import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StatisticsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 时间范围选择
                Picker("时间范围", selection: $viewModel.selectedRange) {
                    ForEach(StatisticsRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: viewModel.selectedRange) { _, _ in
                    viewModel.fetchData(modelContext: modelContext)
                }

                // 收/支概览
                HStack(spacing: 12) {
                    SummaryCard(
                        title: "总收入",
                        amount: viewModel.totalIncome,
                        color: .green,
                        icon: "arrow.down.circle.fill"
                    )
                    SummaryCard(
                        title: "总支出",
                        amount: viewModel.totalExpense,
                        color: .red,
                        icon: "arrow.up.circle.fill"
                    )
                }
                .padding(.horizontal)

                // 分类饼图
                if !viewModel.categoryStats.isEmpty {
                    categoryPieChart
                }

                // 月度柱状图
                if !viewModel.monthlyStats.isEmpty {
                    monthlyBarChart
                }

                // 分类排行
                if !viewModel.categoryStats.isEmpty {
                    categoryRanking
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("统计")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.fetchData(modelContext: modelContext) }
    }

    // MARK: - 分类饼图

    private var categoryPieChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("支出分类占比")
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal)

            Chart(viewModel.categoryStats.prefix(6)) { stat in
                SectorMark(
                    angle: .value("金额", stat.amount),
                    innerRadius: .ratio(0.5),
                    angularInset: 1
                )
                .foregroundStyle(Color(hex: stat.category.colorHex))
            }
            .frame(height: 220)
            .padding(.horizontal)

            // 图例
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(viewModel.categoryStats.prefix(6)) { stat in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: stat.category.colorHex))
                            .frame(width: 8, height: 8)
                        Text(stat.category.name)
                            .font(.system(size: 12))
                        Spacer()
                        Text(String(format: "%.0f%%", stat.percentage * 100))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .padding(.horizontal)
    }

    // MARK: - 月度柱状图

    private var monthlyBarChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("月度收支趋势")
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal)

            Chart {
                ForEach(viewModel.monthlyStats) { stat in
                    BarMark(
                        x: .value("月份", stat.month),
                        y: .value("金额", stat.income)
                    )
                    .foregroundStyle(.green)
                    .position(by: .value("类型", "收入"))
                }
                ForEach(viewModel.monthlyStats) { stat in
                    BarMark(
                        x: .value("月份", stat.month),
                        y: .value("金额", stat.expense)
                    )
                    .foregroundStyle(.red)
                    .position(by: .value("类型", "支出"))
                }
            }
            .chartForegroundStyleScale(["收入": Color.green, "支出": Color.red])
            .frame(height: 220)
            .padding(.horizontal)

            HStack(spacing: 20) {
                legendDot(.green, "收入")
                legendDot(.red, "支出")
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .padding(.horizontal)
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 12)).foregroundColor(.secondary)
        }
    }

    // MARK: - 分类排行

    private var categoryRanking: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("支出排行")
                .font(.system(size: 15, weight: .semibold))

            ForEach(Array(viewModel.categoryStats.enumerated()), id: \.element.id) { index, stat in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(index < 3 ? .orange : .secondary)
                        .frame(width: 20)

                    CategoryIcon(icon: stat.category.icon, colorHex: stat.category.colorHex, size: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat.category.name)
                            .font(.system(size: 14))
                        Text(String(format: "%.1f%%", stat.percentage * 100))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(stat.amount.currencyFormatted)
                        .font(.system(size: 14, design: .rounded))
                }

                // 进度条
                GeometryReader { geo in
                    Capsule()
                        .fill(Color(hex: stat.category.colorHex).opacity(0.3))
                        .frame(width: geo.size.width * stat.percentage, height: 3)
                }
                .frame(height: 3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .padding(.horizontal)
    }
}
