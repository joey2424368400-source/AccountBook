import SwiftUI
import SwiftData

struct AccountManageView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    @State private var showAddSheet = false
    @State private var editingAccount: Account?

    var body: some View {
        List {
            ForEach(viewModel.accounts) { account in
                Button {
                    editingAccount = account
                    showAddSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: account.type.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(account.name)
                                .font(.system(size: 15, weight: .medium))
                            Text(account.type.displayName)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(account.balance.currencyFormatted)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete { offsets in
                for index in offsets {
                    viewModel.deleteAccount(viewModel.accounts[index], modelContext: modelContext)
                }
            }
        }
        .navigationTitle("账户管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingAccount = nil
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AccountEditView(account: editingAccount) { acc in
                viewModel.saveAccount(acc, modelContext: modelContext)
            }
        }
        .onAppear { viewModel.fetchAccounts(modelContext: modelContext) }
    }
}

struct AccountEditView: View {
    @Environment(\.dismiss) private var dismiss
    let existingAccount: Account?
    let onSave: (Account) -> Void

    @State private var name: String = ""
    @State private var type: AccountType = .bank
    @State private var initialBalance: String = ""
    @State private var currency: String = "CNY"

    init(account: Account?, onSave: @escaping (Account) -> Void) {
        self.existingAccount = account
        self.onSave = onSave
        if let acc = account {
            _name = State(initialValue: acc.name)
            _type = State(initialValue: acc.type)
            _initialBalance = State(initialValue: String(format: "%.2f", acc.initialBalance))
            _currency = State(initialValue: acc.currency)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("账户信息") {
                    TextField("账户名称", text: $name)
                    Picker("账户类型", selection: $type) {
                        ForEach(AccountType.allCases, id: \.self) { t in
                            HStack {
                                Image(systemName: t.icon)
                                Text(t.displayName)
                            }.tag(t)
                        }
                    }
                }

                Section("余额") {
                    HStack {
                        Text("¥")
                        TextField("0.00", text: $initialBalance)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle(existingAccount != nil ? "编辑账户" : "添加账户")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        let acc: Account
                        if let existing = existingAccount {
                            existing.name = name
                            existing.type = type
                            existing.initialBalance = Double(initialBalance) ?? 0
                            acc = existing
                        } else {
                            acc = Account(name: name, type: type, initialBalance: Double(initialBalance) ?? 0, currency: currency)
                        }
                        onSave(acc)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
