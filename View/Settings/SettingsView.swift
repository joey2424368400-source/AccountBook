import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showShareSheet = false
    @State private var csvURL: URL?
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        List {
            // 数据管理
            Section("数据管理") {
                NavigationLink(destination: CategoryManageView()) {
                    Label("分类管理", systemImage: "square.grid.2x2")
                }
                NavigationLink(destination: AccountManageView()) {
                    Label("账户管理", systemImage: "creditcard")
                }
                NavigationLink(destination: BudgetManageView()) {
                    Label("预算管理", systemImage: "target")
                }
                NavigationLink(destination: RecurringManageView()) {
                    Label("自动扣费", systemImage: "arrow.triangle.2.circlepath")
                }
                NavigationLink(destination: ReminderManageView()) {
                    Label("账单提醒", systemImage: "bell")
                }
            }

            // 数据导出
            Section("工具") {
                NavigationLink(destination: InterestCalculatorView()) {
                    Label("利息计算器", systemImage: "percent")
                }
                Button {
                    exportCSV()
                } label: {
                    Label("导出 CSV", systemImage: "square.and.arrow.up")
                }
            }

            // 关于
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("我的")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let url = csvURL {
                ShareSheet(items: [url])
            }
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func exportCSV() {
        let descriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        guard let transactions = try? modelContext.fetch(descriptor), !transactions.isEmpty else {
            alertMessage = "没有可导出的交易数据"
            showAlert = true
            return
        }
        if let url = CSVExportService.export(transactions: transactions) {
            csvURL = url
            showShareSheet = true
        } else {
            alertMessage = "导出失败"
            showAlert = true
        }
    }
}
