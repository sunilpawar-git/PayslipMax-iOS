import SwiftUI

struct ManagePersonalDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: FocusField?
    
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userAccountNumber") private var accountNumber: String = ""
    @AppStorage("userPANNumber") private var panNumber: String = ""
    
    enum FocusField {
        case name, accountNumber, panNumber
    }
    
    var body: some View {
        ZStack {
                            FintechColors.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Personal Information")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Name")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your name", text: $userName)
                                .focused($focusedField, equals: .name)
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .accountNumber
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Account Number")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your account number", text: $accountNumber)
                                .focused($focusedField, equals: .accountNumber)
                                .keyboardType(.numberPad)
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .panNumber
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("PAN Number")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your PAN number", text: $panNumber)
                                .focused($focusedField, equals: .panNumber)
                                .autocapitalization(.allCharacters)
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                                .submitLabel(.done)
                                .onSubmit {
                                    focusedField = nil
                                }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    
                    Text("These details will be used to autofill when creating new payslips or when the PDF parser cannot extract this information.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
        .navigationTitle("Personal Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    focusedField = nil
                    dismiss()
                }
            }
            
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }
}

struct ManagePersonalDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ManagePersonalDetailsView()
        }
    }
} 