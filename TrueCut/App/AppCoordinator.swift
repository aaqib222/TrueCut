import UIKit

final class AppCoordinator {
    let environment: AppEnvironment
    init(environment: AppEnvironment = .live) { self.environment = environment }
    func makeRootViewController() -> UIViewController {
        let tabs = UITabBarController()
        let camera = UINavigationController(rootViewController: CameraViewController(environment: environment)); camera.tabBarItem = UITabBarItem(title: "Capture", image: AppIcons.camera, tag: 0)
        let vault = UINavigationController(rootViewController: ProofVaultViewController(environment: environment)); vault.tabBarItem = UITabBarItem(title: "Proof Vault", image: AppIcons.vault, tag: 1)
        let inspect = UINavigationController(rootViewController: InspectorViewController(environment: environment)); inspect.tabBarItem = UITabBarItem(title: "Inspect", image: AppIcons.inspect, tag: 2)
        let settings = UINavigationController(rootViewController: SettingsViewController(environment: environment)); settings.tabBarItem = UITabBarItem(title: "Settings", image: AppIcons.settings, tag: 3)
        tabs.viewControllers = [camera, vault, inspect, settings]
        return tabs
    }
}
