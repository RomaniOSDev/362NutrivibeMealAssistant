import Foundation
import SwiftUI
import UIKit

enum AppLinks {
    static let privacy = "https://nutrivibemealassistant362.site/privacy/474"
    static let terms = "https://nutrivibemealassistant362.site/terms/474"
}

enum KitchenAppearance {
    static func apply() {
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundColor = .clear
        nav.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().isTranslucent = true
    }
}

struct KitchenBackdrop: View {
    var image: String = "bg_spices"

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color("AppBackground")
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(0.52)
                Color("AppBackground").opacity(0.16)
                PaperRules()
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct TransparentBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        DispatchQueue.main.async {
            var parent = view.superview
            var hops = 0
            while let current = parent, hops < 8 {
                if current is UIWindow { break }
                current.backgroundColor = .clear
                parent = current.superview
                hops += 1
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension View {
    func canvasBackground(_ image: String = "bg_spices") -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(TransparentBackground())
            .background { KitchenBackdrop(image: image) }
    }

    func kitchenScreen() -> some View {
        scrollDismissesKeyboard(.immediately)
            .toolbarBackground(.hidden, for: .navigationBar)
            .background(TransparentBackground())
    }
}

enum Keyboard {
    static func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}

final class KeyboardDismissTap: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismissTap()

    func install(on window: UIWindow) {
        guard window.gestureRecognizers?.contains(where: { $0.name == "kitchen.dismissKeyboard" }) != true else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.name = "kitchen.dismissKeyboard"
        tap.cancelsTouchesInView = false
        tap.delegate = self
        window.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        Keyboard.dismiss()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UITextField || current is UITextView { return false }
            view = current.superview
        }
        return true
    }
}

struct PaperRules: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            var y: CGFloat = 18
            while y < size.height {
                path.move(to: CGPoint(x: 28, y: y))
                path.addLine(to: CGPoint(x: size.width - 12, y: y))
                y += 28
            }
            context.stroke(path, with: .color(Color("AppPrimary").opacity(0.08)), lineWidth: 1)
            var margin = Path()
            margin.move(to: CGPoint(x: 22, y: 0))
            margin.addLine(to: CGPoint(x: 22, y: size.height))
            context.stroke(margin, with: .color(Color.red.opacity(0.18)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}
