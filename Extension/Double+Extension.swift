import Foundation

extension Double {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }

    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.currencySymbol = "¥"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "¥\(formattedAmount)"
    }

    var shortFormatted: String {
        if abs(self) >= 10000 {
            return String(format: "%.1f万", self / 10000)
        } else if abs(self) >= 1000 {
            return String(format: "%.0f", self)
        } else {
            return String(format: "%.0f", self)
        }
    }
}
