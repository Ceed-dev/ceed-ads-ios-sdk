import Foundation

// MARK: - Ceed Ads iOS SDK — Event Tracker
//
// This module handles impression and click tracking.
// It does NOT perform any UI operations.
// Network requests are delegated to APIClient.
//
// Responsibilities:
//  - trackImpression(ad, requestId)
//  - trackClick(ad, requestId)
//
// Both functions construct an EventPayload and send it
// to the backend via APIClient.sendEvent().

final class EventTracker {

    // MARK: - Internal State
    //
    // These values are set once during initialization
    // and reused for every event payload.
    private var appId: String?
    private var conversationId: String?
    private var userId: String?

    private let apiClient: APIClient

    // MARK: - Impression Deduplication
    //
    // Prevents duplicate impression tracking for the same
    // ad + requestId pair.
    //
    // Note:
    // On the Web this is needed for React StrictMode.
    // On iOS it is still safe and spec-compatible to keep.
    private var sentImpressions = Set<String>()

    // MARK: - Init
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Initialize Tracker
    //
    // Called from SDK.initialize(...)
    // Sets global identifiers for event tracking.
    func initTracker(
        appId: String,
        conversationId: String? = nil,
        userId: String? = nil
    ) {
        self.appId = appId
        self.conversationId = conversationId
        self.userId = userId
    }

    // MARK: - Track Impression
    //
    // Sends an impression event when an ad becomes visible.
    // Ensures each ad/requestId pair only sends one impression.
    func trackImpression(
        ad: ResolvedAd,
        requestId: String?
    ) async throws {
        guard let appId else {
            throw CeedAdsError.notInitialized
        }

        if requestId == nil {
            // MVP limitation: keep behavior aligned with Web SDK
            print("trackImpression: requestId is nil (MVP limitation)")
        }

        // Unique key identifying this ad instance
        let key = "\(ad.id):\(requestId ?? "unknown")"

        // Prevent duplicate impressions
        if sentImpressions.contains(key) {
            return
        }

        sentImpressions.insert(key)

        let payload = EventPayload(
            type: .impression,
            adId: ad.id,
            advertiserId: ad.advertiserId,
            requestId: requestId ?? "unknown",
            appId: appId,
            conversationId: conversationId,
            userId: userId
        )

        try await apiClient.sendEvent(payload)
    }

    // MARK: - Track Click
    //
    // Sends a click event when the CTA is tapped.
    func trackClick(
        ad: ResolvedAd,
        requestId: String?
    ) async throws {
        guard let appId else {
            throw CeedAdsError.notInitialized
        }

        if requestId == nil {
            // MVP limitation: keep behavior aligned with Web SDK
            print("trackClick: requestId is nil (MVP limitation)")
        }

        let payload = EventPayload(
            type: .click,
            adId: ad.id,
            advertiserId: ad.advertiserId,
            requestId: requestId ?? "unknown",
            appId: appId,
            conversationId: conversationId,
            userId: userId
        )

        try await apiClient.sendEvent(payload)
    }
}
