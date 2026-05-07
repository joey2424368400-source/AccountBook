import SwiftUI

struct AmountText: View {
    let amount: Double
    let type: TransactionType
    var fontSize: CGFloat = 17

    private var sign: String {
        type == .income ? "+" : "-"
    }

    private var color: Color {
        type == .income ? .green : .red
    }

    var body: some View {
        Text("\(sign)\(abs(amount).currencyFormatted)")
            .font(.system(size: fontSize, weight: .medium, design: .rounded))
            .foregroundColor(color)
    }
}

struct CurrencyText: View {
    let amount: Double
    var fontSize: CGFloat = 17
    var color: Color = .primary

    var body: some View {
        Text(amount.currencyFormatted)
            .font(.system(size: fontSize, weight: .medium, design: .rounded))
            .foregroundColor(color)
    }
}
