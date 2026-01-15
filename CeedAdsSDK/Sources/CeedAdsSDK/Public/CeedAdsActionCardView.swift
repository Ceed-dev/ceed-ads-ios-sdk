import SwiftUI

/// SwiftUI equivalent of Web SDK `renderActionCard(...)`.
/// - No API calls here (ad is already resolved).
/// - Triggers impression immediately after render (onAppear).
/// - On CTA tap: await trackClick first, then open URL.
/// - requestId nil => "unknown" (same as Web SDK).
public struct CeedAdsActionCardView: View {
    public let ad: ResolvedAd
    public let requestId: String?

    @Environment(\.openURL) private var openURL
    @State private var didTrackImpression = false
    @State private var isClickInFlight = false

    public init(ad: ResolvedAd, requestId: String?) {
        self.ad = ad
        self.requestId = requestId
    }

    public var body: some View {
        let rid = requestId ?? "unknown"

        VStack(alignment: .leading, spacing: 0) {
            // Header (Advertiser + Dot + "Ad" label)
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: 0x3A82F7))
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

            // Title
            Text(ad.title)
                .font(.system(size: 19, weight: .semibold))
                .lineSpacing(2)
                .padding(.bottom, 10)

            // Description
            Text(ad.description)
                .font(.system(size: 14))
                .opacity(0.8)
                .lineSpacing(3)
                .padding(.bottom, 18)

            // CTA Button
            Button {
                guard !isClickInFlight else { return }
                isClickInFlight = true

                Task {
                    defer { isClickInFlight = false }

                    // Match Web SDK: await trackClick, then open.
                    // If tracking fails, do NOT open (same behavior as an unhandled rejection).
                    do {
                        try await CeedAdsSDK.trackClick(ad: ad, requestId: rid)
                    } catch {
                        return
                    }

                    guard let url = URL(string: ad.ctaUrl) else { return }
                    openURL(url)
                }
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
        .padding(20)
        .frame(maxWidth: 460, alignment: .leading)
        .background(Color(hex: 0x141414))
        .foregroundColor(Color(hex: 0xE5E5E5))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 2)
        .padding(.vertical, 16)
        .onAppear {
            // Match Web SDK: trigger immediately after render.
            guard !didTrackImpression else { return }
            didTrackImpression = true

            Task {
                // Web SDK doesn't await; we also don't block UI here.
                try? await CeedAdsSDK.trackImpression(ad: ad, requestId: rid)
            }
        }
    }
}

// MARK: - Styles

private struct CeedAdsPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(hex: 0x2F6AD4) : Color(hex: 0x3A82F7))
            .cornerRadius(8)
    }
}

// MARK: - Color helper

private extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
