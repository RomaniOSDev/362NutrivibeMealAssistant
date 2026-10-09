import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var launchFlowResolver: LaunchFlowResolver?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        KitchenAppearance.apply()
        window = UIWindow(windowScene: windowScene)
        window?.backgroundColor = UIColor(named: "AppBackground")
        launchFlowResolver = LaunchFlowResolver(window: window)
        window?.rootViewController = launchFlowResolver?.resolveEntryViewController()
        window?.makeKeyAndVisible()
        if let window {
            KeyboardDismissTap.shared.install(on: window)
        }
    }
}
