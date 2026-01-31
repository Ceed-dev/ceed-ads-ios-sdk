import SwiftUI

// MARK: - Followup Ad View

/// A SwiftUI view that displays a followup engagement card with selectable options.
///
/// Followup ads include:
/// - Advertiser name with indicator
/// - Title and description
/// - Multiple selectable option buttons
/// - Success feedback after selection
///
/// ## Automatic Tracking
/// - **Impression**: Tracked automatically when the view appears
/// - **Option Tap**: Tracked when an option is selected
///
/// ## Example
/// ```swift
/// CeedAdsFollowupView(ad: ad, requestId: requestId) { option in
///     print("User selected: \(option.label)")
/// }
/// ```
public struct CeedAdsFollowupView: View {

    // MARK: - Properties

    /// The resolved ad to display
    public let ad: ResolvedAd

    /// Request ID for event tracking (nil defaults to "unknown")
    public let requestId: String?

    /// Callback when an option is selected
    public var onOptionSelected: ((FollowupOption) -> Void)?

    // MARK: - Environment & State

    @Environment(\.openURL) private var openURL
    @State private var didTrackImpression = false
    @State private var selectedOptionId: String?
    @State private var isProcessing = false

    // MARK: - Computed Properties

    /// Followup configuration with fallback defaults
    private var config: FollowupConfig {
        ad.followup ?? FollowupConfig(options: [])
    }

    // MARK: - Initialization

    /// Creates a new followup view.
    /// - Parameters:
    ///   - ad: The resolved ad to display
    ///   - requestId: Request ID for tracking (pass nil if unavailable)
    ///   - onOptionSelected: Optional callback when an option is selected
    public init(
        ad: ResolvedAd,
        requestId: String?,
        onOptionSelected: ((FollowupOption) -> Void)? = nil
    ) {
        self.ad = ad
        self.requestId = requestId
        self.onOptionSelected = onOptionSelected
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

            // Options
            optionsSection(requestId: rid)

            // Success feedback
            if selectedOptionId != nil {
                feedbackSection
            }
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

    private func optionsSection(requestId: String) -> some View {
        VStack(spacing: 10) {
            ForEach(config.options, id: \.id) { option in
                optionButton(option: option, requestId: requestId)
            }
        }
    }

    private func optionButton(option: FollowupOption, requestId: String) -> some View {
        let isSelected = selectedOptionId == option.id

        return Button {
            handleOptionTap(option: option, requestId: requestId)
        } label: {
            HStack {
                Text(option.label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color.ceedText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? Color.ceedBlue : Color.ceedSecondaryBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color.clear : Color.ceedBorderSubtle,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(selectedOptionId != nil || isProcessing)
        .opacity(selectedOptionId != nil && !isSelected ? 0.5 : 1.0)
    }

    private var feedbackSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color.ceedSuccess)
                .font(.system(size: 16))

            Text("Thanks for your feedback!")
                .font(.system(size: 14))
                .opacity(0.8)
        }
        .padding(.top, 16)
    }

    // MARK: - Actions

    private func trackImpressionIfNeeded(requestId: String) {
        guard !didTrackImpression else { return }
        didTrackImpression = true

        Task {
            try? await CeedAdsSDK.trackImpression(ad: ad, requestId: requestId)
        }
    }

    private func handleOptionTap(option: FollowupOption, requestId: String) {
        guard selectedOptionId == nil, !isProcessing else { return }
        isProcessing = true

        Task {
            defer { isProcessing = false }

            do {
                try await CeedAdsSDK.trackOptionTap(ad: ad, requestId: requestId, optionId: option.id)
                selectedOptionId = option.id
                onOptionSelected?(option)

                // Open CTA URL after brief delay (if available)
                if !ad.ctaUrl.isEmpty, let url = URL(string: ad.ctaUrl) {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await MainActor.run {
                        openURL(url)
                    }
                }
            } catch {
                // Keep options selectable on error
            }
        }
    }
}
