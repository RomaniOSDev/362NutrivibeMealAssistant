import Charts
import SwiftUI

struct KitchenStatsView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Polaroid(image: "tile_mortar", tilt: -2)
                    .padding(.horizontal, 28)
                Text("Kitchen ledger")
                    .font(.system(size: 32, design: .serif))
                    .foregroundColor(Color("AppPrimary"))

                HStack(spacing: 10) {
                    statChip("Jars", "\(store.blends.count)")
                    statChip("Plates", "\(store.favorites.count)")
                    statChip("Cooks", "\(store.cookDates.count)")
                }

                if !store.tastingNotes.isEmpty {
                    chartCard(title: "Plate journal", detail: "Notes written after a timer ran down.") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(store.tastingNotes.prefix(8))) { note in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(note.dishName)
                                        .font(.system(.subheadline, design: .serif).weight(.bold))
                                        .foregroundColor(Color("AppPrimary"))
                                    Text(note.text)
                                        .font(.system(.footnote, design: .serif))
                                        .foregroundColor(Color("AppPrimary").opacity(0.75))
                                }
                            }
                        }
                    }
                }

                chartCard(title: "Spice use in your jars", detail: spiceUsage.isEmpty ? "Mix a blend to see which spices you reach for." : "How often each spice lands in a jar.") {
                    if spiceUsage.isEmpty {
                        emptyChart()
                    } else {
                        Chart(spiceUsage) { item in
                            BarMark(
                                x: .value("Uses", item.count),
                                y: .value("Spice", item.name)
                            )
                            .foregroundStyle(Color("AppPrimary"))
                        }
                        .chartXAxis {
                            AxisMarks(position: .bottom) { _ in
                                AxisGridLine().foregroundStyle(Color("AppPrimary").opacity(0.12))
                                AxisValueLabel().foregroundStyle(Color("AppPrimary").opacity(0.7))
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisValueLabel().foregroundStyle(Color("AppPrimary"))
                            }
                        }
                        .frame(height: CGFloat(max(140, spiceUsage.count * 28)))
                    }
                }

                chartCard(title: "Seven-day kitchen", detail: weekPoints.allSatisfy { $0.total == 0 } ? "Open a plate or finish a timer to start the week." : "Blends saved, plates opened, and cooks finished.") {
                    Chart(weekSeries) { row in
                        BarMark(
                            x: .value("Day", row.day, unit: .day),
                            y: .value("Count", row.count)
                        )
                        .foregroundStyle(by: .value("Kind", row.kind))
                    }
                    .chartForegroundStyleScale([
                        "Jars": Color("AppAccent"),
                        "Plates": Color("AppPrimary").opacity(0.55),
                        "Cooks": Color("AppPrimary")
                    ])
                    .chartLegend(.hidden)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine().foregroundStyle(Color("AppPrimary").opacity(0.12))
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(date, format: .dateTime.weekday(.narrow))
                                        .font(.system(.caption2, design: .serif))
                                        .foregroundColor(Color("AppPrimary"))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(Color("AppPrimary").opacity(0.12))
                            AxisValueLabel().foregroundStyle(Color("AppPrimary").opacity(0.7))
                        }
                    }
                    .frame(height: 180)
                    HStack(spacing: 14) {
                        legendDot(Color("AppAccent"), "Jars")
                        legendDot(Color("AppPrimary").opacity(0.55), "Plates")
                        legendDot(Color("AppPrimary"), "Cooks")
                    }
                    .font(.system(.caption2, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.7))
                }

                chartCard(title: "Market list mix", detail: marketSlices.isEmpty ? "Add spices to the list to see the split." : "Jars grouped by the stall they belong to.") {
                    if marketSlices.isEmpty {
                        emptyChart()
                    } else {
                        HStack(alignment: .center, spacing: 16) {
                            CategoryRing(slices: marketSlices)
                                .frame(width: 132, height: 132)
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(marketSlices) { slice in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Self.color(for: slice.category))
                                            .frame(width: 8, height: 8)
                                        Text(slice.category)
                                            .font(.system(.caption, design: .serif))
                                            .foregroundColor(Color("AppPrimary"))
                                        Spacer()
                                        Text("\(slice.count)")
                                            .font(.system(.caption, design: .serif).weight(.bold))
                                            .foregroundColor(Color("AppPrimary"))
                                    }
                                }
                            }
                        }
                    }
                }

                chartCard(title: "List progress", detail: store.market.isEmpty ? "Nothing on the list yet." : "Still to buy versus already in the bag.") {
                    Chart {
                        BarMark(
                            x: .value("Count", store.market.filter { !$0.purchased }.count),
                            y: .value("State", "Still to buy")
                        )
                        .foregroundStyle(Color("AppPrimary"))
                        BarMark(
                            x: .value("Count", store.market.filter(\.purchased).count),
                            y: .value("State", "In the bag")
                        )
                        .foregroundStyle(Color("AppAccent"))
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(Color("AppPrimary").opacity(0.12))
                            AxisValueLabel().foregroundStyle(Color("AppPrimary").opacity(0.7))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisValueLabel().foregroundStyle(Color("AppPrimary"))
                        }
                    }
                    .frame(height: 110)
                }
            }
            .padding(20)
        }
        .kitchenScreen()
    }

    private func statChip(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 22, design: .serif).weight(.bold))
                .foregroundColor(Color("AppPrimary"))
            Text(title)
                .font(.system(.caption2, design: .serif))
                .foregroundColor(Color("AppPrimary").opacity(0.65))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.88))
        .overlay(Rectangle().stroke(Color("AppPrimary").opacity(0.12), lineWidth: 1))
    }

    private func chartCard<Content: View>(title: String, detail: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.title3, design: .serif))
                .foregroundColor(Color("AppPrimary"))
            Text(detail)
                .font(.system(.footnote, design: .serif))
                .foregroundColor(Color("AppPrimary").opacity(0.7))
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.9))
        .overlay(alignment: .leading) {
            Rectangle().fill(Color("AppPrimary")).frame(width: 5)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 3, x: 1, y: 2)
    }

    private func emptyChart() -> some View {
        Rectangle()
            .fill(Color("AppPrimary").opacity(0.04))
            .frame(height: 88)
            .overlay(
                Text("No marks on this page yet.")
                    .font(.system(.caption, design: .serif))
                    .foregroundColor(Color("AppPrimary").opacity(0.5))
            )
    }

    private func legendDot(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title)
        }
    }

    private var spiceUsage: [SpiceUse] {
        var counts: [String: Int] = [:]
        for blend in store.blends {
            for id in Set(blend.spiceIds) {
                counts[id, default: 0] += 1
            }
        }
        return SpiceCatalog.all.compactMap { spice in
            guard let count = counts[spice.id], count > 0 else { return nil }
            return SpiceUse(name: spice.name, count: count)
        }
        .sorted { $0.count > $1.count }
    }

    private var marketSlices: [MarketSlice] {
        Dictionary(grouping: store.market, by: \.category)
            .map { MarketSlice(category: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private var weekPoints: [WeekPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return WeekPoint(
                day: day,
                blends: store.blends.filter { calendar.isDate($0.createdAt, inSameDayAs: day) }.count,
                views: store.recipeViewDates.filter { calendar.isDate($0, inSameDayAs: day) }.count,
                cooks: store.cookDates.filter { calendar.isDate($0, inSameDayAs: day) }.count
            )
        }
    }

    private var weekSeries: [WeekSeriesPoint] {
        weekPoints.flatMap { point in
            [
                WeekSeriesPoint(day: point.day, kind: "Jars", count: point.blends),
                WeekSeriesPoint(day: point.day, kind: "Plates", count: point.views),
                WeekSeriesPoint(day: point.day, kind: "Cooks", count: point.cooks)
            ]
        }
    }

    static func color(for category: String) -> Color {
        switch category {
        case "Herbs": return Color("AppPrimary")
        case "Seeds": return Color("AppAccent")
        case "Powders": return Color(red: 0.72, green: 0.45, blue: 0.18)
        case "Heat": return Color(red: 0.78, green: 0.22, blue: 0.16)
        case "Bark": return Color(red: 0.45, green: 0.28, blue: 0.18)
        case "Pods": return Color(red: 0.55, green: 0.42, blue: 0.22)
        default: return Color("AppPrimary").opacity(0.45)
        }
    }
}

private struct SpiceUse: Identifiable {
    var id: String { name }
    var name: String
    var count: Int
}

private struct MarketSlice: Identifiable {
    var id: String { category }
    var category: String
    var count: Int
}

private struct WeekPoint: Identifiable {
    var id: Date { day }
    var day: Date
    var blends: Int
    var views: Int
    var cooks: Int
    var total: Int { blends + views + cooks }
}

private struct WeekSeriesPoint: Identifiable {
    var id: String { "\(day.timeIntervalSince1970)-\(kind)" }
    var day: Date
    var kind: String
    var count: Int
}

private struct CategoryRing: View {
    let slices: [MarketSlice]

    var body: some View {
        Canvas { context, size in
            let total = slices.reduce(0) { $0 + $1.count }
            guard total > 0 else { return }
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 4
            var start = Angle.degrees(-90)
            for slice in slices {
                let fraction = Double(slice.count) / Double(total)
                let end = start + .degrees(360 * fraction)
                var path = Path()
                path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
                path.addArc(center: center, radius: radius * 0.58, startAngle: end, endAngle: start, clockwise: true)
                path.closeSubpath()
                context.fill(path, with: .color(KitchenStatsView.color(for: slice.category)))
                start = end
            }
        }
    }
}
