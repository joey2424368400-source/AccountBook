import SwiftUI
import Charts

struct InterestCalculatorView: View {
    @State private var loanType: InterestType = .equalInstallment
    @State private var principalText: String = ""
    @State private var rateText: String = ""
    @State private var periodsText: String = ""
    @State private var results: [InterestResult] = []
    @State private var totalInterest: Double = 0
    @State private var totalPayment: Double = 0

    private var principal: Double { Double(principalText) ?? 0 }
    private var annualRate: Double { (Double(rateText) ?? 0) / 100 }
    private var totalPeriods: Int { Int(periodsText) ?? 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 输入区
                inputSection

                // 摘要
                if !results.isEmpty {
                    summarySection
                    amortizationChart
                    amortizationTable
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("利息计算器")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 输入区

    private var inputSection: some View {
        VStack(spacing: 12) {
            Picker("贷款类型", selection: $loanType) {
                ForEach([InterestType.equalInstallment, .equalPrincipal, .interestOnly], id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)

            VStack(spacing: 12) {
                HStack {
                    Text("贷款总额")
                        .font(.system(size: 15))
                    Spacer()
                    HStack(spacing: 4) {
                        Text("¥")
                            .foregroundColor(.secondary)
                        TextField("100000", text: $principalText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                HStack {
                    Text("年利率")
                        .font(.system(size: 15))
                    Spacer()
                    HStack(spacing: 4) {
                        TextField("4.9", text: $rateText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                HStack {
                    Text("还款期数")
                        .font(.system(size: 15))
                    Spacer()
                    HStack(spacing: 4) {
                        TextField("360", text: $periodsText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("月")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }

            Button(action: calculate) {
                Text("计算")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(valid ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!valid)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private var valid: Bool {
        principal > 0 && annualRate > 0 && totalPeriods > 0
    }

    // MARK: - 摘要

    private var summarySection: some View {
        HStack(spacing: 12) {
            SummaryCard(title: "月供 (首期)", amount: results.first?.payment ?? 0, color: .blue, icon: "calendar.badge.clock")
            SummaryCard(title: "利息总额", amount: totalInterest, color: .orange, icon: "percent")
            SummaryCard(title: "还款总额", amount: totalPayment, color: .purple, icon: "sum")
        }
    }

    // MARK: - 图表

    private var amortizationChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("每期月供构成")
                .font(.system(size: 14, weight: .semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                Chart {
                    ForEach(results.prefix(36)) { item in
                        BarMark(x: .value("期", "\(item.period)"),
                                y: .value("金额", item.principal))
                            .foregroundStyle(.blue)
                            .position(by: .value("类型", "本金"))
                    }
                    ForEach(results.prefix(36)) { item in
                        BarMark(x: .value("期", "\(item.period)"),
                                y: .value("金额", item.interest))
                            .foregroundStyle(.orange)
                            .position(by: .value("类型", "利息"))
                    }
                }
                .chartForegroundStyleScale(["本金": Color.blue, "利息": Color.orange])
                .frame(width: max(CGFloat(results.prefix(36).count) * 20, 300), height: 180)
            }

            HStack(spacing: 16) {
                legend(.blue, "本金")
                legend(.orange, "利息")
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func legend(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 12)).foregroundColor(.secondary)
        }
    }

    // MARK: - 还款明细表

    private var amortizationTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("还款明细表")
                .font(.system(size: 14, weight: .semibold))

            // 表头
            Grid(alignment: .trailing, horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    Text("期").font(.system(size: 11)).foregroundColor(.secondary)
                    Text("月供").font(.system(size: 11)).foregroundColor(.secondary).gridColumnAlignment(.trailing)
                    Text("本金").font(.system(size: 11)).foregroundColor(.secondary)
                    Text("利息").font(.system(size: 11)).foregroundColor(.secondary)
                    Text("剩余").font(.system(size: 11)).foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            Divider()

            ForEach(results.prefix(24)) { item in
                Grid(alignment: .trailing, horizontalSpacing: 12, verticalSpacing: 6) {
                    GridRow {
                        Text("\(item.period)")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                            .gridColumnAlignment(.leading)
                        Text(item.payment.formattedAmount)
                            .font(.system(size: 12, design: .rounded))
                        Text(item.principal.formattedAmount)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.blue)
                        Text(item.interest.formattedAmount)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.orange)
                        Text(item.remainingPrincipal.shortFormatted)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                if item.period < min(results.count, 24) {
                    Divider()
                }
            }

            if results.count > 24 {
                HStack {
                    Spacer()
                    Text("... 共 \(results.count) 期，只显示前24期")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - 计算

    private func calculate() {
        guard valid else { return }
        results = InterestCalculator.calculate(
            type: loanType,
            principal: principal,
            annualRate: annualRate,
            totalPeriods: totalPeriods
        )
        totalInterest = results.reduce(0) { $0 + $1.interest }
        totalPayment = results.reduce(0) { $0 + $1.payment }
    }
}
