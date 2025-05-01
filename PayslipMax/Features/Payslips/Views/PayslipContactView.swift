import SwiftUI

// A custom group box style for better visual presentation
struct ContactSectionStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            configuration.content
                .padding(.leading, 4)
                .padding(.top, 2)
        }
        .padding(.vertical, 8)
    }
}

/// A view that displays contact information from a payslip
struct PayslipContactView: View {
    let contactInfo: ContactInfo
    
    var body: some View {
        if !contactInfo.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Contact Information")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "person.crop.circle.fill.badge.checkmark")
                        .foregroundColor(.blue)
                        .imageScale(.medium)
                }
                .padding(.bottom, 4)
                
                if !contactInfo.emails.isEmpty {
                    emailsSection
                        .transition(.opacity)
                }
                
                if !contactInfo.phoneNumbers.isEmpty {
                    phonesSection
                        .transition(.opacity)
                }
                
                if !contactInfo.websites.isEmpty {
                    websitesSection
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    private var emailsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(contactInfo.emails, id: \.self) { email in
                    Link(destination: URL(string: "mailto:\(email)")!) {
                        HStack {
                            Text(email)
                                .foregroundColor(.blue)
                                .underline()
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .foregroundColor(.blue.opacity(0.6))
                                .imageScale(.small)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        } label: {
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                Text("Email")
            }
        }
        .groupBoxStyle(ContactSectionStyle())
    }
    
    private var phonesSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(contactInfo.phoneNumbers, id: \.self) { phone in
                    let formattedPhone = formatPhoneNumber(phone)
                    Link(destination: URL(string: "tel:\(phone.filter { $0.isNumber })")!) {
                        HStack {
                            Text(formattedPhone)
                                .foregroundColor(.blue)
                                .underline()
                                .fixedSize(horizontal: true, vertical: false)
                            Spacer()
                            Image(systemName: "phone.arrow.up.right")
                                .foregroundColor(.green.opacity(0.7))
                                .imageScale(.small)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        } label: {
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.green)
                    .frame(width: 20)
                Text("Phone")
            }
        }
        .groupBoxStyle(ContactSectionStyle())
    }
    
    private var websitesSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(contactInfo.websites, id: \.self) { website in
                    let url = formatWebsiteURL(website)
                    Link(destination: url) {
                        HStack {
                            Text(cleanWebsiteDisplay(website))
                                .foregroundColor(.blue)
                                .underline()
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "safari")
                                .foregroundColor(.orange.opacity(0.7))
                                .imageScale(.small)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        } label: {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.orange)
                    .frame(width: 20)
                Text("Website")
            }
        }
        .groupBoxStyle(ContactSectionStyle())
    }
    
    // Helper to format phone numbers with enhanced military format support
    private func formatPhoneNumber(_ phone: String) -> String {
        // Clean up the input by removing extra spaces and normalizing parentheses
        var cleanPhone = phone.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "  ", with: " ")
        
        // Special case: Military extension numbers with multiple values like "(6512/6528/7761/7709)"
        if cleanPhone.contains("/") {
            return cleanPhone.replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .trimmingCharacters(in: .whitespaces)
        }
        
        // Special case: Military numbers with ":" format like "PRO CIVIL :((020) 2640- 1111/1333/1353/1356)"
        if cleanPhone.contains(":") {
            let parts = cleanPhone.split(separator: ":")
            if parts.count > 1 {
                let numberPart = String(parts[1]).trimmingCharacters(in: .whitespaces)
                // If it has multiple options after the colon, just clean it up
                if numberPart.contains("/") {
                    return numberPart.replacingOccurrences(of: "(", with: "")
                        .replacingOccurrences(of: ")", with: "")
                        .trimmingCharacters(in: .whitespaces)
                }
                return numberPart
            }
        }
        
        // Handle special cases for military numbers in the format (020-26401236)
        if cleanPhone.hasPrefix("(") && cleanPhone.contains("-") && cleanPhone.hasSuffix(")") {
            // Format like (020-26401236) -> (020) 2640-1236
            cleanPhone = cleanPhone.replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
            
            if let dashIndex = cleanPhone.firstIndex(of: "-") {
                let prefix = cleanPhone[..<dashIndex]
                let suffix = cleanPhone[cleanPhone.index(after: dashIndex)...]
                
                // Format the suffix with a dash if long enough
                var formattedSuffix = String(suffix)
                if suffix.count > 4 {
                    let splitIndex = suffix.index(suffix.endIndex, offsetBy: -4)
                    formattedSuffix = "\(suffix[..<splitIndex])-\(suffix[splitIndex...])"
                }
                
                return "(\(prefix)) \(formattedSuffix)"
            }
        }
        
        // If the phone is already in a good format with parentheses and dashes, keep it
        if (cleanPhone.contains("(") && cleanPhone.contains(")")) || cleanPhone.contains("-") {
            return cleanPhone
        }
        
        // Remove any non-digit characters for standard processing
        let digitsOnly = cleanPhone.filter { $0.isNumber }
        
        // Format 10-digit numbers as (XXX) XXX-XXXX
        if digitsOnly.count == 10 {
            let index1 = digitsOnly.index(digitsOnly.startIndex, offsetBy: 3)
            let index2 = digitsOnly.index(digitsOnly.startIndex, offsetBy: 6)
            
            let part1 = digitsOnly[..<index1]
            let part2 = digitsOnly[index1..<index2]
            let part3 = digitsOnly[index2...]
            
            return "(\(part1)) \(part2)-\(part3)"
        }
        
        // Format smaller number groups more consistently
        if digitsOnly.count >= 8 {
            let index1 = digitsOnly.index(digitsOnly.startIndex, offsetBy: digitsOnly.count >= 3 ? 3 : 0)
            let index2 = digitsOnly.index(digitsOnly.startIndex, offsetBy: min(digitsOnly.count - 4, 6))
            
            let part1 = digitsOnly[..<index1]
            let part2 = digitsOnly[index1..<index2]
            let part3 = digitsOnly[index2...]
            
            if !part1.isEmpty {
                return "(\(part1)) \(part2)-\(part3)"
            } else {
                return "\(part2)-\(part3)"
            }
        }
        
        // Just add spacing for very short numbers
        if digitsOnly.count >= 5 {
            let index = digitsOnly.index(digitsOnly.startIndex, offsetBy: digitsOnly.count - 4)
            return "\(digitsOnly[..<index])-\(digitsOnly[index...])"
        }
        
        return cleanPhone
    }
    
    // Helper to format website URLs
    private func formatWebsiteURL(_ website: String) -> URL {
        // If the website already has a scheme, use it
        if website.hasPrefix("http://") || website.hasPrefix("https://") {
            return URL(string: website) ?? URL(string: "https://\(website)")!
        }
        
        // Otherwise, add https:// as the default scheme
        return URL(string: "https://\(website)") ?? URL(string: "https://google.com")!
    }
    
    // Helper to clean website display (remove https://, etc.)
    private func cleanWebsiteDisplay(_ website: String) -> String {
        var cleaned = website
        if cleaned.hasPrefix("https://") {
            cleaned = String(cleaned.dropFirst(8))
        } else if cleaned.hasPrefix("http://") {
            cleaned = String(cleaned.dropFirst(7))
        }
        
        if cleaned.hasPrefix("www.") {
            cleaned = String(cleaned.dropFirst(4))
        }
        
        return cleaned
    }
} 