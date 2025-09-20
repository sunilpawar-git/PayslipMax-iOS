
import Foundation

@MainActor
class PayslipDataService {
    private let dataHandler: PayslipDataHandler

    init(dataHandler: PayslipDataHandler) {
        self.dataHandler = dataHandler
    }

    func loadRecentPayslips() async throws -> [PayslipDTO] {
        return try await dataHandler.loadRecentPayslips()
    }

    func savePayslipItem(_ payslipDTO: PayslipDTO) async throws -> UUID {
        return try await dataHandler.savePayslipItem(payslipDTO)
    }
}
