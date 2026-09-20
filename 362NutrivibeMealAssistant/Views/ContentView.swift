import SwiftUI

struct ContentView: View {
    @StateObject private var store = DataStore()
    @State private var tab: KitchenTab = .blends
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            KitchenBackdrop()
            Group {
                if store.hasSeenOnboarding {
                    HStack(spacing: 0) {
                        tabBody
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .kitchenScreen()
                        chapterTabs
                    }
                } else {
                    OnboardingView()
                }
            }
        }
        .environmentObject(store)
        .preferredColorScheme(.light)
        .sheet(isPresented: journalPresented) {
            if let pending = store.pendingTastings.first {
                TastingNoteSheet(pending: pending)
                    .environmentObject(store)
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                store.tickTimers()
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if scenePhase == .active {
                store.tickTimers()
            }
        }
    }

    private var journalPresented: Binding<Bool> {
        Binding(
            get: { !store.pendingTastings.isEmpty },
            set: { presented in
                if !presented, !store.pendingTastings.isEmpty {
                    store.dismissPendingTasting()
                }
            }
        )
    }

    @ViewBuilder
    private var tabBody: some View {
        switch tab {
        case .blends: BlendLibraryView()
        case .recipes: RecipeListView()
        case .market: MarketView()
        case .timers: TimerBoardView()
        case .stats: KitchenStatsView()
        case .settings: SettingsView()
        }
    }

    private var chapterTabs: some View {
        VStack(spacing: 0) {
            ForEach(KitchenTab.allCases, id: \.self) { item in
                Button {
                    tab = item
                } label: {
                    Text(item.title)
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .rotationEffect(.degrees(90))
                        .fixedSize()
                        .frame(width: 36, height: 66)
                        .foregroundColor(tab == item ? .white : Color("AppPrimary"))
                        .background(tab == item ? Color("AppPrimary") : Color.white.opacity(0.7))
                        .overlay(Rectangle().stroke(Color("AppPrimary").opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.top, 18)
        .background(Color("AppAccent").opacity(0.18))
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var store: DataStore
    @State private var page = 0
    private let pages: [(image: String, tilt: Double, title: String, body: String)] = [
        ("banner_herbs", -3, "Discover spices", "A shelf of seeds, barks, and herbs. Browse the catalog, then cook from what you have."),
        ("tile_mortar", 4, "Create blends", "Two spices make a jar. Saving a blend fills the market list with the jars you still need."),
        ("tile_pan", -2, "Shop and time", "Check off the market list, then name a timer after the dish so the kitchen stays in rhythm."),
        ("banner_herbs", 3, "Keep a ledger", "Saved plates and cook logs become charts. Open the kitchen when you are ready.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") { store.completeOnboarding() }
                    .font(.system(.footnote, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.55))
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            VStack(spacing: 18) {
                Polaroid(image: pages[page].image, tilt: pages[page].tilt)
                    .padding(.horizontal, 36)
                    .padding(.top, 12)
                    .id(page)
                Text(pages[page].title)
                    .font(.system(size: 32, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                    .multilineTextAlignment(.center)
                Text(pages[page].body)
                    .font(.system(.body, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                Spacer()
            }
            .animation(.easeInOut(duration: 0.25), value: page)
            .gesture(
                DragGesture(minimumDistance: 36).onEnded { value in
                    if value.translation.width < -36, page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else if value.translation.width > 36, page > 0 {
                        withAnimation { page -= 1 }
                    }
                }
            )

            HStack(spacing: 7) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(Color("AppPrimary").opacity(index == page ? 1 : 0.22))
                        .frame(width: index == page ? 22 : 8, height: 8)
                }
            }
            .padding(.bottom, 10)

            HStack {
                if page > 0 {
                    Button("Back") {
                        withAnimation { page -= 1 }
                    }
                    .font(.system(.body, design: .serif))
                    .foregroundColor(Color("AppPrimary"))
                }
                Spacer()
                if page == pages.count - 1 {
                    Button("Open the kitchen") { store.completeOnboarding() }
                        .font(.system(.body, design: .serif).weight(.bold))
                        .foregroundColor(Color("AppPrimary"))
                } else {
                    Button("Next") {
                        withAnimation { page += 1 }
                    }
                    .font(.system(.body, design: .serif).weight(.bold))
                    .foregroundColor(Color("AppPrimary"))
                }
            }
            .padding(24)
        }
        .kitchenScreen()
    }
}
