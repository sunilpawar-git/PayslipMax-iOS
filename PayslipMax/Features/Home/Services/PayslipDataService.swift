
import Foundation

@MainActor
class PayslipDataService {
    private let dataHandler: PayslipDataHandler

    init(dataHandler: PayslipDataHandler) {
        self.dataHandler = dataHandler
    }

    func loadRecentPayslips() async throws -> [PayslipDTO] {
        // Get PayslipItems from data handler and convert to DTOs
        let payslipItems = try await dataHandler.loadRecentPayslips()
        return payslipItems.map { PayslipDTO(from: $0) }
    }

    func savePayslipItem(_ payslipDTO: PayslipDTO) async throws -> UUID {
        return try await dataHandler.savePayslipItem(payslipDTO)
    }
}
