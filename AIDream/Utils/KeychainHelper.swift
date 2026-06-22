import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary

        // First delete any existing item
        SecItemDelete(query)

        // Add the new item
        let status = SecItemAdd(query, nil)
        if status != errSecSuccess {
            print("Error saving to Keychain: \(status)")
        }
    }

    func read(service: String, account: String) -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true
        ] as CFDictionary

        var result: AnyObject?
        SecItemCopyMatching(query, &result)

        return result as? Data
    }

    func delete(service: String, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary

        SecItemDelete(query)
    }

    // Helper methods for common types
    func saveInt(_ value: Int, key: String) {
        let data = withUnsafeBytes(of: value) { Data($0) }
        save(data, service: "com.aidream.auth", account: key)
    }

    func readInt(key: String) -> Int? {
        guard let data = read(service: "com.aidream.auth", account: key) else { return nil }
        return data.withUnsafeBytes { $0.load(as: Int.self) }
    }

    func saveBool(_ value: Bool, key: String) {
        var val = value
        let data = Data(bytes: &val, count: MemoryLayout<Bool>.size)
        save(data, service: "com.aidream.auth", account: key)
    }

    func readBool(key: String) -> Bool? {
        guard let data = read(service: "com.aidream.auth", account: key) else { return nil }
        return data.withUnsafeBytes { $0.load(as: Bool.self) }
    }
}
