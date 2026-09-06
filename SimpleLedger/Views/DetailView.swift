import SwiftUI

struct DetailView: View {
    @EnvironmentObject private var store: LedgerStore
    @State private var selectedMonth = Date()
    @State private var filter: TransactionKind?
    @State private var showingMonthPicker = false
    @State private var editingTransaction: LedgerTransaction?
    private let calendar = Calendar.current

    private var interval: DateInterval { calendar.monthInterval(containing: selectedMonth) }
    private var displayedItems: [LedgerTransaction] { store.transactions(in: interval, kind: filter) }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    monthControl
                    summaryCard
                    filterControl

                    if displayedItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 42, weight: .light))
                                .foregroundStyle(.tertiary)
                            Text("这个月还没有账单")
                                .font(.headline)
                            Text("点击下方 + 号记录第一笔")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)
                    } else {
                        ForEach(groupedItems, id: \.date) { group in
                            daySection(date: group.date, items: group.items)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(Color.appBackground)
            .navigationTitle("明细")
            .sheet(isPresented: $showingMonthPicker) {
                MonthPickerView(selection: $selectedMonth)
                    .presentationDetents([.height(330)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingTransaction) { item in
                TransactionEntryView(transaction: item)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var monthControl: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 40, height: 40)
            }
            Spacer()
            Button { showingMonthPicker = true } label: {
                HStack(spacing: 7) {
                    Text(selectedMonth.monthTitle)
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.primary)
            }
            Spacer()
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.top, 4)
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            SummaryValue(title: "本月支出", value: store.total(in: interval, kind: .expense), color: .expenseCoral)
            Divider().frame(height: 48)
            SummaryValue(title: "本月收入", value: store.total(in: interval, kind: .income), color: .incomeGreen)
        }
        .padding(.vertical, 18)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private var filterControl: some View {
        HStack(spacing: 8) {
            FilterChip(title: "全部", isSelected: filter == nil) { filter = nil }
            FilterChip(title: "支出", isSelected: filter == .expense) { filter = .expense }
            FilterChip(title: "收入", isSelected: filter == .income) { filter = .income }
            Spacer()
        }
    }

    private var groupedItems: [(date: Date, items: [LedgerTransaction])] {
        let groups = Dictionary(grouping: displayedItems) { calendar.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { ($0, groups[$0] ?? []) }
    }

    @ViewBuilder
    private func daySection(date: Date, items: [LedgerTransaction]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(date.shortDateText)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                let net = items.reduce(0) { $0 + ($1.kind == .income ? $1.amount : -$1.amount) }
                Text("收支 \(net.currencyText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 9)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    TransactionRow(item: item, category: store.category(for: item.categoryID))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingTransaction = item
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.deleteTransaction(id: item.id)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    if index < items.count - 1 { Divider().padding(.leading, 68) }
                }
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private func changeMonth(by amount: Int) {
        if let date = calendar.date(byAdding: .month, value: amount, to: selectedMonth) {
            selectedMonth = date
        }
    }
}

private struct SummaryValue: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value.currencyText)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(isSelected ? Color.brandBlue : Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct TransactionRow: View {
    let item: LedgerTransaction
    let category: LedgerCategory?

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: category?.symbol ?? "questionmark")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(item.kind.color)
                .frame(width: 42, height: 42)
                .background(item.kind.color.opacity(0.11), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(category?.name ?? "未知分类")
                    .font(.body.weight(.medium))
                Text(item.note.isEmpty ? item.date.timeText : "\(item.date.timeText) · \(item.note)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text("\(item.kind.sign)\(item.amount.currencyText)")
                .font(.body.weight(.semibold))
                .foregroundStyle(item.kind.color)
        }
        .padding(13)
    }
}

private struct MonthPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: Date
    @State private var year: Int
    @State private var month: Int
    private let calendar = Calendar.current

    init(selection: Binding<Date>) {
        _selection = selection
        _year = State(initialValue: Calendar.current.component(.year, from: selection.wrappedValue))
        _month = State(initialValue: Calendar.current.component(.month, from: selection.wrappedValue))
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                Picker("年份", selection: $year) {
                    ForEach((2000...2100).reversed(), id: \.self) { Text("\($0)年").tag($0) }
                }
                .pickerStyle(.wheel)
                Picker("月份", selection: $month) {
                    ForEach(1...12, id: \.self) { Text("\($0)月").tag($0) }
                }
                .pickerStyle(.wheel)
            }
            .navigationTitle("选择月份")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        var components = DateComponents()
                        components.year = year
                        components.month = month
                        components.day = 1
                        selection = calendar.date(from: components) ?? selection
                        dismiss()
                    }
                }
            }
        }
    }
}
