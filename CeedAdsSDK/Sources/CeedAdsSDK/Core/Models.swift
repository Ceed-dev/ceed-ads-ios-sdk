import Foundation

// MARK: - 1) ResolvedAd (Returned from /api/requests)

public struct ResolvedAd: Codable, Equatable, Sendable {
    public let id: String
    public let advertiserId: String
    public let advertiserName: String
    public let format: AdFormat
    public let title: String
    public let description: String
    public let ctaText: String
    public let ctaUrl: String
}

public enum AdFormat: String, Codable, Equatable, Sendable {
    case actionCard = "action_card"
}

// MARK: - 2) Request Payload (SDK -> /api/requests)

public struct RequestPayload: Codable, Equatable, Sendable {
    public let appId: String
    public let conversationId: String
    public let messageId: String
    public let contextText: String
    public let language: String?
    public let userId: String?
    public let sdkVersion: String
}

// MARK: - 3) Event Payload (SDK -> /api/events)

public struct EventPayload: Codable, Equatable, Sendable {
    public let type: EventType
    public let adId: String
    public let advertiserId: String
    public let requestId: String
    public let appId: String
    public let conversationId: String?
    public let userId: String?
}

public enum EventType: String, Codable, Equatable, Sendable {
    case impression
    case click
}

// MARK: - 4) Internal SDK Config (NOT public)

struct SDKConfig: Sendable {
    var appId: String?          // TS: string | null
    var apiBaseUrl: String      // TS: string (e.g., "/api")
    var sdkVersion: String
    var initialized: Bool
}

// MARK: - 5) RenderedAd (Web-only)
// TS includes `RenderedAd` with `rootElement: HTMLElement`.
// iOS/Swift has no `HTMLElement`, so it’s intentionally omitted here.

// MARK: - 6) Chat Message Types (Used in SDK Test Scenarios)

public struct ChatMessageUserAi: Codable, Equatable, Sendable {
    public let id: String
    public let role: ChatUserAiRole
    public let text: String
}

public enum ChatUserAiRole: String, Codable, Equatable, Sendable {
    case user
    case ai
}

public struct ChatMessageAd: Codable, Equatable, Sendable {
    public let id: String
    public let role: ChatAdRole
    public let ad: ResolvedAd
    public let requestId: String?    // TS: string | null
}

public enum ChatAdRole: String, Codable, Equatable, Sendable {
    case ad
}

/// TS: `ChatMessage = ChatMessageUserAi | ChatMessageAd`
/// Swift representation that encodes/decodes based on the `"role"` field.
public enum ChatMessage: Codable, Equatable, Sendable {
    case userAi(ChatMessageUserAi)
    case ad(ChatMessageAd)

    private enum CodingKeys: String, CodingKey {
        case role
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode `role` as a raw string first, then choose the correct shape.
        let role = try container.decode(String.self, forKey: .role)

        switch role {
        case "user", "ai":
            let value = try ChatMessageUserAi(from: decoder)
            self = .userAi(value)

        case "ad":
            let value = try ChatMessageAd(from: decoder)
            self = .ad(value)

        default:
            throw DecodingError.dataCorruptedError(
                forKey: .role,
                in: container,
                debugDescription: "Unknown ChatMessage role: \(role)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .userAi(let value):
            try value.encode(to: encoder)
        case .ad(let value):
            try value.encode(to: encoder)
        }
    }
}
