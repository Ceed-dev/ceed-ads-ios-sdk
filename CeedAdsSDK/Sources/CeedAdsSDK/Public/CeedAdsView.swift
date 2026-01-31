import SwiftUI

// MARK: - Unified Ad View

/// A unified SwiftUI view that automatically renders the appropriate ad format.
///
/// Use this view when you want automatic format detection and rendering
/// without needing to switch on the ad format yourself.
///
/// ## Supported Formats
/// - `.actionCard` → `CeedAdsActionCardView`
/// - `.leadGen` → `CeedAdsLeadGenView`
/// - `.staticAd` → `CeedAdsStaticView`
/// - `.followup` → `CeedAdsFollowupView`
///
/// ## Example
/// ```swift
/// if let ad = ad {
///     CeedAdsView(
///         ad: ad,
///         requestId: requestId,
///         onLeadGenSubmit: { email in
///             print("Email submitted: \(email)")
///         },
///         onFollowupOptionSelected: { option in
///             print("Option selected: \(option.label)")
///         }
///     )
/// }
/// ```
public struct CeedAdsView: View {

    // MARK: - Properties

    /// The resolved ad to display
    public let ad: ResolvedAd

    /// Request ID for event tracking (nil defaults to "unknown")
    public let requestId: String?

    // MARK: - Callbacks

    /// Callback for lead gen ads when email is submitted
    public var onLeadGenSubmit: ((String) -> Void)?

    /// Callback for followup ads when an option is selected
    public var onFollowupOptionSelected: ((FollowupOption) -> Void)?

    // MARK: - Initialization

    /// Creates a unified ad view with optional callbacks.
    /// - Parameters:
    ///   - ad: The resolved ad to display
    ///   - requestId: Request ID for tracking (pass nil if unavailable)
    ///   - onLeadGenSubmit: Optional callback for lead gen email submission
    ///   - onFollowupOptionSelected: Optional callback for followup option selection
    public init(
        ad: ResolvedAd,
        requestId: String?,
        onLeadGenSubmit: ((String) -> Void)? = nil,
        onFollowupOptionSelected: ((FollowupOption) -> Void)? = nil
    ) {
        self.ad = ad
        self.requestId = requestId
        self.onLeadGenSubmit = onLeadGenSubmit
        self.onFollowupOptionSelected = onFollowupOptionSelected
    }

    // MARK: - Body

    public var body: some View {
        switch ad.format {
        case .actionCard:
            CeedAdsActionCardView(ad: ad, requestId: requestId)

        case .leadGen:
            CeedAdsLeadGenView(
                ad: ad,
                requestId: requestId,
                onSubmit: onLeadGenSubmit
            )

        case .staticAd:
            CeedAdsStaticView(ad: ad, requestId: requestId)

        case .followup:
            CeedAdsFollowupView(
                ad: ad,
                requestId: requestId,
                onOptionSelected: onFollowupOptionSelected
            )
        }
    }
}

// MARK: - Convenience Initializers

public extension CeedAdsView {
    /// Creates a CeedAdsView without interaction callbacks.
    ///
    /// Use this initializer for simple ad display where you don't need
    /// to handle lead gen or followup interactions.
    init(ad: ResolvedAd, requestId: String?) {
        self.init(
            ad: ad,
            requestId: requestId,
            onLeadGenSubmit: nil,
            onFollowupOptionSelected: nil
        )
    }
}
