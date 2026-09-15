import Foundation

enum ProtectionStatus: String, Codable { case processing, protected, incomplete, failed
    var title: String { switch self { case .protected: "Protected Original"; case .incomplete: "Protection Incomplete"; case .failed: "Protection Failed"; case .processing: "Protecting" } }
}
enum ProvenanceStatus: String, Codable { case verifiedOriginal, verifiedDerivative, incomplete, unavailable, integrityFailure }
enum LocationDisclosure: String, Codable, CaseIterable { case off, approximate, exact; var title: String { rawValue.capitalized } }
enum HardwareProtectionStatus: String, Codable { case available, unavailable, developmentFallback }
struct CaptureEvidence: Codable { let captureID: String; let digest: Data; let createdAt: Date; let locationDisclosure: LocationDisclosure }
struct SealedAsset { let url: URL; let credentialsCreated: Bool; let manifestStatus: String }
struct ProvenanceResult {
    let status: ProvenanceStatus
    let message: String
    let credentialsFound: Bool
    let assetBindingValid: Bool
    let claimGenerator: String?
    let manifestIdentifier: String?
    let actions: [String]
    let digitalSourceType: String?
    let validationErrors: [String]
}
struct ProofRecord: Identifiable, Codable {
    let id: UUID; let captureId: String; let localAssetURL: URL; let createdAt: Date; let duration: TimeInterval
    let width: Int; let height: Int; let frameRate: Double; let locationDisclosure: LocationDisclosure
    let protectionStatus: ProtectionStatus; let provenanceStatus: ProvenanceStatus; let publicKeyFingerprint: String?
    let digestHex: String?; let fileSize: Int64
}
struct MediaComparisonResult { let identical: Bool; let originalDigest: String; let candidateDigest: String; let differences: [String] }

protocol FileDigestService { func sha256(of url: URL) async throws -> Data }
protocol EvidenceSigningService { func prepareKey() async throws; func publicKeyFingerprint() async throws -> String; func signDigest(_ digest: Data) async throws -> Data; func hardwareProtectionStatus() async -> HardwareProtectionStatus }
protocol ContentCredentialsService { func seal(assetURL: URL, evidence: CaptureEvidence) async throws -> SealedAsset; func verify(assetURL: URL) async throws -> ProvenanceResult }
protocol MediaComparisonService { func compare(original: URL, candidate: URL) async throws -> MediaComparisonResult }
protocol ProofRepository { func load() async throws -> [ProofRecord]; func save(_ record: ProofRecord) async throws; func delete(_ record: ProofRecord) async throws }

enum TrueCutError: LocalizedError { case fileNotFound, storage(String), signing(String), unsupportedCredentials, comparison(String)
    var errorDescription: String? { switch self { case .fileNotFound: "The local original is unavailable."; case .storage(let m): m; case .signing(let m): m; case .unsupportedCredentials: "Content Credentials are not available in this build."; case .comparison(let m): m } }
}

enum ContentCredentialsError: Error { case sdkUnavailable, unsupportedAsset, manifestCreationFailed, signingFailed, embeddingFailed, manifestNotFound, validationFailed, assetBindingInvalid }
