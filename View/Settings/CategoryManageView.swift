import SwiftUI
import SwiftData

struct CategoryManageView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    @State private var showAddSheet = false
    @State private var editingCategory: Category?
    @State private var selectedTab: TransactionType = .expense

    var body: some View {
        VStack(spacing: 0) {
            Picker("类型", selection: $selectedTab) {
                Text("支出").tag(TransactionType.expense)
                Text("收入").tag(TransactionType.income)
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                ForEach(filteredCategories) { category in
                    HStack(spacing: 12) {
                        CategoryIcon(icon: category.icon, colorHex: category.colorHex)
                        Text(category.name)
                            .font(.system(size: 15))
                        Spacer()
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingCategory = category
                        showAddSheet = true
                    }
                }
                .onDelete { offsets in
                    let items = offsets.map { filteredCategories[$0] }
                    for cat in items { viewModel.deleteCategory(cat, modelContext: modelContext) }
                }
                .onMove { from, to in
                    var cats = filteredCategories
                    cats.move(fromOffsets: from, toOffset: to)
                    for (index, cat) in cats.enumerated() {
                        cat.sortOrder = index
                    }
                    try? modelContext.save()
                    viewModel.fetchCategories(modelContext: modelContext)
                }
            }
        }
        .navigationTitle("分类管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingCategory = nil
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showAddSheet) {
            CategoryEditView(category: editingCategory, type: selectedTab) { cat in
                viewModel.saveCategory(cat, modelContext: modelContext)
            }
        }
        .onAppear { viewModel.fetchCategories(modelContext: modelContext) }
    }

    private var filteredCategories: [Category] {
        viewModel.categories.filter { $0.type == selectedTab }
    }
}

// MARK: - 分类编辑

struct CategoryEditView: View {
    @Environment(\.dismiss) private var dismiss
    let existingCategory: Category?
    let type: TransactionType
    let onSave: (Category) -> Void

    @State private var name: String = ""
    @State private var selectedIcon: String = "questionmark.circle"
    @State private var selectedColor: String = "#007AFF"
    @State private var sortOrder: Int = 0

    private let icons = [
        "fork.knife", "car.fill", "bag.fill", "gamecontroller.fill",
        "house.fill", "phone.fill", "cross.case.fill", "book.fill",
        "heart.fill", "basket.fill", "tshirt.fill", "banknote.fill",
        "gift.fill", "chart.line.uptrend.xyaxis", "briefcase.fill",
        "airplane", "cart.fill", "pawprint.fill", "wrench.fill",
        "film.fill", "music.note", "camera.fill", "sportscourt.fill",
        "leaf.fill", "building.columns.fill", "creditcard.fill",
        "lightbulb.fill", "star.fill", "flag.fill", "ellipsis.circle.fill"
    ]

    private let colors = [
        "#FF6B6B", "#4ECDC4", "#FFD93D", "#6C5CE7", "#A8E6CF",
        "#74B9FF", "#FF8A5C", "#B794F4", "#FD79A8", "#FDCB6E",
        "#E17055", "#00B894", "#0984E3", "#E84393", "#636E72",
        "#2D3436", "#55E6C1", "#F8B500", "#6AB04C", "#4834D4"
    ]

    init(category: Category?, type: TransactionType, onSave: @escaping (Category) -> Void) {
        self.existingCategory = category
        self.type = type
        self.onSave = onSave
        if let cat = category {
            _name = State(initialValue: cat.name)
            _selectedIcon = State(initialValue: cat.icon)
            _selectedColor = State(initialValue: cat.colorHex)
            _sortOrder = State(initialValue: cat.sortOrder)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("名称") {
                    TextField("分类名称", text: $name)
                }

                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            ZStack {
                                Circle()
                                    .fill(selectedIcon == icon ? Color(hex: selectedColor) : Color(.systemGray6))
                                    .frame(width: 40, height: 40)
                                Image(systemName: icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                            }
                            .onTapGesture { selectedIcon = icon }
                        }
                    }
                }

                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    selectedColor == color ?
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .bold))
                                    : nil
                                )
                                .onTapGesture { selectedColor = color }
                        }
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            CategoryIcon(icon: selectedIcon, colorHex: selectedColor, size: 56)
                            Text(name.isEmpty ? "预览" : name)
                                .font(.system(size: 15))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle(existingCategory != nil ? "编辑分类" : "添加分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        let cat: Category
                        if let existing = existingCategory {
                            existing.name = name
                            existing.icon = selectedIcon
                            existing.colorHex = selectedColor
                            cat = existing
                        } else {
                            cat = Category(name: name, icon: selectedIcon, colorHex: selectedColor, type: type, sortOrder: sortOrder)
                        }
                        onSave(cat)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
