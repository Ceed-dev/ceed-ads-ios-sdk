import SwiftUI

// MARK: - Button Styles

/// Primary button style used across all Ceed Ads ad formats.
///
/// Applies the Ceed Ads brand blue color with a pressed state variation.
///
/// ## Example
/// ```swift
/// Button("Submit") { ... }
///     .buttonStyle(CeedAdsPrimaryButtonStyle())
/// ```
public struct CeedAdsPrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.ceedBlueDark : Color.ceedBlue)
            .cornerRadius(8)
    }
}

// MARK: - Color Palette

/// Ceed Ads design system colors.
///
/// These colors follow the dark theme design guidelines:
/// - Background: #141414
/// - Text: #E5E5E5
/// - Primary: #3A82F7
/// - Borders: White at 12% opacity
public extension Color {

    // MARK: Brand Colors

    /// Primary brand blue (#3A82F7)
    static let ceedBlue = Color(hex: 0x3A82F7)

    /// Pressed/active state blue (#2F6AD4)
    static let ceedBlueDark = Color(hex: 0x2F6AD4)

    // MARK: Background Colors

    /// Primary card background (#141414)
    static let ceedBackground = Color(hex: 0x141414)

    /// Secondary/elevated background (#1C1C1E)
    static let ceedSecondaryBackground = Color(hex: 0x1C1C1E)

    // MARK: Text Colors

    /// Primary text color (#E5E5E5)
    static let ceedText = Color(hex: 0xE5E5E5)

    // MARK: Semantic Colors

    /// Success indicator green (#34C759)
    static let ceedSuccess = Color(hex: 0x34C759)

    // MARK: Border Colors

    /// Standard border (white at 12% opacity)
    static let ceedBorder = Color.white.opacity(0.12)

    /// Subtle border for input fields (white at 8% opacity)
    static let ceedBorderSubtle = Color.white.opacity(0.08)
}

// MARK: - Color Utilities

public extension Color {
    /// Creates a color from a hexadecimal value.
    ///
    /// ## Example
    /// ```swift
    /// let blue = Color(hex: 0x3A82F7)
    /// ```
    ///
    /// - Parameter hex: A 24-bit RGB color value (e.g., 0x3A82F7)
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - View Modifiers

/// A view modifier that applies standard Ceed Ads card styling.
///
/// This modifier applies:
/// - Padding (20pt)
/// - Max width (460pt)
/// - Dark background
/// - Light text color
/// - Rounded border
/// - Shadow
///
/// ## Example
/// ```swift
/// VStack {
///     // Card content
/// }
/// .modifier(CeedAdsCardModifier())
/// ```
public struct CeedAdsCardModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
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
    }
}

public extension View {
    /// Applies standard Ceed Ads card styling to this view.
    ///
    /// ## Example
    /// ```swift
    /// VStack {
    ///     Text("Ad Content")
    /// }
    /// .ceedAdsCardStyle()
    /// ```
    func ceedAdsCardStyle() -> some View {
        modifier(CeedAdsCardModifier())
    }
}

// MARK: - Reusable Components

/// A reusable header component for ad cards.
///
/// Displays the advertiser name with a blue indicator dot and an "Ad" label.
///
/// ## Example
/// ```swift
/// CeedAdsHeader(advertiserName: "Acme Corp")
/// ```
public struct CeedAdsHeader: View {
    /// The name of the advertiser to display
    public let advertiserName: String

    /// Creates a new ad header.
    /// - Parameter advertiserName: The advertiser's display name
    public init(advertiserName: String) {
        self.advertiserName = advertiserName
    }

    public var body: some View {
        HStack(alignment: .center) {
            // Advertiser indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.ceedBlue)
                    .frame(width: 10, height: 10)

                Text(advertiserName)
                    .font(.system(size: 14))
                    .opacity(0.9)
            }

            Spacer()

            // "Ad" disclosure label
            Text("Ad")
                .font(.system(size: 14))
                .opacity(0.55)
        }
        .padding(.bottom, 14)
    }
}
