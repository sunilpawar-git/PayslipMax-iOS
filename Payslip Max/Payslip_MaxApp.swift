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
    @StateObject private var router = NavRouter()
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Payslip.self,
                Allowance.self,
                Deduction.self,
                PostingDetails.self,
                PayslipItem.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(container)
                .environmentObject(router)
                .onOpenURL { url in
                    // Handle deep links using our NavRouter
                    router.handleDeepLink(url)
                }
        }
    }
}
