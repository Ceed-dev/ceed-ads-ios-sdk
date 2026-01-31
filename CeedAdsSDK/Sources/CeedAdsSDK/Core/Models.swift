import Foundation

// MARK: - Ad Models

/// A resolved advertisement returned from the backend API.
///
/// This structure contains all the information needed to display an ad,
/// including localized content and format-specific configuration.
///
/// ## Example
/// ```swift
/// let ad = try await CeedAdsSDK.requestAd(
///     conversationId: "conv-123",
///     messageId: "msg-456",
///     contextText: "Learning English vocabulary"
/// )
/// ```
public struct ResolvedAd: Codable, Equatable, Sendable {
    /// Unique identifier for this ad
    public let id: String

    /// Identifier of the advertiser who owns this ad
    public let advertiserId: String

    /// Display name of the advertiser
    public let advertiserName: String

    /// The visual format of this ad
    public let format: AdFormat

    /// Localized headline text
    public let title: String

    /// Localized body/description text
    public let description: String

    /// Call-to-action button label
    public let ctaText: String

    /// Destination URL when CTA is tapped
    public let ctaUrl: String

    // MARK: Format-Specific Configurations

    /// Configuration for lead generation ads (only present when `format == .leadGen`)
    public let leadGen: LeadGenConfig?

    /// Configuration for static display ads (only present when `format == .staticAd`)
    public let staticAd: StaticAdConfig?

    /// Configuration for followup cards (only present when `format == .followup`)
    public let followup: FollowupConfig?

    /// Creates a new resolved ad instance.
    /// - Parameters:
    ///   - id: Unique ad identifier
    ///   - advertiserId: Advertiser's unique identifier
    ///   - advertiserName: Display name of the advertiser
    ///   - format: Ad format type
    ///   - title: Headline text
    ///   - description: Body text
    ///   - ctaText: CTA button label
    ///   - ctaUrl: Destination URL
    ///   - leadGen: Lead gen configuration (optional)
    ///   - staticAd: Static ad configuration (optional)
    ///   - followup: Followup configuration (optional)
    public init(
        id: String,
        advertiserId: String,
        advertiserName: String,
        format: AdFormat,
        title: String,
        description: String,
        ctaText: String,
        ctaUrl: String,
        leadGen: LeadGenConfig? = nil,
        staticAd: StaticAdConfig? = nil,
        followup: FollowupConfig? = nil
    ) {
        self.id = id
        self.advertiserId = advertiserId
        self.advertiserName = advertiserName
        self.format = format
        self.title = title
        self.description = description
        self.ctaText = ctaText
        self.ctaUrl = ctaUrl
        self.leadGen = leadGen
        self.staticAd = staticAd
        self.followup = followup
    }
}

/// Supported ad format types.
///
/// Each format has a corresponding SwiftUI view component:
/// - `.actionCard` → `CeedAdsActionCardView`
/// - `.leadGen` → `CeedAdsLeadGenView`
/// - `.staticAd` → `CeedAdsStaticView`
/// - `.followup` → `CeedAdsFollowupView`
public enum AdFormat: String, Codable, Equatable, Sendable {
    /// Traditional card with title, description, and CTA button
    case actionCard = "action_card"

    /// Email capture form for lead generation
    case leadGen = "lead_gen"

    /// Banner-style display ad with optional image
    case staticAd = "static"

    /// Engagement card with selectable options
    case followup = "followup"
}

// MARK: - Format-Specific Configurations

/// Configuration for lead generation ads with email capture form.
///
/// Used when `ResolvedAd.format == .leadGen`.
public struct LeadGenConfig: Codable, Equatable, Sendable {
    /// Placeholder text for the email input field
    public let placeholder: String

    /// Message displayed after successful submission
    public let successMessage: String

    /// Optional URL to privacy policy (shown as link)
    public let privacyPolicyUrl: String?

    /// Creates a new lead gen configuration.
    /// - Parameters:
    ///   - placeholder: Email input placeholder text
    ///   - successMessage: Success message after submission
    ///   - privacyPolicyUrl: Optional privacy policy URL
    public init(
        placeholder: String,
        successMessage: String,
        privacyPolicyUrl: String? = nil
    ) {
        self.placeholder = placeholder
        self.successMessage = successMessage
        self.privacyPolicyUrl = privacyPolicyUrl
    }
}

/// Configuration for static display ads (banner-style).
///
/// Used when `ResolvedAd.format == .staticAd`.
public struct StaticAdConfig: Codable, Equatable, Sendable {
    /// URL of the banner image to display
    public let imageUrl: String?

    /// Optional duration to display the ad (in seconds)
    public let displayDuration: TimeInterval?

    /// Creates a new static ad configuration.
    /// - Parameters:
    ///   - imageUrl: Banner image URL
    ///   - displayDuration: Display duration in seconds
    public init(
        imageUrl: String? = nil,
        displayDuration: TimeInterval? = nil
    ) {
        self.imageUrl = imageUrl
        self.displayDuration = displayDuration
    }
}

/// Configuration for followup engagement cards with selectable options.
///
/// Used when `ResolvedAd.format == .followup`.
public struct FollowupConfig: Codable, Equatable, Sendable {
    /// Array of selectable options
    public let options: [FollowupOption]

    /// Creates a new followup configuration.
    /// - Parameter options: Array of selectable options
    public init(options: [FollowupOption]) {
        self.options = options
    }
}

/// A single selectable option in a followup card.
public struct FollowupOption: Codable, Equatable, Sendable {
    /// Unique identifier for this option
    public let id: String

    /// Display label shown to the user
    public let label: String

    /// Value sent to the backend when selected
    public let value: String

    /// Creates a new followup option.
    /// - Parameters:
    ///   - id: Unique option identifier
    ///   - label: Display label
    ///   - value: Backend value
    public init(id: String, label: String, value: String) {
        self.id = id
        self.label = label
        self.value = value
    }
}

// MARK: - API Payloads

/// Request payload sent to `POST /api/requests`.
///
/// Contains conversation context for ad matching.
public struct RequestPayload: Codable, Equatable, Sendable {
    /// Application identifier
    public let appId: String

    /// Unique conversation session identifier
    public let conversationId: String

    /// Unique message identifier
    public let messageId: String

    /// Conversation text used for contextual matching
    public let contextText: String

    /// Detected or specified language code
    public let language: String?

    /// Optional user identifier for personalization
    public let userId: String?

    /// SDK version for compatibility tracking
    public let sdkVersion: String

    /// Preferred ad formats to request (nil requests all formats)
    public let formats: [String]?
}

/// Event payload sent to `POST /api/events`.
///
/// Used for tracking impressions, clicks, and other interactions.
public struct EventPayload: Codable, Equatable, Sendable {
    /// Type of event being tracked
    public let type: EventType

    /// Ad identifier
    public let adId: String

    /// Advertiser identifier
    public let advertiserId: String

    /// Request identifier for attribution
    public let requestId: String

    /// Application identifier
    public let appId: String

    /// Conversation identifier (if available)
    public let conversationId: String?

    /// User identifier (if available)
    public let userId: String?

    // MARK: Extended Fields

    /// Submitted email address (for `.submit` events only)
    /// Note: Field name matches Web SDK for backend compatibility
    public let submittedEmail: String?

    /// Selected option ID (for `.optionTap` events only)
    public let optionId: String?

    /// Creates a new event payload.
    /// - Parameters:
    ///   - type: Event type
    ///   - adId: Ad identifier
    ///   - advertiserId: Advertiser identifier
    ///   - requestId: Request identifier
    ///   - appId: App identifier
    ///   - conversationId: Conversation identifier
    ///   - userId: User identifier
    ///   - submittedEmail: Email for submit events
    ///   - optionId: Option ID for optionTap events
    public init(
        type: EventType,
        adId: String,
        advertiserId: String,
        requestId: String,
        appId: String,
        conversationId: String?,
        userId: String?,
        submittedEmail: String? = nil,
        optionId: String? = nil
    ) {
        self.type = type
        self.adId = adId
        self.advertiserId = advertiserId
        self.requestId = requestId
        self.appId = appId
        self.conversationId = conversationId
        self.userId = userId
        self.submittedEmail = submittedEmail
        self.optionId = optionId
    }
}

/// Types of events that can be tracked.
public enum EventType: String, Codable, Equatable, Sendable {
    /// Ad became visible to the user
    case impression

    /// User tapped the CTA button
    case click

    /// User submitted email in lead_gen ad
    case submit

    /// User selected an option in followup ad
    case optionTap
}

// MARK: - Internal SDK Configuration

/// Internal SDK configuration (not exposed publicly).
struct SDKConfig: Sendable {
    /// Application ID (set during initialization)
    var appId: String?

    /// Base URL for API requests
    var apiBaseUrl: String

    /// Current SDK version
    var sdkVersion: String

    /// Whether the SDK has been initialized
    var initialized: Bool
}

// MARK: - Chat Message Types

/// A chat message from a user or AI assistant.
public struct ChatMessageUserAi: Codable, Equatable, Sendable {
    /// Unique message identifier
    public let id: String

    /// Message sender role
    public let role: ChatUserAiRole

    /// Message text content
    public let text: String
}

/// Role of a user/AI chat message sender.
public enum ChatUserAiRole: String, Codable, Equatable, Sendable {
    /// Message from the user
    case user

    /// Message from the AI assistant
    case ai
}

/// A chat message containing an advertisement.
public struct ChatMessageAd: Codable, Equatable, Sendable {
    /// Unique message identifier
    public let id: String

    /// Always `.ad`
    public let role: ChatAdRole

    /// The ad to display
    public let ad: ResolvedAd

    /// Request ID for tracking
    public let requestId: String?
}

/// Role for ad chat messages.
public enum ChatAdRole: String, Codable, Equatable, Sendable {
    /// Indicates this message is an advertisement
    case ad
}

/// A chat message that can be either user/AI content or an advertisement.
///
/// Automatically decodes based on the `role` field in JSON.
public enum ChatMessage: Codable, Equatable, Sendable {
    /// User or AI message
    case userAi(ChatMessageUserAi)

    /// Advertisement message
    case ad(ChatMessageAd)

    private enum CodingKeys: String, CodingKey {
        case role
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
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
