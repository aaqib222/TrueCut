import UIKit
import AVKit
import UniformTypeIdentifiers
import LocalAuthentication
import PhotosUI

private final class ProofCard: UIView {
    let stack = UIStackView()
    init(padding: CGFloat = AppSpacing.md) {
        super.init(frame: .zero); backgroundColor = AppColors.surface; layer.cornerRadius = AppRadius.card
        layer.borderWidth = 1; layer.borderColor = AppColors.separator.withAlphaComponent(0.22).cgColor
        layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor; layer.shadowOpacity = 0.22; layer.shadowRadius = 16; layer.shadowOffset = CGSize(width: 0, height: 8)
        stack.axis = .vertical; stack.spacing = AppSpacing.sm; stack.translatesAutoresizingMaskIntoConstraints = false; addSubview(stack)
        NSLayoutConstraint.activate([stack.topAnchor.constraint(equalTo: topAnchor, constant: padding), stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding), stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding), stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding)])
    }
    required init?(coder: NSCoder) { fatalError("Programmatic card") }
}

private final class ProofBadge: UIView {
    init(title: String, protected: Bool) {
        super.init(frame: .zero); let tint = protected ? AppColors.success : AppColors.warning; backgroundColor = tint.withAlphaComponent(0.14); layer.cornerRadius = 10
        let icon = UIImageView(image: UIImage(systemName: protected ? "checkmark.shield.fill" : "exclamationmark.shield.fill")); icon.tintColor = tint; icon.widthAnchor.constraint(equalToConstant: 15).isActive = true
        let label = UIBuilder.label(title.uppercased(), style: AppTypography.caption.withWeight(.semibold), color: tint)
        let row = UIStackView(arrangedSubviews: [icon, label]); row.axis = .horizontal; row.spacing = 5; row.alignment = .center; row.translatesAutoresizingMaskIntoConstraints = false; addSubview(row)
        NSLayoutConstraint.activate([row.topAnchor.constraint(equalTo: topAnchor, constant: 7), row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -7), row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9), row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9)]); accessibilityLabel = title
    }
    required init?(coder: NSCoder) { fatalError("Programmatic badge") }
}

private func proofLabel(_ text: String, style: UIFont = AppTypography.body, color: UIColor = AppColors.primaryText) -> UILabel { UIBuilder.label(text, style: style, color: color) }
private func proofRow(icon: String, title: String, value: String, tint: UIColor = AppColors.primaryText) -> UIView {
    let image = UIImageView(image: UIImage(systemName: icon)); image.tintColor = tint; image.widthAnchor.constraint(equalToConstant: 21).isActive = true
    let titleLabel = proofLabel(title, style: AppTypography.caption, color: AppColors.secondaryText); let valueLabel = proofLabel(value, style: AppTypography.body); valueLabel.textAlignment = .right
    let row = UIStackView(arrangedSubviews: [image, titleLabel, valueLabel]); row.axis = .horizontal; row.spacing = AppSpacing.xs; row.alignment = .center; return row
}
private func makeScrollStack(on view: UIView) -> UIStackView {
    let scroll = UIScrollView(); scroll.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(scroll); let stack = UIStackView(); stack.axis = .vertical; stack.spacing = AppSpacing.md; stack.translatesAutoresizingMaskIntoConstraints = false; scroll.addSubview(stack)
    NSLayoutConstraint.activate([scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor), scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor), scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor), stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: AppSpacing.md), stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: AppSpacing.md), stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -AppSpacing.md), stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -AppSpacing.lg)]); return stack
}

final class ProofDetailViewController: UIViewController {
    private let record: ProofRecord; private let environment: AppEnvironment
    init(record: ProofRecord, environment: AppEnvironment) { self.record = record; self.environment = environment; super.init(nibName: nil, bundle: nil) }; required init?(coder: NSCoder) { fatalError("Programmatic controller") }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Proof Detail"; view.backgroundColor = AppColors.background; let stack = makeScrollStack(on: view); addMediaStage(to: stack)
        let eyebrow = proofLabel("TRUECUT PROOF", style: AppTypography.caption.withWeight(.bold), color: AppColors.accent); let titleRow = UIStackView(arrangedSubviews: [eyebrow, UIView(), ProofBadge(title: record.protectionStatus.title, protected: record.protectionStatus == .protected)]); titleRow.alignment = .center; stack.addArrangedSubview(titleRow)
        let status = ProofCard(); status.stack.addArrangedSubview(proofLabel(record.protectionStatus == .protected ? "Protected original" : "Protection needs attention", style: AppTypography.headline)); status.stack.addArrangedSubview(proofLabel(record.protectionStatus == .protected ? "This file was sealed locally and passed the available integrity checks." : "The recording is stored locally, but complete protection was not established.", style: AppTypography.caption, color: AppColors.secondaryText)); status.stack.addArrangedSubview(checkRow("File integrity", valid: record.protectionStatus == .protected)); status.stack.addArrangedSubview(checkRow("Content Credentials", valid: record.provenanceStatus == .verifiedOriginal)); status.stack.addArrangedSubview(checkRow("Network timestamp", valid: false, detail: "Not available in Phase 1")); stack.addArrangedSubview(status)
        let share = UIBuilder.button("Share Protected Original", image: UIImage(systemName: "square.and.arrow.up")); share.addTarget(self, action: #selector(shareAsset), for: .touchUpInside); stack.addArrangedSubview(share); let technical = UIBuilder.button("View Technical Proof", image: UIImage(systemName: "doc.text.magnifyingglass"), primary: false); technical.addTarget(self, action: #selector(showTechnical), for: .touchUpInside); stack.addArrangedSubview(technical); addMetadata(to: stack)
    }
    private func addMediaStage(to stack: UIStackView) { let stage = UIView(); stage.backgroundColor = UIColor(red: 0.025, green: 0.035, blue: 0.055, alpha: 1); stage.layer.cornerRadius = AppRadius.card; stage.clipsToBounds = true; stage.heightAnchor.constraint(equalToConstant: 245).isActive = true; let ext = record.localAssetURL.pathExtension.lowercased(); if ["jpg", "jpeg", "png", "heic"].contains(ext), let image = UIImage(contentsOfFile: record.localAssetURL.path) { let imageView = UIImageView(image: image); imageView.contentMode = .scaleAspectFit; imageView.translatesAutoresizingMaskIntoConstraints = false; stage.addSubview(imageView); NSLayoutConstraint.activate([imageView.leadingAnchor.constraint(equalTo: stage.leadingAnchor), imageView.trailingAnchor.constraint(equalTo: stage.trailingAnchor), imageView.topAnchor.constraint(equalTo: stage.topAnchor), imageView.bottomAnchor.constraint(equalTo: stage.bottomAnchor)]); imageView.accessibilityLabel = "Captured photo" } else if FileManager.default.fileExists(atPath: record.localAssetURL.path) { let player = AVPlayerViewController(); player.player = AVPlayer(url: record.localAssetURL); player.view.translatesAutoresizingMaskIntoConstraints = false; addChild(player); stage.addSubview(player.view); NSLayoutConstraint.activate([player.view.leadingAnchor.constraint(equalTo: stage.leadingAnchor), player.view.trailingAnchor.constraint(equalTo: stage.trailingAnchor), player.view.topAnchor.constraint(equalTo: stage.topAnchor), player.view.bottomAnchor.constraint(equalTo: stage.bottomAnchor)]); player.didMove(toParent: self); player.player?.play() } else { let missing = proofLabel("Local original unavailable", style: AppTypography.body, color: AppColors.warning); missing.translatesAutoresizingMaskIntoConstraints = false; stage.addSubview(missing); NSLayoutConstraint.activate([missing.centerXAnchor.constraint(equalTo: stage.centerXAnchor), missing.centerYAnchor.constraint(equalTo: stage.centerYAnchor)]) }; stack.addArrangedSubview(stage) }
    private func checkRow(_ title: String, valid: Bool, detail: String? = nil) -> UIView { let icon = UIImageView(image: UIImage(systemName: valid ? "checkmark.circle.fill" : "minus.circle")); icon.tintColor = valid ? AppColors.success : AppColors.secondaryText; icon.widthAnchor.constraint(equalToConstant: 20).isActive = true; let label = proofLabel(detail.map { "\(title)  ·  \($0)" } ?? title, style: AppTypography.body, color: valid ? AppColors.primaryText : AppColors.secondaryText); let row = UIStackView(arrangedSubviews: [icon, label]); row.axis = .horizontal; row.spacing = AppSpacing.sm; row.alignment = .center; return row }
    private func addMetadata(to stack: UIStackView) { let media = fallbackMetadata(); let duration = record.duration > 0 ? record.duration : media.duration; let width = record.width > 0 ? record.width : media.width; let height = record.height > 0 ? record.height : media.height; let frameRate = record.frameRate > 0 ? record.frameRate : media.frameRate; let capture = ProofCard(); capture.stack.addArrangedSubview(proofLabel("CAPTURE", style: AppTypography.caption.withWeight(.bold), color: AppColors.accent)); capture.stack.addArrangedSubview(proofRow(icon: "calendar", title: "Captured", value: record.createdAt.formatted(date: .abbreviated, time: .shortened))); capture.stack.addArrangedSubview(proofRow(icon: "timer", title: "Duration", value: duration > 0 ? formatDuration(duration) : "Not available")); capture.stack.addArrangedSubview(proofRow(icon: "rectangle.on.rectangle", title: "Resolution", value: width > 0 ? "\(width) × \(height)" : "Not available")); capture.stack.addArrangedSubview(proofRow(icon: "speedometer", title: "Frame rate", value: frameRate > 0 ? String(format: "%.1f FPS", frameRate) : "Not available")); stack.addArrangedSubview(capture); let location = ProofCard(); location.stack.addArrangedSubview(proofLabel("LOCATION DISCLOSURE", style: AppTypography.caption.withWeight(.bold), color: AppColors.accent)); location.stack.addArrangedSubview(proofRow(icon: "location.fill", title: "Privacy mode", value: record.locationDisclosure.title)); stack.addArrangedSubview(location) }
    private func fallbackMetadata() -> (duration: TimeInterval, width: Int, height: Int, frameRate: Double) { let asset = AVAsset(url: record.localAssetURL); let duration = asset.duration.seconds.isFinite ? asset.duration.seconds : 0; guard let track = asset.tracks(withMediaType: .video).first else { return (duration, 0, 0, 0) }; let size = track.naturalSize.applying(track.preferredTransform); return (duration, Int(abs(size.width)), Int(abs(size.height)), Double(track.nominalFrameRate)) }
    private func formatDuration(_ seconds: TimeInterval) -> String { String(format: "%02d:%02d", Int(seconds) / 60, Int(seconds) % 60) }
    @objc private func shareAsset() { guard FileManager.default.fileExists(atPath: record.localAssetURL.path) else { return }; present(UIActivityViewController(activityItems: [record.localAssetURL], applicationActivities: nil), animated: true) }
    @objc private func showTechnical() { navigationController?.pushViewController(TechnicalProofViewController(record: record, environment: environment), animated: true) }
}

final class TechnicalProofViewController: UIViewController {
    private let record: ProofRecord; init(record: ProofRecord, environment: AppEnvironment) { self.record = record; super.init(nibName: nil, bundle: nil) }; required init?(coder: NSCoder) { fatalError("Programmatic controller") }
    override func viewDidLoad() { super.viewDidLoad(); title = "Technical Proof"; view.backgroundColor = AppColors.background; let stack = makeScrollStack(on: view); let card = ProofCard(); card.stack.addArrangedSubview(proofLabel("LOCAL EVIDENCE", style: AppTypography.caption.withWeight(.bold), color: AppColors.accent)); card.stack.addArrangedSubview(proofLabel("CAPTURE ID\n\(record.captureId)\n\nLOCAL DIGEST\n\(record.digestHex ?? "Not available")\n\nPUBLIC KEY FINGERPRINT\n\(record.publicKeyFingerprint ?? "Not available")\n\nC2PA STATUS\n\(record.provenanceStatus == .verifiedOriginal ? "Validated locally" : "Not available")\n\nLOCATION\n\(record.locationDisclosure.title)", style: AppTypography.mono)); stack.addArrangedSubview(card) }
}

final class CompareViewController: UIViewController, UIDocumentPickerDelegate {
    private let original: URL; private let environment: AppEnvironment; private let result = proofLabel("Select another MP4 or MOV to compare locally.", color: AppColors.secondaryText)
    init(original: URL, environment: AppEnvironment) { self.original = original; self.environment = environment; super.init(nibName: nil, bundle: nil) }; required init?(coder: NSCoder) { fatalError("Programmatic controller") }
    override func viewDidLoad() { super.viewDidLoad(); title = "Compare"; view.backgroundColor = AppColors.background; let stack = makeScrollStack(on: view); let card = ProofCard(); card.stack.addArrangedSubview(proofLabel("COMPARE WITH ORIGINAL", style: AppTypography.caption.withWeight(.bold), color: AppColors.accent)); card.stack.addArrangedSubview(result); stack.addArrangedSubview(card); let button = UIBuilder.button("Choose Candidate Video", image: AppIcons.folder); button.addTarget(self, action: #selector(pick), for: .touchUpInside); stack.addArrangedSubview(button) }
    @objc private func pick() { let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.movie, UTType.image]); picker.delegate = self; present(picker, animated: true) }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { guard let candidate = urls.first else { return }; result.text = "Comparing locally…\n\nDigesting both files\nReading media properties\nChecking Content Credentials"; result.font = AppTypography.mono; Task { let comparison = try? await environment.comparisonService.compare(original: original, candidate: candidate); let provenance = try? await environment.credentialsService.verify(assetURL: candidate); await MainActor.run { self.showResult(comparison: comparison, provenance: provenance) } }
    }
    private func showResult(comparison: MediaComparisonResult?, provenance: ProvenanceResult?) {
        guard let comparison else { result.text = "Comparison could not be completed."; result.font = AppTypography.body; return }
        if comparison.identical { result.attributedText = formattedComparisonText("PROTECTED ORIGINAL\n\nThe selected file has the same cryptographic digest as the TrueCut original.", headlineColor: AppColors.success); result.textColor = AppColors.success; result.accessibilityLabel = "Protected original. The selected file matches the TrueCut original."; return }
        var lines = ["NOT THE PROTECTED ORIGINAL", "", "This file is different from the protected TrueCut original. Its original integrity can no longer be confirmed.", "", "EVIDENCE FOUND"]
        lines.append(contentsOf: comparison.differences.dropFirst().map { "• \($0)" })
        lines.append("")
        if let provenance {
            switch provenance.status {
            case .verifiedOriginal, .verifiedDerivative: lines.append("C2PA PROVENANCE\n\(provenance.message)\(provenance.actions.isEmpty ? "" : "\nDeclared actions: \(provenance.actions.joined(separator: ", "))")")
            case .integrityFailure: lines.append("C2PA INTEGRITY FAILURE\nThe Content Credentials are present, but their asset binding did not validate.")
            case .unavailable, .incomplete: lines.append("C2PA PROVENANCE UNAVAILABLE\nNo supported edit history was found. The file may have been edited, re-exported, or had its credentials removed.")
            }
        }
        lines.append("\nTrueCut cannot determine who edited the file or the exact timeline unless the editing application preserved valid provenance.")
        result.attributedText = formattedComparisonText(lines.joined(separator: "\n"), headlineColor: AppColors.danger); result.textColor = AppColors.danger; result.accessibilityLabel = "Not the protected original. The selected file is different from the protected TrueCut original."
    }
    private func formattedComparisonText(_ text: String, headlineColor: UIColor) -> NSAttributedString { let output = NSMutableAttributedString(string: text, attributes: [.font: AppTypography.body, .foregroundColor: headlineColor]); if let range = text.range(of: "\n") { output.addAttributes([.font: AppTypography.headline.withWeight(.bold), .foregroundColor: headlineColor], range: NSRange(text.startIndex..<range.lowerBound, in: text)) }; return output }
}

final class InspectorViewController: UIViewController, UIDocumentPickerDelegate, PHPickerViewControllerDelegate {
    private let environment: AppEnvironment; private let result = proofLabel("Inspect a video\n\nCheck supported provenance and integrity information for a video you've received.", style: AppTypography.title)
    init(environment: AppEnvironment) { self.environment = environment; super.init(nibName: nil, bundle: nil) }; required init?(coder: NSCoder) { fatalError("Programmatic controller") }
    override func viewDidLoad() { super.viewDidLoad(); title = "Inspect"; view.backgroundColor = AppColors.background; let stack = makeScrollStack(on: view); let card = ProofCard(); card.stack.addArrangedSubview(proofLabel("LOCAL INSPECTION", style: AppTypography.caption.withWeight(.bold), color: AppColors.accent)); result.textAlignment = .left; card.stack.addArrangedSubview(result); stack.addArrangedSubview(card); let button = UIBuilder.button("Choose Photo or Video", image: UIImage(systemName: "photo.on.rectangle")); button.addTarget(self, action: #selector(pick), for: .touchUpInside); stack.addArrangedSubview(button) }
    @objc private func pick() {
        let sheet = UIAlertController(title: "Inspect Media", message: "Choose where the photo or video is stored.", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Photo & Video Library", style: .default) { [weak self] _ in self?.pickFromLibrary() })
        sheet.addAction(UIAlertAction(title: "Files", style: .default) { [weak self] _ in self?.pickFromFiles() })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = sheet.popoverPresentationController { popover.sourceView = view; popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 120, width: 1, height: 1) }
        present(sheet, animated: true)
    }
    private func pickFromLibrary() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared()); configuration.filter = .any(of: [.images, .videos]); configuration.selectionLimit = 1; configuration.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: configuration); picker.delegate = self; present(picker, animated: true)
    }
    private func pickFromFiles() { let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.movie, UTType.image]); picker.delegate = self; present(picker, animated: true) }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { guard let url = urls.first else { return }; inspect(url: url) }
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true); guard let result = results.first else { return }; let provider = result.itemProvider
        let type = provider.registeredTypeIdentifiers.compactMap { UTType($0) }.first(where: { $0.conforms(to: .movie) || $0.conforms(to: .image) })
        guard let type else { showInspectionError("This item cannot be read by TrueCut."); return }
        provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { [weak self] temporaryURL, error in
            guard let self, let temporaryURL, error == nil else { DispatchQueue.main.async { self?.showInspectionError("TrueCut could not read this item from the Photo & Video Library.") }; return }
            let ext = temporaryURL.pathExtension.isEmpty ? (type.conforms(to: .movie) ? "mov" : "jpg") : temporaryURL.pathExtension
            let destination = FileManager.default.temporaryDirectory.appendingPathComponent("truecut-inspect-\(UUID().uuidString).\(ext)")
            do { try FileManager.default.copyItem(at: temporaryURL, to: destination); DispatchQueue.main.async { self.inspect(url: destination) } } catch { DispatchQueue.main.async { self.showInspectionError("TrueCut could not prepare this item for local inspection.") } }
        }
    }
    private func inspect(url: URL) { result.text = "ANALYZING\n\nReading file\nChecking Content Credentials\nValidating provenance"; result.font = AppTypography.mono; Task { let provenance = try? await environment.credentialsService.verify(assetURL: url); await MainActor.run { self.result.text = provenance?.message ?? "Unable to inspect this file."; self.result.font = AppTypography.body } } }
    private func showInspectionError(_ message: String) { result.text = message; result.font = AppTypography.body; result.textColor = AppColors.warning }
}

final class SettingsViewController: UIViewController {
    private let environment: AppEnvironment; init(environment: AppEnvironment) { self.environment = environment; super.init(nibName: nil, bundle: nil) }; required init?(coder: NSCoder) { fatalError("Programmatic controller") }
    override func viewDidLoad() { super.viewDidLoad(); title = "Settings"; view.backgroundColor = AppColors.background; let stack = makeScrollStack(on: view); addHero(to: stack); addCameraCard(to: stack); addPrivacyCard(to: stack); addProtectionCard(to: stack); addStorageCard(to: stack); addAboutCard(to: stack) }
    private func addHero(to stack: UIStackView) { let card = ProofCard(); let icon = UIImageView(image: UIImage(systemName: "lock.shield.fill")); icon.tintColor = AppColors.accent; icon.widthAnchor.constraint(equalToConstant: 34).isActive = true; let text = UIStackView(arrangedSubviews: [proofLabel("Your proof workspace", style: AppTypography.headline), proofLabel("Capture settings, privacy controls, and local protection status in one place.", style: AppTypography.caption, color: AppColors.secondaryText)]); text.axis = .vertical; text.spacing = 4; let row = UIStackView(arrangedSubviews: [icon, text]); row.axis = .horizontal; row.spacing = AppSpacing.md; row.alignment = .top; card.stack.addArrangedSubview(row); stack.addArrangedSubview(card) }
    private func section(_ title: String, _ subtitle: String) -> ProofCard { let card = ProofCard(padding: AppSpacing.sm); card.stack.addArrangedSubview(proofLabel(title, style: AppTypography.caption.withWeight(.bold), color: AppColors.accent)); card.stack.addArrangedSubview(proofLabel(subtitle, style: AppTypography.caption, color: AppColors.secondaryText)); return card }
    private func addCameraCard(to stack: UIStackView) { let card = section("CAMERA", "Recording preferences"); card.stack.addArrangedSubview(proofRow(icon: "video.fill", title: "Resolution", value: "High")); card.stack.addArrangedSubview(proofRow(icon: "speedometer", title: "Frame rate", value: "Auto")); card.stack.addArrangedSubview(proofRow(icon: "square.grid.3x3", title: "Composition grid", value: "Off")); card.stack.addArrangedSubview(proofRow(icon: "waveform", title: "Audio recording", value: "On", tint: AppColors.success)); stack.addArrangedSubview(card) }
    private func addPrivacyCard(to stack: UIStackView) { let card = section("PRIVACY", "You choose what accompanies a capture"); card.stack.addArrangedSubview(proofRow(icon: "location.fill", title: "Location disclosure", value: "Off")); let toggle = UISwitch(); toggle.isOn = UserDefaults.standard.bool(forKey: "truecut.faceIDVault"); toggle.onTintColor = AppColors.accent; toggle.addTarget(self, action: #selector(faceIDChanged(_:)), for: .valueChanged); let text = UIStackView(arrangedSubviews: [proofLabel("Require Face ID", style: AppTypography.body), proofLabel("Protect access to Proof Vault", style: AppTypography.caption, color: AppColors.secondaryText)]); text.axis = .vertical; text.spacing = 3; let image = UIImageView(image: UIImage(systemName: "faceid")); image.tintColor = AppColors.accent; image.widthAnchor.constraint(equalToConstant: 22).isActive = true; let row = UIStackView(arrangedSubviews: [image, text, toggle]); row.axis = .horizontal; row.spacing = AppSpacing.sm; row.alignment = .center; card.stack.addArrangedSubview(row); stack.addArrangedSubview(card) }
    private func addProtectionCard(to stack: UIStackView) { let card = section("PROTECTION", "Local status, never a cloud upload"); card.stack.addArrangedSubview(proofRow(icon: "shield.lefthalf.filled", title: "Hardware evidence", value: "Device-reported")); card.stack.addArrangedSubview(proofRow(icon: "seal.fill", title: "Content Credentials", value: "Local C2PA")); card.stack.addArrangedSubview(proofRow(icon: "icloud.slash", title: "Original media", value: "On this device")); stack.addArrangedSubview(card) }
    private func addStorageCard(to stack: UIStackView) { let card = section("STORAGE", "Your originals remain under your control"); card.stack.addArrangedSubview(proofRow(icon: "internaldrive.fill", title: "Protected videos", value: "Local vault")); card.stack.addArrangedSubview(proofLabel("TrueCut does not upload your original videos or photos in this version.", style: AppTypography.caption, color: AppColors.secondaryText)); stack.addArrangedSubview(card) }
    private func addAboutCard(to stack: UIStackView) { let card = section("ABOUT", "TrueCut · Phase 1"); card.stack.addArrangedSubview(proofRow(icon: "info.circle", title: "How TrueCut Works", value: "View")); card.stack.addArrangedSubview(proofRow(icon: "lock.fill", title: "Privacy", value: "View")); card.stack.addArrangedSubview(proofRow(icon: "doc.text", title: "App Version", value: "1.0")); stack.addArrangedSubview(card) }
    @objc private func faceIDChanged(_ sender: UISwitch) { UserDefaults.standard.set(sender.isOn, forKey: "truecut.faceIDVault") }
}

private extension UIFont { func withWeight(_ weight: UIFont.Weight) -> UIFont { UIFont.systemFont(ofSize: pointSize, weight: weight) } }
