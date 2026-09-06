import Foundation
import Combine

@MainActor
final class LedgerStore: ObservableObject {
    @Published private(set) var transactions: [LedgerTransaction] = []
    @Published private(set) var categories: [LedgerCategory] = []

    private let transactionsKey = "simple-ledger.transactions.v1"
    private let categoriesKey = "simple-ledger.categories.v1"
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func categories(for kind: TransactionKind) -> [LedgerCategory] {
        categories.filter { $0.kind == kind && $0.isCustom }
    }

    func category(for id: UUID) -> LedgerCategory? {
        categories.first { $0.id == id }
    }

    @discardableResult
    func addCategory(name: String, symbol: String = "square.grid.2x2.fill", kind: TransactionKind) -> LedgerCategory? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let existing = categories.first(where: { $0.kind == kind && $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing
        }
        let category = LedgerCategory(name: trimmed, symbol: symbol, kind: kind, isCustom: true)
        categories.append(category)
        saveCategories()
        return category
    }

    func addTransaction(kind: TransactionKind, amount: Double, categoryID: UUID, note: String, date: Date) {
        guard amount > 0 else { return }
        let item = LedgerTransaction(kind: kind, amount: amount, categoryID: categoryID, note: note.trimmingCharacters(in: .whitespacesAndNewlines), date: date)
        transactions.append(item)
        saveTransactions()
    }

    func updateTransaction(id: UUID, kind: TransactionKind, amount: Double, categoryID: UUID, note: String, date: Date) {
        guard amount > 0, let index = transactions.firstIndex(where: { $0.id == id }) else { return }
        transactions[index] = LedgerTransaction(id: id, kind: kind, amount: amount, categoryID: categoryID, note: note.trimmingCharacters(in: .whitespacesAndNewlines), date: date)
        saveTransactions()
    }

    func deleteTransaction(id: UUID) {
        transactions.removeAll { $0.id == id }
        saveTransactions()
    }

    func deleteTransactions(at offsets: IndexSet, from displayedItems: [LedgerTransaction]) {
        let ids = Set(offsets.compactMap { displayedItems.indices.contains($0) ? displayedItems[$0].id : nil })
        transactions.removeAll { ids.contains($0.id) }
        saveTransactions()
    }

    func transactions(in interval: DateInterval, kind: TransactionKind? = nil) -> [LedgerTransaction] {
        transactions
            .filter { interval.contains($0.date) && (kind == nil || $0.kind == kind) }
            .sorted { $0.date > $1.date }
    }

    func total(in interval: DateInterval, kind: TransactionKind) -> Double {
        transactions(in: interval, kind: kind).reduce(0) { $0 + $1.amount }
    }

    func categoryTotals(in interval: DateInterval, kind: TransactionKind) -> [CategoryTotal] {
        let items = transactions(in: interval, kind: kind)
        let grouped = Dictionary(grouping: items, by: \.categoryID)
        let values: [(LedgerCategory, Double)] = grouped.compactMap { categoryID, rows in
            guard let category = category(for: categoryID) else { return nil }
            return (category, rows.reduce(0) { $0 + $1.amount })
        }
        let maxAmount = values.map(\.1).max() ?? 0
        return values
            .map { CategoryTotal(category: $0.0, amount: $0.1, fraction: maxAmount > 0 ? $0.1 / maxAmount : 0) }
            .sorted { $0.amount > $1.amount }
    }

    func makeBackup() -> LedgerBackup {
        LedgerBackup(
            version: 1,
            exportedAt: Date(),
            categories: categories,
            transactions: transactions
        )
    }

    func importBackup(_ backup: LedgerBackup) throws {
        guard backup.version == 1 else { throw LedgerBackupError.unsupportedVersion }
        let importedCategories = backup.categories
        guard Set(importedCategories.map(\.id)).count == importedCategories.count else {
            throw LedgerBackupError.invalidData
        }
        let categoryKinds = Dictionary(uniqueKeysWithValues: importedCategories.map { ($0.id, $0.kind) })
        let isValid = backup.transactions.allSatisfy { item in
            item.amount > 0 && categoryKinds[item.categoryID] == item.kind
        }
        guard isValid else { throw LedgerBackupError.invalidData }

        categories = importedCategories
        transactions = backup.transactions
        saveCategories()
        saveTransactions()
    }

    func deleteAllLocalData() {
        transactions = []
        categories = []
        saveTransactions()
        saveCategories()
    }

    private func load() {
        if let data = defaults.data(forKey: categoriesKey),
           let decoded = try? decoder.decode([LedgerCategory].self, from: data) {
            categories = decoded
        } else {
            categories = []
            saveCategories()
        }

        if let data = defaults.data(forKey: transactionsKey),
           let decoded = try? decoder.decode([LedgerTransaction].self, from: data) {
            transactions = decoded
        }
    }

    private func saveTransactions() {
        guard let data = try? encoder.encode(transactions) else { return }
        defaults.set(data, forKey: transactionsKey)
    }

    private func saveCategories() {
        guard let data = try? encoder.encode(categories) else { return }
        defaults.set(data, forKey: categoriesKey)
    }

}
