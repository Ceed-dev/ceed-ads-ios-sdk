[English](README.md) | [日本語](README.ja.md)

# CeedAdsSDK

A Swift SDK for integrating Ceed Ads into iOS applications.

## Requirements

- iOS 15.0+
- macOS 12.0+
- Swift 5.9+

## Installation

### Swift Package Manager

Add the package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/Ceed-dev/ceed-ads-ios-sdk.git", from: "1.0.0")
]
```

Or in Xcode:
1. Go to **File → Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/Ceed-dev/ceed-ads-ios-sdk`
3. Select the version and add to your target

## Usage

### 1. Initialize the SDK

Initialize the SDK when your app starts (e.g., in your App struct or AppDelegate):

```swift
import CeedAdsSDK

// Initialize with your app ID
do {
    try CeedAdsSDK.initialize(appId: "your-app-id")
} catch {
    print("SDK initialization failed: \(error)")
}
```

### 2. Request an Ad

Request an ad based on conversation context:

```swift
do {
    let (ad, requestId) = try await CeedAdsSDK.requestAd(
        conversationId: "conversation-123",
        messageId: "message-456",
        contextText: "User is asking about learning English"
    )

    if let ad = ad {
        // Display the ad
    }
} catch {
    print("Failed to request ad: \(error)")
}
```

### 3. Display the Ad

Use the built-in SwiftUI view to render the ad:

```swift
import SwiftUI
import CeedAdsSDK

struct ChatView: View {
    var ad: ResolvedAd?
    var requestId: String?

    var body: some View {
        VStack {
            // Your chat content...

            if let ad = ad {
                CeedAdsActionCardView(ad: ad, requestId: requestId)
            }
        }
    }
}
```

The `CeedAdsActionCardView` automatically handles:
- Impression tracking (when the ad appears)
- Click tracking (when the user taps the CTA)
- Opening the destination URL

## API Reference

### CeedAdsSDK

| Method | Description |
|--------|-------------|
| `initialize(appId:apiBaseUrl:)` | Initialize the SDK with your app ID |
| `requestAd(conversationId:messageId:contextText:userId:)` | Request an ad based on context |

### ResolvedAd

| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Unique ad identifier |
| `advertiserId` | String | Advertiser identifier |
| `advertiserName` | String | Display name of the advertiser |
| `format` | AdFormat | Ad format (e.g., `.actionCard`) |
| `title` | String | Ad title |
| `description` | String | Ad description |
| `ctaText` | String | Call-to-action button text |
| `ctaUrl` | String | Destination URL |

### CeedAdsActionCardView

A SwiftUI view that renders an action card ad.

```swift
CeedAdsActionCardView(ad: ResolvedAd, requestId: String?)
```

## Sample App

See a complete working example in the sample app repository:

[CeedAdsIOSSample](https://github.com/Ceed-dev/CeedAdsIOSSample)

## License

MIT License - see [LICENSE](LICENSE) for details.
