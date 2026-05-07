import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TransactionViewModel()
    @State private var showEditSheet = false
    @State private var editingTransaction: Transaction?

    var body: some View {
        VStack(spacing: 0) {
            // 筛选栏
            filterBar

            if viewModel.groupedTransactions.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(viewModel.groupedTransactions, id: \.month) { group in
                        Section {
                            ForEach(group.items) { transaction in
                                Button {
                                    editingTransaction = transaction
                                    showEditSheet = true
                                } label: {
                                    TransactionRow(transaction: transaction)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.delete(transaction, modelContext: modelContext)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Text(group.month)
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                let total = group.items.reduce(0) { $0 + ($1.type == .expense ? -$1.amount : $1.amount) }
                                Text(total.currencyFormatted)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(total >= 0 ? .green : .red)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("账单")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "搜索交易")
        .onChange(of: viewModel.searchText) { _, _ in viewModel.buildGroups() }
        .sheet(isPresented: $showEditSheet) {
            if let tx = editingTransaction {
                TransactionEditView(transaction: tx)
            }
        }
        .onAppear { viewModel.fetchTransactions(modelContext: modelContext) }
        .onChange(of: showEditSheet) { _, newValue in
            if !newValue { viewModel.fetchTransactions(modelContext: modelContext) }
        }
        .refreshable { viewModel.fetchTransactions(modelContext: modelContext) }
    }

    private var filterBar: some View {
        HStack(spacing: 12) {
            filterChip("全部", isSelected: viewModel.filterType == nil) {
                viewModel.filterType = nil
                viewModel.buildGroups()
            }
            ForEach(TransactionType.allCases, id: \.self) { type in
                filterChip(type.displayName, isSelected: viewModel.filterType == type) {
                    viewModel.filterType = type
                    viewModel.buildGroups()
                }
            }

            Spacer()

            if let category = viewModel.filterCategory {
                HStack(spacing: 4) {
                    Text(category.name)
                        .font(.system(size: 12))
                    Button {
                        viewModel.filterCategory = nil
                        viewModel.buildGroups()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            } else {
                Menu {
                    ForEach(viewModel.categoriesByType(.expense, modelContext: modelContext)) { cat in
                        Button(cat.name) {
                            viewModel.filterCategory = cat
                            viewModel.buildGroups()
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private func filterChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.4))
            Text("没有找到交易记录")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
}
