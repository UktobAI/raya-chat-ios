import Foundation
import Security

/// Keychain-based storage for session ID and user info.
/// Hardware-encrypted by Secure Enclave — unlike Android's EncryptedSharedPreferences, never fails.
final class KeychainStorage: @unchecked Sendable {

    private let service = Constants.keychainService

    // MARK: - Session ID

    func getSessionId() -> String {
        read(key: Constants.sessionIdKey) ?? ""
    }

    func setSessionId(_ id: String) {
        write(key: Constants.sessionIdKey, value: id)
    }

    // MARK: - User Info

    func getUserInfo() -> UserInfo? {
        guard let jsonString = read(key: Constants.userInfoKey),
              let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(UserInfo.self, from: data)
    }

    func setUserInfo(_ userInfo: UserInfo) {
        guard let data = try? JSONEncoder().encode(userInfo),
              let jsonString = String(data: data, encoding: .utf8) else { return }
        write(key: Constants.userInfoKey, value: jsonString)
    }

    // MARK: - Clear

    func clearAll() {
        delete(key: Constants.sessionIdKey)
        delete(key: Constants.userInfoKey)
    }

    // MARK: - Keychain Operations

    private func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func write(key: String, value: String) {
        guard let data = value.data(using: .utf8) else {
            Log.e("Keychain", "Failed to encode value to UTF8 for key '\(key)'")
            return
        }

        // Delete existing first (upsert pattern)
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            Log.e("Keychain", "Write failed for key '\(key)': OSStatus \(status)")
        }
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
