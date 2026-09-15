import UIKit
import SwiftUI

enum AppColors {
    static let background = UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.035, green: 0.043, blue: 0.055, alpha: 1) : .systemGroupedBackground }
    static let surface = UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.075, green: 0.09, blue: 0.115, alpha: 1) : .secondarySystemGroupedBackground }
    static let elevatedSurface = UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.12, green: 0.14, blue: 0.17, alpha: 1) : .white }
    static let primaryText = UIColor.label
    static let secondaryText = UIColor.secondaryLabel
    static let accent = UIColor(red: 0.25, green: 0.55, blue: 0.92, alpha: 1)
    static let success = UIColor.systemGreen
    static let warning = UIColor.systemOrange
    static let danger = UIColor.systemRed
    static let separator = UIColor.separator
}
enum AppTypography {
    static let title = UIFont.preferredFont(forTextStyle: .largeTitle).withWeight(.bold)
    static let headline = UIFont.preferredFont(forTextStyle: .headline)
    static let body = UIFont.preferredFont(forTextStyle: .body)
    static let caption = UIFont.preferredFont(forTextStyle: .caption1)
    static let mono = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
}
enum AppSpacing { static let xs: CGFloat = 6; static let sm: CGFloat = 12; static let md: CGFloat = 20; static let lg: CGFloat = 28 }
enum AppRadius { static let card: CGFloat = 18; static let button: CGFloat = 14 }
enum AppIcons {
    static let camera = UIImage(systemName: "camera.fill")
    static let vault = UIImage(systemName: "checkmark.shield.fill")
    static let inspect = UIImage(systemName: "magnifyingglass")
    static let settings = UIImage(systemName: "slider.horizontal.3")
    static let shield = UIImage(systemName: "lock.shield.fill")
    static let play = UIImage(systemName: "play.fill")
    static let folder = UIImage(systemName: "folder.fill")
}
private extension UIFont { func withWeight(_ weight: UIFont.Weight) -> UIFont { UIFont.systemFont(ofSize: pointSize, weight: weight) } }
extension Color { static let trueCutBackground = Color(uiColor: AppColors.background); static let trueCutSurface = Color(uiColor: AppColors.surface) }

enum UIBuilder {
    static func label(_ text: String, style: UIFont = AppTypography.body, color: UIColor = AppColors.primaryText) -> UILabel { let l = UILabel(); l.text = text; l.font = style; l.textColor = color; l.numberOfLines = 0; return l }
    static func button(_ title: String, image: UIImage? = nil, primary: Bool = true) -> UIButton { var c = UIButton.Configuration.filled(); c.title = title; c.image = image; c.imagePadding = AppSpacing.xs; c.cornerStyle = .medium; c.baseBackgroundColor = primary ? AppColors.accent : AppColors.surface; c.baseForegroundColor = primary ? .white : AppColors.primaryText; let b = UIButton(configuration: c); b.accessibilityLabel = title; return b }
    static func card() -> UIView { let v = UIView(); v.backgroundColor = AppColors.surface; v.layer.cornerRadius = AppRadius.card; return v }
}
