import SwiftUI
import SwiftData

struct TransactionEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let existingTransaction: Transaction?
    @State private var amount: String = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var availableCategories: [Category] = []
    @State private var availableAccounts: [Account] = []

    init(transaction: Transaction? = nil) {
        self.existingTransaction = transaction
    }

    var body: some View {
        NavigationStack {
            Form {
                // 类型切换
                Section {
                    Picker("类型", selection: $selectedType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedType) { _, _ in loadCategories() }
                }

                // 金额
                Section {
                    HStack {
                        Text("¥")
                            .font(.system(size: 28, weight: .medium))
                        TextField("0.00", text: $amount)
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                    }
                }

                // 分类选择
                Section("分类") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 16) {
                        ForEach(availableCategories) { category in
                            categoryCell(category)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // 详细信息
                Section {
                    accountPicker
                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("备注", text: $note)
                }
            }
            .navigationTitle(existingTransaction != nil ? "编辑账单" : "记一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(amount.isEmpty || Double(amount) == nil || selectedCategory == nil)
                }
            }
            .onAppear {
                loadCategories()
                loadAccounts()
                if let tx = existingTransaction {
                    amount = String(format: "%.2f", tx.amount)
                    selectedType = tx.type
                    selectedCategory = tx.category
                    selectedAccount = tx.account
                    date = tx.date
                    note = tx.note
                }
            }
        }
    }

    private func categoryCell(_ category: Category) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(selectedCategory?.id == category.id ? Color(hex: category.colorHex) : Color(hex: category.colorHex).opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(selectedCategory?.id == category.id ? .white : Color(hex: category.colorHex))
            }
            Text(category.name)
                .font(.system(size: 11))
                .foregroundColor(selectedCategory?.id == category.id ? .primary : .secondary)
        }
        .onTapGesture { selectedCategory = category }
    }

    @ViewBuilder
    private var accountPicker: some View {
        if availableAccounts.isEmpty {
            EmptyView()
        } else {
            Picker("账户", selection: $selectedAccount) {
                Text("不选择").tag(nil as Account?)
                ForEach(availableAccounts) { account in
                    HStack {
                        Image(systemName: account.type.icon)
                        Text(account.name)
                    }.tag(account as Account?)
                }
            }
        }
    }

    private func loadCategories() {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.typeRaw == selectedType.rawValue },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        availableCategories = (try? modelContext.fetch(descriptor)) ?? []
        if selectedCategory?.type != selectedType {
            selectedCategory = availableCategories.first
        }
    }

    private func loadAccounts() {
        let descriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortOrder)])
        availableAccounts = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func save() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }

        if let tx = existingTransaction {
            tx.amount = amountValue
            tx.type = selectedType
            tx.category = selectedCategory
            tx.account = selectedAccount
            tx.date = date
            tx.note = note
        } else {
            let transaction = Transaction(
                amount: amountValue,
                note: note,
                date: date,
                type: selectedType,
                category: selectedCategory,
                account: selectedAccount
            )
            modelContext.insert(transaction)
        }
        try? modelContext.save()
        dismiss()
    }
}
