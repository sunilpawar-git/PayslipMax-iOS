import SwiftUI

struct PayslipHeaderView: View {
    let title: String
    let monthYear: String
    let employeeName: String
    let companyName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(monthYear)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Employee")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(employeeName)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if !companyName.isEmpty {
                    VStack(alignment: .trailing) {
                        Text("Employer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(companyName)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(FintechColors.backgroundGray)
        .cornerRadius(10)
        .shadow(color: FintechColors.shadow, radius: 5, x: 0, y: 2)
    }
} 