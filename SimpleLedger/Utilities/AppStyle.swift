import SwiftUI

extension Color {
    static let brandBlue = Color(red: 0.18, green: 0.38, blue: 0.95)
    static let incomeGreen = Color(red: 0.10, green: 0.67, blue: 0.48)
    static let expenseCoral = Color(red: 0.96, green: 0.35, blue: 0.33)
    static let appBackground = Color(uiColor: .systemGroupedBackground)
}

extension Double {
    var currencyText: String {
        formatted(.currency(code: "CNY").precision(.fractionLength(self.rounded() == self ? 0 : 2)))
    }
}

extension Date {
    var monthTitle: String { formatted(.dateTime.year().month(.wide).locale(Locale(identifier: "zh_CN"))) }
    var shortDateText: String { formatted(.dateTime.month().day().weekday(.abbreviated).locale(Locale(identifier: "zh_CN"))) }
    var timeText: String { formatted(.dateTime.hour().minute().locale(Locale(identifier: "zh_CN"))) }
}

extension Calendar {
    func monthInterval(containing date: Date) -> DateInterval {
        dateInterval(of: .month, for: date) ?? DateInterval(start: date, duration: 0)
    }

    func interval(for period: OverviewPeriod, containing date: Date) -> DateInterval {
        switch period {
        case .week: return dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 0)
        case .month: return dateInterval(of: .month, for: date) ?? DateInterval(start: date, duration: 0)
        case .year: return dateInterval(of: .year, for: date) ?? DateInterval(start: date, duration: 0)
        }
    }
}
