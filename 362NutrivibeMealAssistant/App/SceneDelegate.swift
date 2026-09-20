import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        KitchenAppearance.apply()
        let host = UIHostingController(rootView: ContentView())
        host.view.backgroundColor = .clear
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = UIColor(named: "AppBackground")
        window.rootViewController = host
        window.makeKeyAndVisible()
        KeyboardDismissTap.shared.install(on: window)
        self.window = window
    }
}
