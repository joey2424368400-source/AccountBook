import SwiftUI
import SwiftData

struct ReminderManageView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationService: NotificationService
    @State private var viewModel = SettingsViewModel()
    @State private var showAddSheet = false
    @State private var editingReminder: BillReminder?

    var body: some View {
        Group {
            if viewModel.reminders.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("还没有账单提醒")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Button {
                        editingReminder = nil
                        showAddSheet = true
                    } label: {
                        Label("添加提醒", systemImage: "plus.circle.fill")
                    }
                }
            } else {
                List {
                    ForEach(viewModel.reminders) { reminder in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reminder.name)
                                    .font(.system(size: 15, weight: .medium))
                                Text(reminder.dueDate.monthAndYear)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                if !reminder.note.isEmpty {
                                    Text(reminder.note)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(reminder.amount.currencyFormatted)
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundColor(.red)

                                Text(reminder.repeatCycle.displayName)
                                    .font(.system(size: 11))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(4)
                            }
                        }
                        .onTapGesture {
                            editingReminder = reminder
                            showAddSheet = true
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                reminder.isEnabled.toggle()
                                notificationService.scheduleReminder(reminder)
                                try? modelContext.save()
                                viewModel.fetchReminders(modelContext: modelContext)
                            } label: {
                                Label(
                                    reminder.isEnabled ? "停用" : "启用",
                                    systemImage: reminder.isEnabled ? "bell.slash" : "bell"
                                )
                            }
                            .tint(reminder.isEnabled ? .orange : .green)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            viewModel.deleteReminder(viewModel.reminders[index], modelContext: modelContext, notificationService: notificationService)
                        }
                    }
                }
            }
        }
        .navigationTitle("账单提醒")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingReminder = nil
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            ReminderEditView(reminder: editingReminder) { reminder in
                viewModel.saveReminder(reminder, modelContext: modelContext, notificationService: notificationService)
            }
        }
        .onAppear { viewModel.fetchReminders(modelContext: modelContext) }
    }
}

struct ReminderEditView: View {
    @Environment(\.dismiss) private var dismiss
    let existingReminder: BillReminder?
    let onSave: (BillReminder) -> Void

    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var dueDate: Date = Date()
    @State private var repeatCycle: RepeatCycle = .none
    @State private var isEnabled: Bool = true
    @State private var note: String = ""

    init(reminder: BillReminder?, onSave: @escaping (BillReminder) -> Void) {
        self.existingReminder = reminder
        self.onSave = onSave
        if let r = reminder {
            _name = State(initialValue: r.name)
            _amount = State(initialValue: String(format: "%.2f", r.amount))
            _dueDate = State(initialValue: r.dueDate)
            _repeatCycle = State(initialValue: r.repeatCycle)
            _isEnabled = State(initialValue: r.isEnabled)
            _note = State(initialValue: r.note)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("账单信息") {
                    TextField("名称", text: $name)
                    HStack {
                        Text("¥")
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    DatePicker("到期日期", selection: $dueDate, displayedComponents: .date)
                    Picker("重复", selection: $repeatCycle) {
                        ForEach(RepeatCycle.allCases, id: \.self) { cycle in
                            Text(cycle.displayName).tag(cycle)
                        }
                    }
                    Toggle("启用提醒", isOn: $isEnabled)
                }

                Section {
                    TextField("备注", text: $note)
                }
            }
            .navigationTitle(existingReminder != nil ? "编辑提醒" : "添加提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        let reminder: BillReminder
                        if let existing = existingReminder {
                            existing.name = name
                            existing.amount = Double(amount) ?? 0
                            existing.dueDate = dueDate
                            existing.repeatCycle = repeatCycle
                            existing.isEnabled = isEnabled
                            existing.note = note
                            reminder = existing
                        } else {
                            reminder = BillReminder(
                                name: name,
                                amount: Double(amount) ?? 0,
                                dueDate: dueDate,
                                repeatCycle: repeatCycle,
                                isEnabled: isEnabled,
                                note: note
                            )
                        }
                        onSave(reminder)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
        }
    }
}
