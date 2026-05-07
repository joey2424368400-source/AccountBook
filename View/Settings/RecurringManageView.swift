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

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.amount.currencyFormatted)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(item.isEnabled ? .red : .secondary)
                if item.hasInterest {
                    HStack(spacing: 2) {
                        Image(systemName: "percent")
                            .font(.system(size: 8))
                        Text("\(InterestCalculator.formatRate(item.interestRate ?? 0))")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.orange)
                }
            }
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
    // 利息配置
    @State private var showInterestConfig: Bool = false
    @State private var interestRateText: String = ""
    @State private var selectedInterestType: InterestType = .none
    @State private var principalText: String = ""
    @State private var totalPeriodsText: String = ""
    @State private var previewResults: [InterestResult] = []

    private var expenseCategories: [Category] {
        let expenseRawValue = TransactionType.expense.rawValue
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.typeRaw == expenseRawValue },
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
            _showInterestConfig = State(initialValue: r.hasInterest)
            _interestRateText = State(initialValue: r.interestRate != nil ? String(format: "%.2f", r.interestRate! * 100) : "")
            _selectedInterestType = State(initialValue: r.interestType)
            _principalText = State(initialValue: r.principal != nil ? String(format: "%.0f", r.principal!) : "")
            _totalPeriodsText = State(initialValue: r.totalPeriods != nil ? "\(r.totalPeriods!)" : "")
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

                // 利息配置 (信用卡/贷款)
                if selectedType == .creditCard || selectedType == .loan {
                    Section {
                        Toggle("含利息", isOn: $showInterestConfig)
                        if showInterestConfig {
                            Picker("计息方式", selection: $selectedInterestType) {
                                ForEach([InterestType.equalInstallment, .equalPrincipal, .interestOnly, .creditCardRevolving], id: \.self) { t in
                                    Text(t.displayName).tag(t)
                                }
                            }
                            HStack {
                                Text("年利率")
                                Spacer()
                                TextField("4.9", text: $interestRateText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                Text("%")
                            }
                            HStack {
                                Text("贷款总额")
                                Spacer()
                                HStack(spacing: 4) {
                                    Text("¥")
                                    TextField("0", text: $principalText)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 100)
                                }
                            }
                            HStack {
                                Text("还款期数")
                                Spacer()
                                TextField("12", text: $totalPeriodsText)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                Text("月")
                            }
                            if !previewResults.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("月供 (首期):")
                                            .font(.system(size: 13))
                                        Text(previewResults.first!.payment.currencyFormatted)
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                        Spacer()
                                        Text("利息总额:")
                                            .font(.system(size: 13))
                                        Text(previewResults.reduce(0) { $0 + $1.interest }.currencyFormatted)
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(.orange)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    } header: {
                        Text("利息配置")
                    }
                    .onChange(of: interestRateText) { _, _ in refreshPreview() }
                    .onChange(of: selectedInterestType) { _, _ in refreshPreview() }
                    .onChange(of: principalText) { _, _ in refreshPreview() }
                    .onChange(of: totalPeriodsText) { _, _ in refreshPreview() }
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
                        let irate = showInterestConfig ? ((Double(interestRateText) ?? 0) / 100) : nil
                        let itype = showInterestConfig ? selectedInterestType : .none
                        let iprincipal = showInterestConfig ? (Double(principalText) ?? 0) : nil
                        let itotal = showInterestConfig ? (Int(totalPeriodsText) ?? 0) : nil

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
                            existing.interestRate = irate
                            existing.interestType = itype
                            existing.principal = iprincipal
                            existing.totalPeriods = itotal
                            existing.currentPeriod = 1
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
                                account: selectedAccount,
                                interestRate: irate,
                                interestType: itype,
                                principal: iprincipal,
                                totalPeriods: itotal,
                                currentPeriod: 1
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

    private func refreshPreview() {
        guard showInterestConfig,
              let rate = Double(interestRateText), rate > 0,
              let principal = Double(principalText), principal > 0,
              let periods = Int(totalPeriodsText), periods > 0 else {
            previewResults = []
            return
        }
        previewResults = InterestCalculator.calculate(
            type: selectedInterestType,
            principal: principal,
            annualRate: rate / 100,
            totalPeriods: periods
        )
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

                // 利息信息
                if recurring.hasInterest {
                    Section("利息信息") {
                        HStack {
                            Text("计息方式")
                            Spacer()
                            Text(recurring.interestType.displayName)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("年利率")
                            Spacer()
                            Text(InterestCalculator.formatRate(recurring.interestRate ?? 0))
                                .foregroundColor(.orange)
                        }
                        HStack {
                            Text("贷款总额")
                            Spacer()
                            Text((recurring.principal ?? 0).currencyFormatted)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("还款进度")
                            Spacer()
                            Text("\(recurring.currentPeriod) / \(recurring.totalPeriods ?? 0) 期")
                                .foregroundColor(.secondary)
                        }
                        if let current = recurring.interestResultForCurrentPeriod {
                            HStack {
                                Text("下期月供")
                                Spacer()
                                Text(current.payment.currencyFormatted)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.red)
                            }
                            HStack {
                                Text("  其中利息")
                                Spacer()
                                Text(current.interest.currencyFormatted)
                                    .foregroundColor(.orange)
                            }
                        }
                    }

                    // 还款计划表
                    let plan = recurring.amortizationPlan
                    if !plan.isEmpty {
                        Section("还款计划 (\(plan.count) 期)") {
                            // 表头
                            HStack(spacing: 0) {
                                Text("期").frame(width: 30, alignment: .leading).font(.system(size: 11)).foregroundColor(.secondary)
                                Text("月供").frame(maxWidth: .infinity, alignment: .trailing).font(.system(size: 11)).foregroundColor(.secondary)
                                Text("本金").frame(maxWidth: .infinity, alignment: .trailing).font(.system(size: 11)).foregroundColor(.secondary)
                                Text("利息").frame(maxWidth: .infinity, alignment: .trailing).font(.system(size: 11)).foregroundColor(.secondary)
                            }
                            ForEach(plan.prefix(18)) { item in
                                HStack(spacing: 0) {
                                    Text("\(item.period)").frame(width: 30, alignment: .leading).font(.system(size: 12, design: .rounded)).foregroundColor(item.period == recurring.currentPeriod ? .blue : .secondary)
                                    Text(item.payment.formattedAmount).frame(maxWidth: .infinity, alignment: .trailing).font(.system(size: 12, design: .rounded))
                                    Text(item.principal.formattedAmount).frame(maxWidth: .infinity, alignment: .trailing).font(.system(size: 12, design: .rounded)).foregroundColor(.blue)
                                    Text(item.interest.formattedAmount).frame(maxWidth: .infinity, alignment: .trailing).font(.system(size: 12, design: .rounded)).foregroundColor(.orange)
                                }
                                if item.period < plan.prefix(18).count {
                                    Divider()
                                }
                            }
                            if plan.count > 18 {
                                Text("... 共 \(plan.count) 期")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
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
