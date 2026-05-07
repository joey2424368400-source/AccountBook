import Foundation
import SwiftData
import UniformTypeIdentifiers
import SwiftUI

struct CSVExportableTransaction: Codable {
    let date: String
    let type: String
    let category: String
    let amount: String
    let account: String
    let note: String

    static func from(_ transaction: Transaction) -> CSVExportableTransaction {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"
        return CSVExportableTransaction(
            date: df.string(from: transaction.date),
            type: transaction.type.displayName,
            category: transaction.category?.name ?? "未分类",
            amount: String(format: "%.2f", transaction.amount),
            account: transaction.account?.name ?? "",
            note: transaction.note
        )
    }
}

enum CSVExportService {
    static func export(transactions: [Transaction]) -> URL? {
        let rows = transactions.map { CSVExportableTransaction.from($0) }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let header = "日期,类型,分类,金额,账户,备注\n"
        let body = rows.map { row in
            "\"\(row.date)\",\"\(row.type)\",\"\(row.category)\",\"\(row.amount)\",\"\(row.account)\",\"\(row.note.replacingOccurrences(of: "\"", with: "\"\""))\""
        }.joined(separator: "\n")

        let csvString = header + body
        let fileName = "记账导出_\(dateFormatter.string(from: Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("CSV export failed: \(error)")
            return nil
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
