import Foundation
import CryptoKit
import Security
import AVFoundation
import OSLog
#if canImport(C2PA)
import C2PA
#endif

private let trueCutLog = Logger(subsystem: "com.sherazi.truecut", category: "security")

final class StreamingFileDigestService: FileDigestService {
    func sha256(of url: URL) async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            guard FileManager.default.fileExists(atPath: url.path) else { throw TrueCutError.fileNotFound }
            let handle = try FileHandle(forReadingFrom: url); defer { try? handle.close() }
            var hasher = SHA256(); let chunkSize = 1024 * 1024
            while autoreleasepool(invoking: {
                let data = try? handle.read(upToCount: chunkSize)
                guard let data, !data.isEmpty else { return false }
                hasher.update(data: data); return true
            }) {}
            return Data(hasher.finalize())
        }.value
    }
}

final class KeychainEvidenceSigningService: EvidenceSigningService {
    private let tag = "com.sherazi.truecut.evidence-key".data(using: .utf8)!
    func prepareKey() async throws { _ = try key() }
    func publicKeyFingerprint() async throws -> String { try key().publicKey.rawRepresentation.sha256Hex.prefix(24).description }
    func signDigest(_ digest: Data) async throws -> Data { try key().signature(for: digest).rawRepresentation }
    func hardwareProtectionStatus() async -> HardwareProtectionStatus {
        #if targetEnvironment(simulator)
        return .developmentFallback
        #else
        do { _ = try key(); return .available } catch { return .unavailable }
        #endif
    }
    private func key() throws -> P256.Signing.PrivateKey {
        let query: [String: Any] = [kSecClass as String: kSecClassKey, kSecAttrApplicationTag as String: tag, kSecReturnRef as String: true]
        var item: CFTypeRef?; let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let ref = item { return try P256.Signing.PrivateKey(secKey: ref as! SecKey) }
        var attributes: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom, kSecAttrKeySizeInBits as String: 256, kSecPrivateKeyAttrs as String: [kSecAttrIsPermanent as String: true, kSecAttrApplicationTag as String: tag]]
        #if !targetEnvironment(simulator)
        attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        #endif
        var error: Unmanaged<CFError>?; guard let secKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else { throw TrueCutError.signing((error?.takeRetainedValue() as Error?)?.localizedDescription ?? "Unable to prepare signing key.") }
        return try P256.Signing.PrivateKey(secKey: secKey)
    }
}

final class UnsupportedContentCredentialsService: ContentCredentialsService {
    func seal(assetURL: URL, evidence: CaptureEvidence) async throws -> SealedAsset { throw TrueCutError.unsupportedCredentials }
    func verify(assetURL: URL) async throws -> ProvenanceResult { ProvenanceResult(status: .unavailable, message: "This file does not contain sufficient supported provenance information to establish its capture history.", credentialsFound: false, assetBindingValid: false, claimGenerator: nil, manifestIdentifier: nil, actions: [], digitalSourceType: nil, validationErrors: []) }
}

#if canImport(C2PA)
/// Production adapter for the official c2pa-swift package. C2PA owns the BMFF
/// asset binding and validation; TrueCut never hashes a pre-embedded file and
/// assumes that hash is still valid after embedding.
final class C2PAContentCredentialsService: ContentCredentialsService {
    private let signingKeyTag = "com.sherazi.truecut.c2pa-development-key"

    func seal(assetURL: URL, evidence: CaptureEvidence) async throws -> SealedAsset {
        try await Task.detached(priority: .userInitiated) { [self] in
            guard FileManager.default.fileExists(atPath: assetURL.path) else { throw ContentCredentialsError.unsupportedAsset }
            let output = FileManager.default.temporaryDirectory.appendingPathComponent("sealed-\(evidence.captureID).mov")
            try? FileManager.default.removeItem(at: output)
            let manifest = try makeManifest(assetURL: assetURL, evidence: evidence)
            let signer = try makeDevelopmentSigner()
            do {
                try C2PA.signFile(source: assetURL, destination: output, manifestJSON: manifest, signer: signer)
            } catch { trueCutLog.error("C2PA embedding failed: \(String(describing: error), privacy: .public)"); throw ContentCredentialsError.embeddingFailed }
            let validation = try verifySynchronously(assetURL: output)
            guard validation.status == .verifiedOriginal, validation.assetBindingValid else { throw ContentCredentialsError.validationFailed }
            return SealedAsset(url: output, credentialsCreated: true, manifestStatus: "validated")
        }.value
    }

    func verify(assetURL: URL) async throws -> ProvenanceResult {
        try await Task.detached(priority: .userInitiated) {
            do {
                let json = try C2PA.readFile(at: assetURL)
                guard let data = json.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw ContentCredentialsError.validationFailed }
                let errors = Self.validationErrors(from: object)
                let active = object["active_manifest"] as? String
                let manifests = object["manifests"] as? [String: Any]
                let manifest = (active.flatMap { manifests?[$0] as? [String: Any] }) ?? manifests?.values.compactMap { $0 as? [String: Any] }.first
                let claimGenerator = manifest?["claim_generator"] as? String ?? manifest?["claim_generator_info"] as? String
                let actions = ((manifest?["assertions"] as? [[String: Any]]) ?? []).compactMap { assertion -> String? in
                    let data = assertion["data"] as? [String: Any]; let actions = data?["actions"] as? [[String: Any]]; return actions?.compactMap { $0["action"] as? String }.joined(separator: ", ")
                }
                let source = ((manifest?["assertions"] as? [[String: Any]]) ?? []).compactMap { ($0["data"] as? [String: Any])?["actions"] as? [[String: Any]] }.flatMap { $0 }.compactMap { $0["digital_source_type"] as? String }.first
                if !errors.isEmpty { return ProvenanceResult(status: .integrityFailure, message: "The Content Credentials contain validation errors. The protected asset may have changed.", credentialsFound: true, assetBindingValid: false, claimGenerator: claimGenerator, manifestIdentifier: active, actions: actions, digitalSourceType: source, validationErrors: errors) }
                return ProvenanceResult(status: .verifiedOriginal, message: "CONTENT CREDENTIALS VALID\n\nThe file contains supported Content Credentials and its asset binding validated locally.", credentialsFound: true, assetBindingValid: true, claimGenerator: claimGenerator, manifestIdentifier: active, actions: actions, digitalSourceType: source, validationErrors: [])
            } catch ContentCredentialsError.validationFailed { throw ContentCredentialsError.validationFailed
            } catch { return ProvenanceResult(status: .unavailable, message: "This file does not contain sufficient supported provenance information to establish its capture history.", credentialsFound: false, assetBindingValid: false, claimGenerator: nil, manifestIdentifier: nil, actions: [], digitalSourceType: nil, validationErrors: []) }
        }.value
    }

    private func makeManifest(assetURL: URL, evidence: CaptureEvidence) throws -> String {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let generator = ClaimGeneratorInfo(name: "TrueCut iOS", operatingSystem: "iOS", version: appVersion)
        let action = Action(action: .created, digitalSourceType: .digitalCapture, softwareAgent: "TrueCut iOS")
        let trueCutData: [String: Any] = ["capture_id": evidence.captureID, "capture_evidence_digest": evidence.digest.sha256Hex, "location_disclosure": evidence.locationDisclosure.rawValue, "capture_time": ISO8601DateFormatter().string(from: evidence.createdAt)]
        let definition = ManifestDefinition(assertions: [.actions(actions: [action]), .custom(label: "com.sherazi.truecut.capture", data: AnyCodable(trueCutData))], claimGeneratorInfo: [generator], format: "video/quicktime", title: assetURL.lastPathComponent, instanceId: "urn:uuid:\(evidence.captureID)")
        return try definition.toJSON()
    }

    private func makeDevelopmentSigner() throws -> SignerInfo {
        // Development-only C2PA signing: a runtime-created P-256 key and a
        // self-signed certificate. Production claim-signing infrastructure must
        // be replaced before release; no production private key is shipped.
        let attributes: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom, kSecAttrKeySizeInBits as String: 256]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error), let publicKey = SecKeyCopyPublicKey(key), let privateDER = SecKeyCopyExternalRepresentation(key, &error) as Data? else { throw ContentCredentialsError.signingFailed }
        let config = CertificateManager.CertificateConfig(commonName: "TrueCut Development Signer", organization: "TrueCut Development", organizationalUnit: "Development Only", country: "US", state: "CA", locality: "Cupertino", validityDays: 30)
        let certs = try CertificateManager.createSelfSignedCertificateChain(for: publicKey, config: config)
        let privatePEM = "-----BEGIN EC PRIVATE KEY-----\n\(privateDER.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed]))-----END EC PRIVATE KEY-----"
        let signer = SignerInfo(algorithm: .es256, certificatePEM: certs, privateKeyPEM: privatePEM)
        return signer
    }
    private func verifySynchronously(assetURL: URL) throws -> ProvenanceResult {
        do {
            let json = try C2PA.readFile(at: assetURL)
            guard let data = json.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw ContentCredentialsError.validationFailed }
            let errors = Self.validationErrors(from: object)
            if !errors.isEmpty { return ProvenanceResult(status: .integrityFailure, message: "The Content Credentials contain validation errors. The protected asset may have changed.", credentialsFound: true, assetBindingValid: false, claimGenerator: nil, manifestIdentifier: nil, actions: [], digitalSourceType: nil, validationErrors: errors) }
            return ProvenanceResult(status: .verifiedOriginal, message: "CONTENT CREDENTIALS VALID", credentialsFound: true, assetBindingValid: true, claimGenerator: nil, manifestIdentifier: nil, actions: [], digitalSourceType: nil, validationErrors: [])
        } catch { throw ContentCredentialsError.validationFailed }
    }
    private static func validationErrors(from object: [String: Any]) -> [String] {
        var result = [String]()
        func walk(_ value: Any) {
            if let dictionary = value as? [String: Any] {
                if let explanation = dictionary["explanation"] as? String { result.append(explanation) }
                for (key, child) in dictionary where key == "validation_status" || key == "validation_results" || key == "failure" { walk(child) }
            } else if let array = value as? [Any] { array.forEach(walk) }
        }
        walk(object)
        return Array(Set(result))
    }
}
#endif

final class LocalMediaComparisonService: MediaComparisonService {
    let digestService: FileDigestService
    init(digestService: FileDigestService) { self.digestService = digestService }
    func compare(original: URL, candidate: URL) async throws -> MediaComparisonResult {
        let a = try await digestService.sha256(of: original).sha256Hex; let b = try await digestService.sha256(of: candidate).sha256Hex
        return MediaComparisonResult(identical: a == b, originalDigest: a, candidateDigest: b, differences: a == b ? [] : ["File digest"])
    }
}

final class LocalProofRepository: ProofRepository {
    private let directory: URL; private let file: URL
    init() { directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("TrueCut", isDirectory: true); file = directory.appendingPathComponent("proof-records.json") }
    func load() async throws -> [ProofRecord] { guard FileManager.default.fileExists(atPath: file.path) else { return [] }; return try JSONDecoder().decode([ProofRecord].self, from: Data(contentsOf: file)) }
    func save(_ record: ProofRecord) async throws { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true); var all = try await load(); all.removeAll { $0.id == record.id }; all.insert(record, at: 0); let data = try JSONEncoder().encode(all); try data.write(to: file, options: .atomic); try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen], ofItemAtPath: file.path) }
    func delete(_ record: ProofRecord) async throws { var all = try await load(); all.removeAll { $0.id == record.id }; let data = try JSONEncoder().encode(all); try data.write(to: file, options: .atomic) }
}

extension Data { var sha256Hex: String { map { String(format: "%02x", $0) }.joined() } }
