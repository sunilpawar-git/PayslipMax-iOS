import SwiftUI

/// A view for managing abbreviations
struct AbbreviationManagementView: View {
    @EnvironmentObject var abbreviationManager: AbbreviationManager
    @State private var searchText = ""
    @State private var showingAddNewSheet = false
    @State private var filterType: AbbreviationManager.AbbreviationType? = nil
    
    var filteredAbbreviations: [AbbreviationManager.AbbreviationInfo] {
        abbreviationManager.abbreviations.filter { abbr in
            let typeMatch = filterType == nil || abbr.type == filterType
            let searchMatch = searchText.isEmpty || 
                              abbr.abbreviation.localizedCaseInsensitiveContains(searchText) ||
                              abbr.fullName.localizedCaseInsensitiveContains(searchText)
            return typeMatch && searchMatch
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Filters")) {
                    Picker("Type", selection: $filterType) {
                        Text("All").tag(nil as AbbreviationManager.AbbreviationType?)
                        Text("Earnings").tag(AbbreviationManager.AbbreviationType.earning as AbbreviationManager.AbbreviationType?)
                        Text("Deductions").tag(AbbreviationManager.AbbreviationType.deduction as AbbreviationManager.AbbreviationType?)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Known Abbreviations")) {
                    ForEach(filteredAbbreviations) { abbr in
                        NavigationLink(destination: AbbreviationDetailView(abbreviation: abbr)) {
                            HStack {
                                Text(abbr.abbreviation)
                                    .bold()
                                Spacer()
                                Text(abbr.fullName)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Circle()
                                    .fill(abbr.type == .earning ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        showingAddNewSheet = true
                    }) {
                        Label("Add New Abbreviation", systemImage: "plus.circle")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search abbreviations")
            .navigationTitle("Abbreviations")
            .sheet(isPresented: $showingAddNewSheet) {
                AddNewAbbreviationView()
            }
        }
    }
}

/// A view for adding a new abbreviation
struct AddNewAbbreviationView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var abbreviationManager: AbbreviationManager
    
    @State private var abbreviation = ""
    @State private var fullName = ""
    @State private var selectedType: AbbreviationManager.AbbreviationType = .earning
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Abbreviation Details")) {
                    TextField("Abbreviation", text: $abbreviation)
                        .autocapitalization(.allCharacters)
                    
                    TextField("Full Name", text: $fullName)
                        .autocapitalization(.words)
                }
                
                Section(header: Text("Type")) {
                    Picker("Type", selection: $selectedType) {
                        Text("Earning").tag(AbbreviationManager.AbbreviationType.earning)
                        Text("Deduction").tag(AbbreviationManager.AbbreviationType.deduction)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Additional Information")) {
                    TextField("Notes (optional)", text: $notes)
                }
                
                Section {
                    Button("Save") {
                        abbreviationManager.addUserDefinedAbbreviation(
                            abbreviation: abbreviation,
                            fullName: fullName,
                            type: selectedType,
                            notes: notes.isEmpty ? nil : notes
                        )
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(abbreviation.isEmpty || fullName.isEmpty)
                }
            }
            .navigationTitle("Add Abbreviation")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

/// A view for displaying abbreviation details
struct AbbreviationDetailView: View {
    let abbreviation: AbbreviationManager.AbbreviationInfo
    
    var body: some View {
        List {
            Section(header: Text("Abbreviation Details")) {
                HStack {
                    Text("Abbreviation")
                    Spacer()
                    Text(abbreviation.abbreviation)
                        .bold()
                }
                
                HStack {
                    Text("Full Name")
                    Spacer()
                    Text(abbreviation.fullName)
                }
                
                HStack {
                    Text("Type")
                    Spacer()
                    Text(abbreviation.type == .earning ? "Earning" : "Deduction")
                        .foregroundColor(abbreviation.type == .earning ? .green : .red)
                }
                
                if let notes = abbreviation.notes {
                    HStack {
                        Text("Notes")
                        Spacer()
                        Text(notes)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Added")
                    Spacer()
                    Text(abbreviation.dateAdded, style: .date)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Source")
                    Spacer()
                    Text(abbreviation.isUserDefined ? "User Defined" : "System")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Abbreviation Details")
    }
}

struct AbbreviationManagementView_Previews: PreviewProvider {
    static var previews: some View {
        let abbreviationManager = AbbreviationManager()
        return AbbreviationManagementView()
            .environmentObject(abbreviationManager)
    }
} 