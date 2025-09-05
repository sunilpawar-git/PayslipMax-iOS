import Foundation

// MARK: - PayslipItem Encryption Methods

extension PayslipItem {
    /// Encrypts sensitive fields (name, account number, PAN) using the configured EncryptionService.
    ///
    /// Fetches the encryption service via `DIContainerResolver`, concatenates the sensitive fields
    /// into a single string separated by '|', encrypts the resulting data, and stores it in `sensitiveData`.
    /// Updates the corresponding `is...Encrypted` flags to true upon success.
    /// Throws an error if the encryption service cannot be resolved or if encryption fails.
    func encryptSensitiveData() async throws {
        // Get the encryption service through the actor-isolated container
        let container = try await DIContainerResolver.resolveAsync()
        guard let encryptionService = await container.resolveAsync(EncryptionServiceProtocol.self) else {
            return
        }
        
        let dataToEncrypt = "\(name)|\(accountNumber)|\(panNumber)".data(using: .utf8)
        if let data = dataToEncrypt {
            sensitiveData = try encryptionService.encrypt(data)
            isNameEncrypted = true
            isAccountNumberEncrypted = true
            isPanNumberEncrypted = true
        }
    }
    
    /// Decrypts sensitive fields stored in `sensitiveData` using the configured EncryptionService.
    ///
    /// Fetches the encryption service via `DIContainerResolver`, decrypts the `sensitiveData`,
    /// splits the resulting string by '|', and populates the `name`, `accountNumber`, and `panNumber` fields.
    /// Updates the corresponding `is...Encrypted` flags to false upon success.
    /// Throws an error if the encryption service cannot be resolved, if `sensitiveData` is nil,
    /// if decryption fails, or if the decrypted data format is incorrect.
    func decryptSensitiveData() async throws {
        // Get the encryption service through the actor-isolated container
        let container = try await DIContainerResolver.resolveAsync()
        guard let encryptionService = await container.resolveAsync(EncryptionServiceProtocol.self) else {
            return
        }
        
        guard let sensitiveData = self.sensitiveData else {
            throw NSError(domain: "PayslipEncryption", code: 1, userInfo: [NSLocalizedDescriptionKey: "No sensitive data to decrypt"])
        }
        
        let decryptedData = try encryptionService.decrypt(sensitiveData)
        if let decryptedString = String(data: decryptedData, encoding: .utf8) {
            let components = decryptedString.split(separator: "|")
            if components.count >= 3 {
                name = String(components[0])
                accountNumber = String(components[1])
                panNumber = String(components[2])
                
                isNameEncrypted = false
                isAccountNumberEncrypted = false
                isPanNumberEncrypted = false
            }
        }
    }
}
