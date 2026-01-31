import SwiftUI

// MARK: - Action Card Ad View

/// A SwiftUI view that displays an action card advertisement.
///
/// Action cards are the standard ad format, displaying:
/// - Advertiser name with indicator
/// - Title and description
/// - Call-to-action button
///
/// ## Automatic Tracking
/// - **Impression**: Tracked automatically when the view appears
/// - **Click**: Tracked when the CTA button is tapped
///
/// ## Example
/// ```swift
/// if let ad = ad {
///     CeedAdsActionCardView(ad: ad, requestId: requestId)
/// }
/// ```
///
/// ## Web SDK Equivalent
/// This is the iOS equivalent of the Web SDK's `renderActionCard(...)` function.
public struct CeedAdsActionCardView: View {

    // MARK: - Properties

    /// The resolved ad to display
    public let ad: ResolvedAd

    /// Request ID for event tracking (nil defaults to "unknown")
    public let requestId: String?

    // MARK: - Environment & State

    @Environment(\.openURL) private var openURL
    @State private var didTrackImpression = false
    @State private var isClickInFlight = false

    // MARK: - Initialization

    /// Creates a new action card view.
    /// - Parameters:
    ///   - ad: The resolved ad to display
    ///   - requestId: Request ID for tracking (pass nil if unavailable)
    public init(ad: ResolvedAd, requestId: String?) {
        self.ad = ad
        self.requestId = requestId
    }

    // MARK: - Body

    public var body: some View {
        let rid = requestId ?? "unknown"

        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection

            // Content
            titleSection
            descriptionSection

            // CTA
            ctaButton(requestId: rid)
        }
        .padding(20)
        .frame(maxWidth: 460, alignment: .leading)
        .background(Color.ceedBackground)
        .foregroundColor(Color.ceedText)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.ceedBorder, lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 2)
        .padding(.vertical, 16)
        .onAppear {
            trackImpressionIfNeeded(requestId: rid)
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.ceedBlue)
                    .frame(width: 10, height: 10)

                Text(ad.advertiserName)
                    .font(.system(size: 14))
                    .opacity(0.9)
            }

            Spacer()

            Text("Ad")
                .font(.system(size: 14))
                .opacity(0.55)
        }
        .padding(.bottom, 14)
    }

    private var titleSection: some View {
        Text(ad.title)
            .font(.system(size: 19, weight: .semibold))
            .lineSpacing(2)
            .padding(.bottom, 10)
    }

    private var descriptionSection: some View {
        Text(ad.description)
            .font(.system(size: 14))
            .opacity(0.8)
            .lineSpacing(3)
            .padding(.bottom, 18)
    }

    private func ctaButton(requestId: String) -> some View {
        Button {
            handleCtaTap(requestId: requestId)
        } label: {
            Text(ad.ctaText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
        }
        .buttonStyle(CeedAdsPrimaryButtonStyle())
        .padding(.top, 6)
        .disabled(isClickInFlight)
    }

    // MARK: - Actions

    private func trackImpressionIfNeeded(requestId: String) {
        guard !didTrackImpression else { return }
        didTrackImpression = true

        Task {
            try? await CeedAdsSDK.trackImpression(ad: ad, requestId: requestId)
        }
    }

    private func handleCtaTap(requestId: String) {
        guard !isClickInFlight else { return }
        isClickInFlight = true

        Task {
            defer { isClickInFlight = false }

            // Track click before opening URL
            do {
                try await CeedAdsSDK.trackClick(ad: ad, requestId: requestId)
            } catch {
                return
            }

            guard let url = URL(string: ad.ctaUrl) else { return }
            openURL(url)
        }
    }
}
