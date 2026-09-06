import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var store: LedgerStore
    @State private var period: OverviewPeriod = .month
    @State private var anchorDate = Date()
    @State private var kind: TransactionKind = .expense
    private let calendar = Calendar.current

    private var interval: DateInterval { calendar.interval(for: period, containing: anchorDate) }
    private var total: Double { store.total(in: interval, kind: kind) }
    private var rows: [CategoryTotal] { store.categoryTotals(in: interval, kind: kind) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Picker("统计周期", selection: $period) {
                        ForEach(OverviewPeriod.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: period) { _ in anchorDate = Date() }

                    periodControl
                    heroCard

                    Picker("收支类型", selection: $kind) {
                        ForEach(TransactionKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Text("分类\(kind.rawValue)")
                                .font(.headline)
                            Spacer()
                            Text("共 \(rows.count) 类")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if rows.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.largeTitle)
                                    .foregroundStyle(.tertiary)
                                Text("当前周期暂无\(kind.rawValue)记录")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 46)
                        } else {
                            ForEach(rows) { row in
                                CategoryProgressRow(row: row, total: total, color: kind.color)
                            }
                        }
                    }
                    .padding(18)
                    .background(.background, in: RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 90)
            }
            .background(Color.appBackground)
            .navigationTitle("总览")
        }
    }

    private var periodControl: some View {
        HStack {
            Button { move(by: -1) } label: { Image(systemName: "chevron.left").frame(width: 40, height: 40) }
            Spacer()
            Text(periodTitle)
                .font(.headline)
            Spacer()
            Button { move(by: 1) } label: { Image(systemName: "chevron.right").frame(width: 40, height: 40) }
        }
    }

    private var heroCard: some View {
        VStack(spacing: 8) {
            Text("总\(kind.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Text(total.currencyText)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundStyle(.white)
            Text(rows.isEmpty ? "还没有数据" : "最高类别：\(rows[0].category.name)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.76))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            LinearGradient(colors: [kind.color, kind.color.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .shadow(color: kind.color.opacity(0.2), radius: 14, y: 7)
    }

    private var periodTitle: String {
        switch period {
        case .week:
            let end = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
            return "\(interval.start.formatted(.dateTime.month().day())) – \(end.formatted(.dateTime.month().day()))"
        case .month:
            return anchorDate.monthTitle
        case .year:
            return anchorDate.formatted(.dateTime.year().locale(Locale(identifier: "zh_CN")))
        }
    }

    private func move(by amount: Int) {
        let component: Calendar.Component = period == .week ? .weekOfYear : (period == .month ? .month : .year)
        anchorDate = calendar.date(byAdding: component, value: amount, to: anchorDate) ?? anchorDate
    }
}

private struct CategoryProgressRow: View {
    let row: CategoryTotal
    let total: Double
    let color: Color

    private var percentage: Int {
        guard total > 0 else { return 0 }
        return Int((row.amount / total * 100).rounded())
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 11) {
                Image(systemName: row.category.symbol)
                    .foregroundStyle(color)
                    .frame(width: 34, height: 34)
                    .background(color.opacity(0.11), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.category.name).font(.subheadline.weight(.semibold))
                    Text("占比 \(percentage)%").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(row.amount.currencyText)
                    .font(.subheadline.weight(.semibold))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.12))
                    Capsule()
                        .fill(color)
                        .frame(width: max(8, proxy.size.width * row.fraction))
                }
            }
            .frame(height: 8)
        }
    }
}
