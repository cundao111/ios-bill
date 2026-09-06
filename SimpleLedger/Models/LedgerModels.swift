import Foundation
import SwiftUI

enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case expense = "支出"
    case income = "收入"

    var id: String { rawValue }
    var sign: String { self == .expense ? "-" : "+" }
    var color: Color { self == .expense ? .expenseCoral : .incomeGreen }
}

struct LedgerCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var symbol: String
    var kind: TransactionKind
    var isCustom: Bool

    init(id: UUID = UUID(), name: String, symbol: String, kind: TransactionKind, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.kind = kind
        self.isCustom = isCustom
    }
}

struct LedgerTransaction: Identifiable, Codable, Hashable {
    let id: UUID
    var kind: TransactionKind
    var amount: Double
    var categoryID: UUID
    var note: String
    var date: Date

    init(id: UUID = UUID(), kind: TransactionKind, amount: Double, categoryID: UUID, note: String, date: Date) {
        self.id = id
        self.kind = kind
        self.amount = amount
        self.categoryID = categoryID
        self.note = note
        self.date = date
    }
}

enum OverviewPeriod: String, CaseIterable, Identifiable {
    case week = "周"
    case month = "月"
    case year = "年"
    var id: String { rawValue }
}

struct CategoryTotal: Identifiable {
    let category: LedgerCategory
    let amount: Double
    let fraction: Double
    var id: UUID { category.id }
}

struct LedgerBackup: Codable {
    let version: Int
    let exportedAt: Date
    let categories: [LedgerCategory]
    let transactions: [LedgerTransaction]
}

enum LedgerBackupError: LocalizedError {
    case unsupportedVersion
    case invalidData

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion: return "备份版本不受支持"
        case .invalidData: return "备份内容不完整或已损坏"
        }
    }
}
