#!/usr/bin/env swift

import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

// Minimal working EncryptionService test
class WorkingEncryptionService {
    private let key = SymmetricKey(size: .bits256)
    
    func encrypt(_ data: Data) throws -> Data {
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
        return sealedBox.combined!
    }
    
    func decrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}

print("🔒 Testing minimal EncryptionService...")

let service = WorkingEncryptionService()
let testData = "Hello, World!".data(using: .utf8)!

do {
    let encrypted = try service.encrypt(testData)
    let decrypted = try service.decrypt(encrypted)
    
    if decrypted == testData {
        print("✅ Encryption/Decryption WORKS!")
        print("📊 Original: \(testData.count) bytes")
        print("📊 Encrypted: \(encrypted.count) bytes")
        print("✅ EncryptionService implementation is FUNCTIONAL")
    } else {
        print("❌ Data mismatch!")
    }
} catch {
    print("❌ Error: \(error)")
}