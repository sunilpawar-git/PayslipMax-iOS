
import Foundation

@MainActor
class PayslipDataService {
    private let dataHandler: PayslipDataHandler

    init(dataHandler: PayslipDataHandler) {
        self.dataHandler = dataHandler
    }

    func loadRecentPayslips() async throws -> [AnyPayslip] {
        return try await dataHandler.loadRecentPayslips()
    }

    func savePayslipItem(_ payslipItem: PayslipItem) async throws {
        try await dataHandler.savePayslipItem(payslipItem)
    }
}
