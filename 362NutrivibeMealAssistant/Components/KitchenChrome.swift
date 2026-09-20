import Combine
import StoreKit
import SwiftUI
import UIKit

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var confirmReset = false
    func openPrivacy() {
        if let url = URL(string: AppLinks.privacy) { UIApplication.shared.open(url) }
    }
    func openTerms() {
        if let url = URL(string: AppLinks.terms) { UIApplication.shared.open(url) }
    }
    func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

enum KitchenTab: String, CaseIterable {
    case blends
    case recipes
    case market
    case timers
    case stats
    case settings

    var title: String {
        switch self {
        case .blends: return "Jars"
        case .recipes: return "Plates"
        case .market: return "List"
        case .timers: return "Time"
        case .stats: return "Stats"
        case .settings: return "Desk"
        }
    }
}

struct Polaroid: View {
    let image: String
    var tilt: Double = -3

    var body: some View {
        VStack(spacing: 8) {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(height: 118)
                .clipped()
            Rectangle()
                .fill(Color("AppPrimary").opacity(0.28))
                .frame(width: 52, height: 5)
        }
        .padding(10)
        .background(Color.white)
        .shadow(color: .black.opacity(0.18), radius: 8, x: 2, y: 6)
        .rotationEffect(.degrees(tilt))
    }
}

struct RecipeCard: View {
    let title: String
    let detail: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.title3, design: .serif))
                .foregroundColor(Color("AppPrimary"))
            Text(detail)
                .font(.system(.footnote, design: .serif))
                .foregroundColor(Color("AppPrimary").opacity(0.7))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .overlay(alignment: .leading) {
            Rectangle().fill(Color("AppPrimary")).frame(width: 5)
        }
                .shadow(color: Color.black.opacity(0.12), radius: 3, x: 1, y: 2)
    }
}

struct KitchenField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding(10)
            .background(Color.white)
            .overlay(Rectangle().stroke(Color("AppPrimary").opacity(0.2), lineWidth: 1))
    }
}

struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.caption, design: .serif).weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundColor(selected ? .white : Color("AppPrimary"))
                .background(selected ? Color("AppPrimary") : Color.white.opacity(0.9))
                .overlay(Rectangle().stroke(Color("AppPrimary").opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct FlavorRadar: View {
    let spiceIds: [String]

    var body: some View {
        let profile = SpiceCatalog.profile(for: spiceIds)
        VStack(spacing: 8) {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2 + 6)
                let radius = min(size.width, size.height) / 2 - 22
                let axes: [(String, Double)] = [
                    ("Heat", profile.heat),
                    ("Smoke", profile.smoke),
                    ("Citrus", profile.citrus),
                    ("Floral", profile.floral)
                ]
                for ring in [0.33, 0.66, 1.0] {
                    var grid = Path()
                    for index in 0..<4 {
                        let point = Self.point(center: center, radius: radius * ring, index: index)
                        if index == 0 { grid.move(to: point) } else { grid.addLine(to: point) }
                    }
                    grid.closeSubpath()
                    context.stroke(grid, with: .color(Color("AppPrimary").opacity(0.18)), lineWidth: 1)
                }
                var fill = Path()
                for index in 0..<4 {
                    let point = Self.point(center: center, radius: radius * max(0.04, axes[index].1), index: index)
                    if index == 0 { fill.move(to: point) } else { fill.addLine(to: point) }
                }
                fill.closeSubpath()
                context.fill(fill, with: .color(Color("AppPrimary").opacity(0.28)))
                context.stroke(fill, with: .color(Color("AppPrimary")), lineWidth: 1.5)
                for index in 0..<4 {
                    let labelPoint = Self.point(center: center, radius: radius + 14, index: index)
                    let resolved = context.resolve(Text(axes[index].0).font(.system(size: 10, design: .serif)).foregroundColor(Color("AppPrimary")))
                    context.draw(resolved, at: labelPoint)
                }
            }
            .frame(height: 168)
        }
    }

    private static func point(center: CGPoint, radius: CGFloat, index: Int) -> CGPoint {
        let angle = Angle.degrees(-90 + Double(index) * 90).radians
        return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }
}

struct StampButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.body, design: .serif).weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color("AppPrimary"))
                .foregroundColor(.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 2)
                        .padding(3)
                )
                .shadow(color: Color("AppPrimary").opacity(0.28), radius: 0, x: 3, y: 3)
        }
        .buttonStyle(.plain)
    }
}
