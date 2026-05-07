import SwiftUI
import SwiftData

struct BudgetManageView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    @State private var showAddSheet = false
    @State private var editingBudget: Budget?

    var body: some View {
        Group {
            if viewModel.budgets.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "target")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("还没有设置预算")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Button {
                        editingBudget = nil
                        showAddSheet = true
                    } label: {
                        Label("添加预算", systemImage: "plus.circle.fill")
                            .font(.system(size: 15))
                    }
                }
            } else {
                List {
                    ForEach(viewModel.budgets) { budget in
                        BudgetProgressRow(budget: budget)
                            .padding(.vertical, 4)
                            .onTapGesture {
                                editingBudget = budget
                                showAddSheet = true
                            }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            viewModel.deleteBudget(viewModel.budgets[index], modelContext: modelContext)
                        }
                    }
                }
            }
        }
        .navigationTitle("预算管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingBudget = nil
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            BudgetEditView(budget: editingBudget) { b in
                viewModel.saveBudget(b, modelContext: modelContext)
            }
        }
        .onAppear { viewModel.fetchBudgets(modelContext: modelContext) }
    }
}

struct BudgetEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let existingBudget: Budget?
    let onSave: (Budget) -> Void

    @State private var amount: String = ""
    @State private var period: BudgetPeriod = .monthly
    @State private var selectedCategory: Category?

    private var expenseCategories: [Category] {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.typeRaw == TransactionType.expense.rawValue },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    init(budget: Budget?, onSave: @escaping (Budget) -> Void) {
        self.existingBudget = budget
        self.onSave = onSave
        if let b = budget {
            _amount = State(initialValue: String(format: "%.2f", b.amount))
            _period = State(initialValue: b.period)
            _selectedCategory = State(initialValue: b.category)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("预算金额") {
                    HStack {
                        Text("¥")
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("周期") {
                    Picker("周期", selection: $period) {
                        ForEach(BudgetPeriod.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                }

                Section("分类（可选）") {
                    Picker("分类", selection: $selectedCategory) {
                        Text("总预算").tag(nil as Category?)
                        ForEach(expenseCategories) { cat in
                            HStack {
                                CategoryIcon(icon: cat.icon, colorHex: cat.colorHex, size: 24)
                                Text(cat.name)
                            }.tag(cat as Category?)
                        }
                    }
                }
            }
            .navigationTitle(existingBudget != nil ? "编辑预算" : "添加预算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        let budget: Budget
                        if let existing = existingBudget {
                            existing.amount = Double(amount) ?? 0
                            existing.period = period
                            existing.category = selectedCategory
                            budget = existing
                        } else {
                            budget = Budget(amount: Double(amount) ?? 0, period: period, category: selectedCategory)
                        }
                        onSave(budget)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(amount.isEmpty || Double(amount) == nil)
                }
            }
        }
    }
}
