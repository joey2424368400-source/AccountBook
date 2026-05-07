import SwiftUI
import SwiftData

struct RecurringManageView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    @State private var showAddSheet = false
    @State private var editingRecurring: RecurringTransaction?
    @State private var showHistorySheet = false
    @State private var selectedRecurring: RecurringTransaction?

    var body: some View {
        Group {
            if viewModel.recurringTransactions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("还没有自动扣费项目")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Text("信用卡还款、贷款、订阅会员等\n按月自动扣费的项目")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        editingRecurring = nil
                        showAddSheet = true
                    } label: {
                        Label("添加扣费项目", systemImage: "plus.circle.fill")
                    }
                }
            } else {
                List {
                    ForEach(RecurringType.allCases, id: \.self) { type in
                        let items = viewModel.recurringTransactions.filter { $0.type == type }
                        if !items.isEmpty {
                            Section(type.displayName) {
                                ForEach(items) { item in
                                    recurringRow(item)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("自动扣费")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingRecurring = nil
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            RecurringEditView(recurring: editingRecurring) { r in
                viewModel.saveRecurring(r, modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showHistorySheet) {
            if let selected = selectedRecurring {
                RecurringHistoryView(recurring: selected)
            }
        }
        .onAppear { viewModel.fetchRecurring(modelContext: modelContext) }
    }

    private func recurringRow(_ item: RecurringTransaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.type.icon)
                .font(.system(size: 20))
                .foregroundColor(.orange)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                HStack(spacing: 8) {
                    Text("下次: \(item.nextDueDate.monthAndYear)")
                        .font(.system(size: 11))
                    Text(item.cycle.displayName)
                        .font(.system(size: 11))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                    if !item.isEnabled {
                        Text("已停用")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            Text(item.amount.currencyFormatted)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(item.isEnabled ? .red : .secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedRecurring = item
            showHistorySheet = true
        }
        .swipeActions(edge: .leading) {
            Button {
                item.isEnabled.toggle()
                try? modelContext.save()
                viewModel.fetchRecurring(modelContext: modelContext)
            } label: {
                Label(item.isEnabled ? "停用" : "启用", systemImage: item.isEnabled ? "pause.circle" : "play.circle")
            }
            .tint(item.isEnabled ? .orange : .green)
        }
        .swipeActions(edge: .trailing) {
            Button {
                editingRecurring = item
                showAddSheet = true
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            .tint(.blue)

            Button(role: .destructive) {
                viewModel.deleteRecurring(item, modelContext: modelContext)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

// MARK: - 扣费编辑

struct RecurringEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let existingRecurring: RecurringTransaction?
    let onSave: (RecurringTransaction) -> Void

    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var selectedType: RecurringType = .subscription
    @State private var cycle: RecurringCycle = .monthly
    @State private var nextDueDate: Date = Date()
    @State private var isEnabled: Bool = true
    @State private var note: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?

    private var expenseCategories: [Category] {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.typeRaw == TransactionType.expense.rawValue },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var accounts: [Account] {
        let descriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortOrder)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    init(recurring: RecurringTransaction?, onSave: @escaping (RecurringTransaction) -> Void) {
        self.existingRecurring = recurring
        self.onSave = onSave
        if let r = recurring {
            _name = State(initialValue: r.name)
            _amount = State(initialValue: String(format: "%.2f", r.amount))
            _selectedType = State(initialValue: r.type)
            _cycle = State(initialValue: r.cycle)
            _nextDueDate = State(initialValue: r.nextDueDate)
            _isEnabled = State(initialValue: r.isEnabled)
            _note = State(initialValue: r.note)
            _selectedCategory = State(initialValue: r.category)
            _selectedAccount = State(initialValue: r.account)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("扣费信息") {
                    TextField("名称（如：招行信用卡）", text: $name)
                    HStack {
                        Text("¥")
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    Picker("类型", selection: $selectedType) {
                        ForEach(RecurringType.allCases, id: \.self) { t in
                            HStack {
                                Image(systemName: t.icon)
                                Text(t.displayName)
                            }.tag(t)
                        }
                    }
                    Picker("周期", selection: $cycle) {
                        ForEach(RecurringCycle.allCases, id: \.self) { c in
                            Text(c.displayName).tag(c)
                        }
                    }
                    DatePicker("下次扣费日期", selection: $nextDueDate, displayedComponents: .date)
                    Toggle("启用", isOn: $isEnabled)
                }

                Section("分类与账户") {
                    Picker("分类", selection: $selectedCategory) {
                        Text("不选择").tag(nil as Category?)
                        ForEach(expenseCategories) { cat in
                            HStack {
                                CategoryIcon(icon: cat.icon, colorHex: cat.colorHex, size: 24)
                                Text(cat.name)
                            }.tag(cat as Category?)
                        }
                    }
                    Picker("扣费账户", selection: $selectedAccount) {
                        Text("不选择").tag(nil as Account?)
                        ForEach(accounts) { acc in
                            HStack {
                                Image(systemName: acc.type.icon)
                                Text(acc.name)
                            }.tag(acc as Account?)
                        }
                    }
                }

                Section {
                    TextField("备注", text: $note)
                }
            }
            .navigationTitle(existingRecurring != nil ? "编辑扣费" : "添加扣费")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        let recurring: RecurringTransaction
                        if let existing = existingRecurring {
                            existing.name = name
                            existing.amount = Double(amount) ?? 0
                            existing.type = selectedType
                            existing.cycle = cycle
                            existing.nextDueDate = nextDueDate
                            existing.isEnabled = isEnabled
                            existing.note = note
                            existing.category = selectedCategory
                            existing.account = selectedAccount
                            recurring = existing
                        } else {
                            recurring = RecurringTransaction(
                                name: name,
                                amount: Double(amount) ?? 0,
                                type: selectedType,
                                cycle: cycle,
                                nextDueDate: nextDueDate,
                                isEnabled: isEnabled,
                                note: note,
                                category: selectedCategory,
                                account: selectedAccount
                            )
                        }
                        onSave(recurring)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
        }
    }
}

// MARK: - 扣费历史

struct RecurringHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    let recurring: RecurringTransaction

    private var historyTransactions: [Transaction] {
        recurring.generatedTransactions?.sorted { $0.date > $1.date } ?? []
    }

    var body: some View {
        NavigationStack {
            List {
                Section("扣费详情") {
                    HStack {
                        Text("名称")
                        Spacer()
                        Text(recurring.name)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("金额")
                        Spacer()
                        Text(recurring.amount.currencyFormatted)
                            .foregroundColor(.red)
                    }
                    HStack {
                        Text("周期")
                        Spacer()
                        Text(recurring.cycle.displayName)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("下次扣费")
                        Spacer()
                        Text(recurring.nextDueDate.monthAndYear)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("状态")
                        Spacer()
                        Text(recurring.isEnabled ? "启用中" : "已停用")
                            .foregroundColor(recurring.isEnabled ? .green : .secondary)
                    }
                }

                Section("扣费记录 (\(historyTransactions.count))") {
                    if historyTransactions.isEmpty {
                        Text("暂无扣费记录")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(historyTransactions) { tx in
                            TransactionRow(transaction: tx)
                        }
                    }
                }
            }
            .navigationTitle("扣费详情")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
