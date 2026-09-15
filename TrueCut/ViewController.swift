import UIKit

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let content = AppCoordinator().makeRootViewController()
        addChild(content); content.view.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(content.view); content.didMove(toParent: self)
        NSLayoutConstraint.activate([content.view.topAnchor.constraint(equalTo: view.topAnchor), content.view.bottomAnchor.constraint(equalTo: view.bottomAnchor), content.view.leadingAnchor.constraint(equalTo: view.leadingAnchor), content.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)])
    }
}
