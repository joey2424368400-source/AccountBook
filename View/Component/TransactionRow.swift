import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            if let category = transaction.category {
                CategoryIcon(icon: category.icon, colorHex: category.colorHex)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category?.name ?? "未分类")
                    .font(.system(size: 15, weight: .medium))
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                AmountText(amount: transaction.amount, type: transaction.type, fontSize: 15)
                Text(transaction.date.relativeFormatted)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
