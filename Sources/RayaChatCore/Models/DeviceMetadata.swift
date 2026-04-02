import Foundation

/// Device metadata sent in the WebSocket connection URL's `data` parameter.
public struct DeviceMetadata: Codable, Sendable {
    public let platform: String
    public let osVersion: String
    public let deviceFamily: String
    public let sdkVersion: String
    public let locale: String
    public let timezone: String

    enum CodingKeys: String, CodingKey {
        case platform
        case osVersion = "os_version"
        case deviceFamily = "device_family"
        case sdkVersion = "sdk_version"
        case locale, timezone
    }

    public init(
        platform: String = "ios",
        osVersion: String = "",
        deviceFamily: String = "iOS",
        sdkVersion: String = Constants.sdkVersion,
        locale: String = "en",
        timezone: String = ""
    ) {
        self.platform = platform
        self.osVersion = osVersion
        self.deviceFamily = deviceFamily
        self.sdkVersion = sdkVersion
        self.locale = locale
        self.timezone = timezone
    }
}
