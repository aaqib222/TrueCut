import UIKit
import SwiftUI

enum AppColors {
    static let background = UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.035, green: 0.047, blue: 0.082, alpha: 1) : UIColor(red: 0.955, green: 0.965, blue: 0.985, alpha: 1) }
    static let surface = UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.075, green: 0.098, blue: 0.16, alpha: 1) : .white }
    static let elevatedSurface = UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.12, green: 0.15, blue: 0.20, alpha: 1) : UIColor(red: 0.985, green: 0.99, blue: 1, alpha: 1) }
    static let primaryText = UIColor.label
    static let secondaryText = UIColor.secondaryLabel
    static let accent = UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.40, green: 0.57, blue: 1.0, alpha: 1) : UIColor(red: 0.19, green: 0.36, blue: 0.86, alpha: 1) }
    static let success = UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.24, green: 0.83, blue: 0.58, alpha: 1) : UIColor(red: 0.08, green: 0.60, blue: 0.38, alpha: 1) }
    static let warning = UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 1.0, green: 0.66, blue: 0.28, alpha: 1) : UIColor(red: 0.83, green: 0.45, blue: 0.08, alpha: 1) }
    static let danger = UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 1.0, green: 0.35, blue: 0.42, alpha: 1) : UIColor(red: 0.78, green: 0.12, blue: 0.20, alpha: 1) }
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
