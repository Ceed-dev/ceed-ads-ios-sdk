import SwiftUI

// MARK: - Lead Generation Ad View

/// A SwiftUI view that displays a lead generation ad with email capture.
///
/// Lead gen ads include:
/// - Advertiser name with indicator
/// - Title and description
/// - Email input field with validation
/// - Submit button
/// - Optional privacy policy link
///
/// ## Automatic Tracking
/// - **Impression**: Tracked automatically when the view appears
/// - **Submit**: Tracked when email is successfully submitted
///
/// ## Example
/// ```swift
/// CeedAdsLeadGenView(ad: ad, requestId: requestId) { email in
///     print("User submitted: \(email)")
/// }
/// ```
public struct CeedAdsLeadGenView: View {

    // MARK: - Properties

    /// The resolved ad to display
    public let ad: ResolvedAd

    /// Request ID for event tracking (nil defaults to "unknown")
    public let requestId: String?

    /// Callback when email is successfully submitted
    public var onSubmit: ((String) -> Void)?

    // MARK: - Environment & State

    @Environment(\.openURL) private var openURL
    @State private var didTrackImpression = false
    @State private var email = ""
    @State private var isSubmitting = false
    @State private var isSubmitted = false
    @State private var showError = false

    // MARK: - Computed Properties

    /// Lead gen configuration with fallback defaults
    private var config: LeadGenConfig {
        ad.leadGen ?? LeadGenConfig(
            placeholder: "Enter your email",
            successMessage: "Thank you for subscribing!"
        )
    }

    // MARK: - Initialization

    /// Creates a new lead gen view.
    /// - Parameters:
    ///   - ad: The resolved ad to display
    ///   - requestId: Request ID for tracking (pass nil if unavailable)
    ///   - onSubmit: Optional callback when email is submitted
    public init(
        ad: ResolvedAd,
        requestId: String?,
        onSubmit: ((String) -> Void)? = nil
    ) {
        self.ad = ad
        self.requestId = requestId
        self.onSubmit = onSubmit
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

            // Form or Success State
            if isSubmitted {
                successSection
            } else {
                formSection(requestId: rid)
            }

            // Privacy Policy
            if let privacyUrl = config.privacyPolicyUrl {
                privacyLinkSection(url: privacyUrl)
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

    private var successSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color.ceedSuccess)
                .font(.system(size: 24))

            Text(config.successMessage)
                .font(.system(size: 15, weight: .medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color.ceedSecondaryBackground)
        .cornerRadius(8)
    }

    private func formSection(requestId: String) -> some View {
        VStack(spacing: 12) {
            // Email input
            emailInputField

            // Validation error
            if showError {
                validationErrorText
            }

            // Submit button
            submitButton(requestId: requestId)
        }
    }

    private var emailInputField: some View {
        TextField(config.placeholder, text: $email)
            .textFieldStyle(.plain)
            .font(.system(size: 15))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.ceedSecondaryBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(showError ? Color.red.opacity(0.5) : Color.ceedBorderSubtle, lineWidth: 1)
            )
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .disableAutocorrection(true)
    }

    private var validationErrorText: some View {
        Text("Please enter a valid email address")
            .font(.system(size: 12))
            .foregroundColor(Color.red.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func submitButton(requestId: String) -> some View {
        Button {
            handleSubmit(requestId: requestId)
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(ad.ctaText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(CeedAdsPrimaryButtonStyle())
        .disabled(isSubmitting || email.isEmpty)
        .opacity(email.isEmpty ? 0.6 : 1.0)
    }

    private func privacyLinkSection(url: String) -> some View {
        Button {
            if let privacyUrl = URL(string: url) {
                openURL(privacyUrl)
            }
        } label: {
            Text("Privacy Policy")
                .font(.system(size: 12))
                .foregroundColor(Color.ceedBlue)
                .underline()
        }
        .padding(.top, 12)
    }

    // MARK: - Actions

    private func trackImpressionIfNeeded(requestId: String) {
        guard !didTrackImpression else { return }
        didTrackImpression = true

        Task {
            try? await CeedAdsSDK.trackImpression(ad: ad, requestId: requestId)
        }
    }

    private func handleSubmit(requestId: String) {
        guard isValidEmail(email) else {
            showError = true
            return
        }

        showError = false
        isSubmitting = true

        Task {
            defer { isSubmitting = false }

            do {
                try await CeedAdsSDK.trackSubmit(ad: ad, requestId: requestId, email: email)
                isSubmitted = true
                onSubmit?(email)
            } catch {
                // Keep form visible on error
            }
        }
    }

    // MARK: - Validation

    /// Validates email format using regex.
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}
