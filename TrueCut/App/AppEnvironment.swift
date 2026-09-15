import Foundation

struct AppEnvironment {
    let proofRepository: ProofRepository
    let digestService: FileDigestService
    let signingService: EvidenceSigningService
    let credentialsService: ContentCredentialsService
    let comparisonService: MediaComparisonService

    static let live: AppEnvironment = {
        let storage = LocalProofRepository()
        #if canImport(C2PA)
        let credentials: ContentCredentialsService = C2PAContentCredentialsService()
        #else
        let credentials: ContentCredentialsService = UnsupportedContentCredentialsService()
        #endif
        return AppEnvironment(proofRepository: storage, digestService: StreamingFileDigestService(), signingService: KeychainEvidenceSigningService(), credentialsService: credentials, comparisonService: LocalMediaComparisonService(digestService: StreamingFileDigestService()))
    }()
}
