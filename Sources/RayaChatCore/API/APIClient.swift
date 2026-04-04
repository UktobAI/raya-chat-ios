import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// API client for bot config fetch and WebSocket URL construction.
final class APIClient: @unchecked Sendable {

    private let token: String
    private let locale: String
    private let endpoint = Constants.defaultEndpoint
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .useDefaultKeys
        return d
    }()

    init(token: String, locale: String = "en") {
        self.token = token
        self.locale = locale
    }

    /// Fetches bot configuration from the API. Returns defaults on failure.
    func fetchBotConfig() async -> BotConfigProps {
        let urlString = "https://\(endpoint)/v1/agents/chatbox-config/widget/"
        Log.i("API", "→ GET \(urlString)")

        guard let url = URL(string: urlString) else {
            Log.e("API", "Invalid bot config URL")
            return BotConfigProps()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            let body = String(data: data, encoding: .utf8) ?? "nil"
            Log.i("API", "← \(httpResponse?.statusCode ?? 0): \(body.prefix(500))")

            guard httpResponse?.statusCode == 200 else {
                Log.w("API", "Bot config fetch failed: \(httpResponse?.statusCode ?? 0)")
                return BotConfigProps()
            }

            return try decoder.decode(BotConfigProps.self, from: data)
        } catch {
            Log.e("API", "Bot config fetch error: \(error.localizedDescription)")
            return BotConfigProps()
        }
    }

    /// Constructs the WebSocket connection URL with all required query parameters.
    func constructWebSocketUrl(sessionId: String, userInfo: UserInfo) -> String {
        let metadata = getDeviceMetadata()
        let metadataJson: String
        if let data = try? JSONEncoder().encode(metadata), let json = String(data: data, encoding: .utf8) {
            metadataJson = json
        } else {
            metadataJson = "{}"
        }

        var components = URLComponents()
        components.scheme = "wss"
        components.host = endpoint
        components.path = "/v1/conversations/ws/start"
        components.queryItems = [
            URLQueryItem(name: "integration_type", value: Constants.integrationType),
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "agent_id", value: "null"),
            URLQueryItem(name: "chat_session_id", value: sessionId),
            URLQueryItem(name: "user_name", value: userInfo.fullName),
            URLQueryItem(name: "email", value: userInfo.email.lowercased()),
            URLQueryItem(name: "phone", value: userInfo.phone),
            URLQueryItem(name: "data", value: metadataJson),
        ]

        // URLComponents auto-encodes query items
        return components.url?.absoluteString ?? ""
    }

    private func getDeviceMetadata() -> DeviceMetadata {
        let osVersion: String
        #if canImport(UIKit)
        osVersion = UIDevice.current.systemVersion
        #else
        osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        #endif

        return DeviceMetadata(
            platform: "ios",
            osVersion: osVersion,
            deviceFamily: "iOS",
            sdkVersion: Constants.sdkVersion,
            locale: locale,
            timezone: TimeZone.current.identifier
        )
    }
}
