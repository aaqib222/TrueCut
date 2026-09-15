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
        AppLogger.step("Environment: C2PAContentCredentialsService selected")
        let credentials: ContentCredentialsService = C2PAContentCredentialsService()
        #else
        AppLogger.failure("Environment: UnsupportedContentCredentialsService selected because C2PA is unavailable")
        let credentials: ContentCredentialsService = UnsupportedContentCredentialsService()
        #endif
        return AppEnvironment(proofRepository: storage, digestService: StreamingFileDigestService(), signingService: KeychainEvidenceSigningService(), credentialsService: credentials, comparisonService: LocalMediaComparisonService(digestService: StreamingFileDigestService()))
    }()
}
