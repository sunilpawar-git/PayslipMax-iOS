//
//  Payslip_MaxApp.swift
//  Payslip Max
//
//  Created by Sunil on 21/01/25.
//

import SwiftUI
import SwiftData

@main
struct Payslip_MaxApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Payslip.self,
                Allowance.self,
                Deduction.self,
                PostingDetails.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
