import Foundation

enum InterestType: String, Codable, CaseIterable {
    case none = "none"
    case creditCardRevolving = "creditCardRevolving"
    case equalInstallment = "equalInstallment"
    case equalPrincipal = "equalPrincipal"
    case interestOnly = "interestOnly"

    var displayName: String {
        switch self {
        case .none: return "无利息"
        case .creditCardRevolving: return "信用卡循环利息"
        case .equalInstallment: return "等额本息"
        case .equalPrincipal: return "等额本金"
        case .interestOnly: return "先息后本"
        }
    }
}

struct InterestResult: Identifiable {
    let id = UUID()
    let period: Int
    let payment: Double          // 月供
    let principal: Double        // 本金部分
    let interest: Double         // 利息部分
    let remainingPrincipal: Double // 剩余本金

    var totalPaid: Double { principal + interest }
}

enum InterestCalculator {

    // MARK: - 信用卡循环利息

    /// 计算信用卡本期利息 (按日计息)
    /// - Parameters:
    ///   - principal: 未还本金
    ///   - annualRate: 年利率 (0.18 = 18%)
    ///   - days: 计息天数
    /// - Returns: 利息金额
    static func creditCardRevolvingInterest(
        principal: Double,
        annualRate: Double,
        days: Int
    ) -> Double {
        let dailyRate = annualRate / 365.0
        return principal * dailyRate * Double(days)
    }

    // MARK: - 等额本息

    /// 等额本息还款计划
    /// - Parameters:
    ///   - principal: 贷款总额
    ///   - annualRate: 年利率
    ///   - totalPeriods: 总期数 (月)
    /// - Returns: 每期还款明细
    static func equalInstallmentPlan(
        principal: Double,
        annualRate: Double,
        totalPeriods: Int
    ) -> [InterestResult] {
        let monthlyRate = annualRate / 12.0
        var results: [InterestResult] = []
        var remaining = principal

        // 月供 = P × r × (1+r)^n / ((1+r)^n - 1)
        let powTerm = pow(1 + monthlyRate, Double(totalPeriods))
        let monthlyPayment = principal * monthlyRate * powTerm / (powTerm - 1)

        for i in 1...totalPeriods {
            let interestPart = remaining * monthlyRate
            let principalPart = monthlyPayment - interestPart
            remaining -= principalPart
            if remaining < 0 { remaining = 0 }

            results.append(InterestResult(
                period: i,
                payment: monthlyPayment,
                principal: principalPart,
                interest: interestPart,
                remainingPrincipal: remaining
            ))
        }
        return results
    }

    // MARK: - 等额本金

    /// 等额本金还款计划
    static func equalPrincipalPlan(
        principal: Double,
        annualRate: Double,
        totalPeriods: Int
    ) -> [InterestResult] {
        let monthlyRate = annualRate / 12.0
        let monthlyPrincipal = principal / Double(totalPeriods)
        var results: [InterestResult] = []
        var remaining = principal

        for i in 1...totalPeriods {
            let interestPart = remaining * monthlyRate
            let monthlyPayment = monthlyPrincipal + interestPart
            remaining -= monthlyPrincipal
            if remaining < 0 { remaining = 0 }

            results.append(InterestResult(
                period: i,
                payment: monthlyPayment,
                principal: monthlyPrincipal,
                interest: interestPart,
                remainingPrincipal: remaining
            ))
        }
        return results
    }

    // MARK: - 先息后本

    /// 先息后本还款计划
    static func interestOnlyPlan(
        principal: Double,
        annualRate: Double,
        totalPeriods: Int
    ) -> [InterestResult] {
        let monthlyRate = annualRate / 12.0
        let monthlyInterest = principal * monthlyRate
        var results: [InterestResult] = []

        for i in 1...totalPeriods {
            let isLast = i == totalPeriods
            let principalPart = isLast ? principal : 0
            let payment = isLast ? (monthlyInterest + principal) : monthlyInterest

            results.append(InterestResult(
                period: i,
                payment: payment,
                principal: principalPart,
                interest: monthlyInterest,
                remainingPrincipal: isLast ? 0 : principal
            ))
        }
        return results
    }

    // MARK: - 通用计算

    /// 根据类型计算还款计划
    static func calculate(
        type: InterestType,
        principal: Double,
        annualRate: Double,
        totalPeriods: Int
    ) -> [InterestResult] {
        switch type {
        case .none, .creditCardRevolving:
            return []
        case .equalInstallment:
            return equalInstallmentPlan(principal: principal, annualRate: annualRate, totalPeriods: totalPeriods)
        case .equalPrincipal:
            return equalPrincipalPlan(principal: principal, annualRate: annualRate, totalPeriods: totalPeriods)
        case .interestOnly:
            return interestOnlyPlan(principal: principal, annualRate: annualRate, totalPeriods: totalPeriods)
        }
    }

    /// 计算当前期应还利息 (用于自动扣费)
    /// - Parameters:
    ///   - type: 利息类型
    ///   - principal: 剩余本金
    ///   - annualRate: 年利率
    ///   - currentPeriod: 当前期数 (1-based)
    ///   - totalPeriods: 总期数
    /// - Returns: 本期利息
    static func currentPeriodInterest(
        type: InterestType,
        principal: Double,
        annualRate: Double,
        currentPeriod: Int,
        totalPeriods: Int
    ) -> Double {
        switch type {
        case .none:
            return 0
        case .creditCardRevolving:
            // 默认按30天计息
            return creditCardRevolvingInterest(principal: principal, annualRate: annualRate, days: 30)
        case .equalInstallment:
            let plan = equalInstallmentPlan(principal: principal, annualRate: annualRate, totalPeriods: totalPeriods)
            let idx = min(currentPeriod - 1, plan.count - 1)
            return idx >= 0 ? plan[idx].interest : 0
        case .equalPrincipal:
            let plan = equalPrincipalPlan(principal: principal, annualRate: annualRate, totalPeriods: totalPeriods)
            let idx = min(currentPeriod - 1, plan.count - 1)
            return idx >= 0 ? plan[idx].interest : 0
        case .interestOnly:
            let plan = interestOnlyPlan(principal: principal, annualRate: annualRate, totalPeriods: totalPeriods)
            let idx = min(currentPeriod - 1, plan.count - 1)
            return idx >= 0 ? plan[idx].interest : 0
        }
    }

    /// 格式化百分比
    static func formatRate(_ rate: Double) -> String {
        String(format: "%.2f%%", rate * 100)
    }
}
