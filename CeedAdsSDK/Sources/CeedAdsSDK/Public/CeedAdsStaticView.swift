import SwiftUI

// MARK: - Static Ad View

/// A SwiftUI view that displays a static/banner-style advertisement.
///
/// Static ads can include:
/// - Optional banner image
/// - Advertiser name with indicator
/// - Title and description
/// - Inline CTA link
///
/// The entire card is tappable and opens the destination URL.
///
/// ## Automatic Tracking
/// - **Impression**: Tracked automatically when the view appears
/// - **Click**: Tracked when the card is tapped
///
/// ## Example
/// ```swift
/// CeedAdsStaticView(ad: ad, requestId: requestId)
/// ```
public struct CeedAdsStaticView: View {

    // MARK: - Properties

    /// The resolved ad to display
    public let ad: ResolvedAd

    /// Request ID for event tracking (nil defaults to "unknown")
    public let requestId: String?

    // MARK: - Environment & State

    @Environment(\.openURL) private var openURL
    @State private var didTrackImpression = false
    @State private var isClickInFlight = false

    // MARK: - Computed Properties

    /// Static ad configuration with fallback defaults
    private var config: StaticAdConfig {
        ad.staticAd ?? StaticAdConfig()
    }

    // MARK: - Initialization

    /// Creates a new static ad view.
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

        Button {
            handleTap(requestId: rid)
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        .disabled(isClickInFlight)
        .padding(.vertical, 16)
        .onAppear {
            trackImpressionIfNeeded(requestId: rid)
        }
    }

    // MARK: - Subviews

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Banner image (if available)
            if let imageUrl = config.imageUrl, let url = URL(string: imageUrl) {
                imageSection(url: url)
            }

            // Text content
            textSection
        }
        .frame(maxWidth: 460, alignment: .leading)
        .background(Color.ceedBackground)
        .foregroundColor(Color.ceedText)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.ceedBorder, lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 2)
    }

    private func imageSection(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
            case .failure:
                imagePlaceholder
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
            @unknown default:
                imagePlaceholder
            }
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection
                .padding(.top, config.imageUrl != nil ? 16 : 0)

            // Title
            Text(ad.title)
                .font(.system(size: 17, weight: .semibold))
                .lineSpacing(2)
                .padding(.bottom, 8)
                .multilineTextAlignment(.leading)

            // Description
            Text(ad.description)
                .font(.system(size: 14))
                .opacity(0.8)
                .lineSpacing(3)
                .multilineTextAlignment(.leading)

            // CTA link
            ctaSection
        }
        .padding(16)
    }

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
        .padding(.bottom, 12)
    }

    private var ctaSection: some View {
        HStack {
            Text(ad.ctaText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.ceedBlue)

            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.ceedBlue)
        }
        .padding(.top, 14)
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color.ceedSecondaryBackground)
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 32))
                    .foregroundColor(Color.white.opacity(0.3))
            )
    }

    // MARK: - Actions

    private func trackImpressionIfNeeded(requestId: String) {
        guard !didTrackImpression else { return }
        didTrackImpression = true

        Task {
            try? await CeedAdsSDK.trackImpression(ad: ad, requestId: requestId)
        }
    }

    private func handleTap(requestId: String) {
        guard !isClickInFlight else { return }
        isClickInFlight = true

        Task {
            defer { isClickInFlight = false }

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
