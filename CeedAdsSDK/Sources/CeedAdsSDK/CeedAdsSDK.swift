import Foundation

// MARK: - Ceed Ads iOS SDK — Public Entry Point
//
// Swift equivalent of Web SDK `/sdk/index.ts`.
//
// Public API:
//  - initialize(appId, apiBaseUrl?)
//      -> Sets up the SDK with your app ID and prepares internal state.
//
//  - requestAd(options)
//      -> Fetches an ad from the backend based on conversation context.
//         (Does NOT render anything.)
//
// Note:
// Web SDK also exposes `renderAd` and `showAd` which are DOM-specific.
// On iOS, the rendering equivalent will be provided as a SwiftUI component later.

public enum CeedAdsSDKError: Error, LocalizedError, Equatable {
    case appIdRequired

    public var errorDescription: String? {
        switch self {
        case .appIdRequired:
            return "CeedAdsSDK.initialize: appId is required"
        }
    }
}

// IMPORTANT:
// The SDK facade owns shared instances (APIClient/EventTracker).
// Shared instances are made concurrency-safe inside those classes,
// so the facade does NOT need @MainActor.
public enum CeedAdsSDK {

    // MARK: - Internal SDK-owned components (not public)
    private static let apiClient = APIClient()
    private static let eventTracker = EventTracker(apiClient: apiClient)

    // MARK: - 1) Public: initialize(appId, apiBaseUrl?)
    public static func initialize(appId: String, apiBaseUrl: String? = nil) throws {
        guard !appId.isEmpty else {
            throw CeedAdsSDKError.appIdRequired
        }

        // Initialize HTTP client configuration.
        apiClient.initClient(appId: appId, apiBaseUrl: apiBaseUrl)

        // Initialize event tracker (stores global identifiers).
        eventTracker.initTracker(appId: appId)

        print("[CeedAdsSDK] Initialized with appId=\(appId)")
    }

    // MARK: - 2) Public: requestAd(options)
    /// Requests a contextual ad based on conversation context.
    ///
    /// - Parameters:
    ///   - conversationId: Unique identifier for the conversation session
    ///   - messageId: Unique identifier for the current message
    ///   - contextText: The conversation text used for contextual matching
    ///   - userId: Optional user identifier for personalization
    ///   - formats: Optional array of preferred ad formats (nil requests all formats)
    /// - Returns: A tuple containing the matched ad (if any) and a request ID for tracking
    public static func requestAd(
        conversationId: String,
        messageId: String,
        contextText: String,
        userId: String? = nil,
        formats: [AdFormat]? = nil
    ) async throws -> (ad: ResolvedAd?, requestId: String?) {
        try await apiClient.requestAd(
            conversationId: conversationId,
            messageId: messageId,
            contextText: contextText,
            language: nil,
            userId: userId,
            formats: formats
        )
    }

    // MARK: - Internal tracking hooks (used by UI layer)
    //
    // These are internal (not public) on purpose.
    static func trackImpression(ad: ResolvedAd, requestId: String?) async throws {
        try await eventTracker.trackImpression(ad: ad, requestId: requestId)
    }

    static func trackClick(ad: ResolvedAd, requestId: String?) async throws {
        try await eventTracker.trackClick(ad: ad, requestId: requestId)
    }

    // MARK: - Extended tracking hooks for new ad formats

    /// Tracks email submission for lead_gen ads
    static func trackSubmit(ad: ResolvedAd, requestId: String?, email: String) async throws {
        try await eventTracker.trackSubmit(ad: ad, requestId: requestId, email: email)
    }

    /// Tracks option selection for followup ads
    static func trackOptionTap(ad: ResolvedAd, requestId: String?, optionId: String) async throws {
        try await eventTracker.trackOptionTap(ad: ad, requestId: requestId, optionId: optionId)
    }
}
