import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthViewModel.self) private var auth
    @State private var showShareSheet = false
    @State private var csvURL: URL?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSyncing = false
    @State private var showRestoreConfirm = false

    var body: some View {
        List {
            // 账号
            Section("账号") {
                HStack {
                    Text("当前账号")
                    Spacer()
                    Text(AuthService.shared.currentEmail ?? "")
                        .foregroundColor(.secondary)
                }
                Button(role: .destructive) {
                    auth.logout()
                } label: {
                    Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }

            // 数据同步
            Section("数据同步") {
                Button {
                    Task { await backupData() }
                } label: {
                    HStack {
                        Label("备份到云端", systemImage: "icloud.and.arrow.up")
                        Spacer()
                        if isSyncing {
                            ProgressView()
                        }
                    }
                }
                .disabled(isSyncing)

                Button {
                    showRestoreConfirm = true
                } label: {
                    Label("从云端恢复", systemImage: "icloud.and.arrow.down")
                }
                .disabled(isSyncing)

                if let lastSync = SyncService.shared.lastSyncedAt {
                    HStack {
                        Text("上次同步")
                        Spacer()
                        Text(formatSyncDate(lastSync))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }

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
        .alert("从云端恢复", isPresented: $showRestoreConfirm) {
            Button("取消", role: .cancel) {}
            Button("确定恢复", role: .destructive) {
                Task { await restoreData() }
            }
        } message: {
            Text("从云端恢复将覆盖本地所有数据，确定继续吗？")
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

    private func backupData() async {
        isSyncing = true
        defer { isSyncing = false }

        do {
            try await SyncService.shared.uploadBackup(modelContext: modelContext)
            alertMessage = "备份成功"
        } catch let error as APIError {
            alertMessage = error.localizedDescription
        } catch {
            alertMessage = "备份失败: \(error.localizedDescription)"
        }
        showAlert = true
    }

    private func restoreData() async {
        isSyncing = true
        defer { isSyncing = false }

        do {
            try await SyncService.shared.downloadRestore(modelContext: modelContext)
            alertMessage = "恢复成功"
        } catch let error as APIError {
            alertMessage = error.localizedDescription
        } catch {
            alertMessage = "恢复失败: \(error.localizedDescription)"
        }
        showAlert = true
    }

    private func formatSyncDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return isoString }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MM-dd HH:mm"
        return displayFormatter.string(from: date)
    }
}
