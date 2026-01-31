[English](README.md) | [日本語](README.ja.md)

# CeedAdsSDK

A Swift SDK for integrating contextual ads into iOS AI chat applications. CeedAdsSDK enables developers to display relevant ads based on conversation context within their chat interfaces.

## Overview

CeedAdsSDK is designed for AI-powered chat applications that want to monetize through contextual advertising. The SDK analyzes conversation context and displays relevant ads that match the user's current interests and discussion topics.

**Key Features:**
- Context-aware ad targeting based on conversation content
- **Four ad formats**: Action Card, Lead Gen, Static, and Followup
- Automatic impression, click, and interaction tracking
- Native SwiftUI components for seamless integration
- Async/await API design for modern Swift concurrency

## Ad Formats

CeedAdsSDK supports four distinct ad formats, each designed for different engagement goals:

| Format | Description | Use Case |
|--------|-------------|----------|
| **Action Card** | Traditional card with title, description, and CTA button | General promotion, app downloads |
| **Lead Gen** | Email capture form with privacy policy link | Newsletter signups, lead collection |
| **Static** | Banner-style ad with optional image | Brand awareness, visual campaigns |
| **Followup** | Engagement card with selectable options | Surveys, preference collection |

Each format has a corresponding SwiftUI view component:
- `.actionCard` → `CeedAdsActionCardView`
- `.leadGen` → `CeedAdsLeadGenView`
- `.staticAd` → `CeedAdsStaticView`
- `.followup` → `CeedAdsFollowupView`

## Requirements

| Requirement | Version |
|-------------|---------|
| iOS | 15.0+ |
| macOS | 12.0+ |
| Swift | 5.9+ |
| Xcode | 15.0+ |

## Installation

### Swift Package Manager

Add the package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/Ceed-dev/ceed-ads-ios-sdk.git", from: "1.0.0")
]
```

Then add `CeedAdsSDK` to your target's dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["CeedAdsSDK"]
)
```

### Xcode Integration

1. Go to **File > Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/Ceed-dev/ceed-ads-ios-sdk`
3. Select version rule (e.g., "Up to Next Major Version" from `1.0.0`)
4. Add `CeedAdsSDK` to your target

## Quick Start

### 1. Initialize the SDK

Initialize the SDK when your app launches. This is typically done in your `App` struct or `AppDelegate`:

```swift
import CeedAdsSDK

@main
struct MyApp: App {
    init() {
        do {
            try CeedAdsSDK.initialize(appId: "your-app-id")
        } catch {
            print("Failed to initialize CeedAdsSDK: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Request an Ad

Request an ad when appropriate in your chat flow. The SDK uses the conversation context to find relevant ads:

```swift
func requestAdForMessage() async {
    do {
        let (ad, requestId) = try await CeedAdsSDK.requestAd(
            conversationId: "conversation-123",
            messageId: "message-456",
            contextText: "User is asking about learning English vocabulary"
        )

        if let ad = ad {
            // Store ad and requestId for display
            self.currentAd = ad
            self.currentRequestId = requestId
        }
    } catch {
        print("Ad request failed: \(error)")
    }
}
```

#### Requesting Specific Formats

You can specify which ad formats you want to receive using the `formats` parameter:

```swift
// Request only action card and lead gen formats
let (ad, requestId) = try await CeedAdsSDK.requestAd(
    conversationId: "conversation-123",
    messageId: "message-456",
    contextText: "User is asking about learning English vocabulary",
    formats: [.actionCard, .leadGen]
)

// Request all formats (default behavior)
let (ad, requestId) = try await CeedAdsSDK.requestAd(
    conversationId: "conversation-123",
    messageId: "message-456",
    contextText: "User is asking about learning English vocabulary"
)
```

### 3. Display the Ad

#### Using CeedAdsView (Recommended)

`CeedAdsView` automatically selects the appropriate view based on the ad's format:

```swift
import SwiftUI
import CeedAdsSDK

struct ChatView: View {
    @State private var ad: ResolvedAd?
    @State private var requestId: String?

    var body: some View {
        ScrollView {
            LazyVStack {
                // Your chat messages...

                if let ad = ad {
                    CeedAdsView(
                        ad: ad,
                        requestId: requestId,
                        onLeadGenSubmit: { email in
                            print("Email submitted: \(email)")
                        },
                        onFollowupOptionSelected: { option in
                            print("Option selected: \(option.label)")
                        }
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
}
```

#### Using Format-Specific Views

You can also use format-specific views directly:

```swift
// Action Card
CeedAdsActionCardView(ad: ad, requestId: requestId)

// Lead Gen with email callback
CeedAdsLeadGenView(ad: ad, requestId: requestId) { email in
    print("Email submitted: \(email)")
}

// Static Ad
CeedAdsStaticView(ad: ad, requestId: requestId)

// Followup with option callback
CeedAdsFollowupView(ad: ad, requestId: requestId) { option in
    print("Option selected: \(option.label)")
}
```

#### Automatic Tracking

All ad views automatically handle event tracking:

| View | Events Tracked |
|------|----------------|
| `CeedAdsActionCardView` | Impression (on appear), Click (on CTA tap) |
| `CeedAdsLeadGenView` | Impression (on appear), Submit (on email submission) |
| `CeedAdsStaticView` | Impression (on appear), Click (on card tap) |
| `CeedAdsFollowupView` | Impression (on appear), Option Tap (on selection) |

## API Reference

### CeedAdsSDK

The main entry point for SDK operations.

| Method | Description |
|--------|-------------|
| `initialize(appId:apiBaseUrl:)` | Initialize the SDK with your app credentials |
| `requestAd(conversationId:messageId:contextText:userId:formats:)` | Request a contextual ad based on conversation |

#### initialize(appId:apiBaseUrl:)

```swift
public static func initialize(
    appId: String,
    apiBaseUrl: String? = nil
) throws
```

**Parameters:**
- `appId`: Your unique application identifier (required)
- `apiBaseUrl`: Custom API endpoint (optional, defaults to production)

**Throws:** `CeedAdsSDKError.appIdRequired` if appId is empty

#### requestAd(...)

```swift
public static func requestAd(
    conversationId: String,
    messageId: String,
    contextText: String,
    userId: String? = nil,
    formats: [AdFormat]? = nil
) async throws -> (ad: ResolvedAd?, requestId: String?)
```

**Parameters:**
- `conversationId`: Unique identifier for the conversation session
- `messageId`: Unique identifier for the current message
- `contextText`: The conversation text used for contextual matching
- `userId`: Optional user identifier for personalization
- `formats`: Optional array of preferred ad formats (nil requests all formats)

**Returns:** A tuple containing the matched ad (if any) and a request ID for tracking

### ResolvedAd

The ad model returned from a successful request.

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique ad identifier |
| `advertiserId` | `String` | Advertiser's unique identifier |
| `advertiserName` | `String` | Display name of the advertiser |
| `format` | `AdFormat` | Ad format type (`.actionCard`, `.leadGen`, `.staticAd`, `.followup`) |
| `title` | `String` | Localized ad headline |
| `description` | `String` | Localized ad body text |
| `ctaText` | `String` | Call-to-action button label |
| `ctaUrl` | `String` | Destination URL for the CTA |
| `leadGen` | `LeadGenConfig?` | Configuration for lead gen ads (only when `format == .leadGen`) |
| `staticAd` | `StaticAdConfig?` | Configuration for static ads (only when `format == .staticAd`) |
| `followup` | `FollowupConfig?` | Configuration for followup ads (only when `format == .followup`) |

### AdFormat

Supported ad format types.

```swift
public enum AdFormat: String, Codable {
    case actionCard = "action_card"
    case leadGen = "lead_gen"
    case staticAd = "static"
    case followup = "followup"
}
```

### Ad View Components

#### CeedAdsView

A unified view that automatically renders the appropriate ad format.

```swift
public struct CeedAdsView: View {
    public init(
        ad: ResolvedAd,
        requestId: String?,
        onLeadGenSubmit: ((String) -> Void)? = nil,
        onFollowupOptionSelected: ((FollowupOption) -> Void)? = nil
    )
}
```

**Parameters:**
- `ad`: The resolved ad to display
- `requestId`: The request ID for event tracking (pass `nil` if unavailable)
- `onLeadGenSubmit`: Optional callback when email is submitted (lead gen ads)
- `onFollowupOptionSelected`: Optional callback when an option is selected (followup ads)

#### CeedAdsActionCardView

Renders an action card advertisement with CTA button.

```swift
public struct CeedAdsActionCardView: View {
    public init(ad: ResolvedAd, requestId: String?)
}
```

#### CeedAdsLeadGenView

Renders a lead generation form with email input.

```swift
public struct CeedAdsLeadGenView: View {
    public init(
        ad: ResolvedAd,
        requestId: String?,
        onSubmit: ((String) -> Void)? = nil
    )
}
```

**Callback:**
- `onSubmit`: Called with the submitted email address

#### CeedAdsStaticView

Renders a static/banner-style advertisement.

```swift
public struct CeedAdsStaticView: View {
    public init(ad: ResolvedAd, requestId: String?)
}
```

#### CeedAdsFollowupView

Renders a followup card with selectable options.

```swift
public struct CeedAdsFollowupView: View {
    public init(
        ad: ResolvedAd,
        requestId: String?,
        onOptionSelected: ((FollowupOption) -> Void)? = nil
    )
}
```

**Callback:**
- `onOptionSelected`: Called with the selected `FollowupOption`

### Error Types

#### CeedAdsSDKError

| Case | Description |
|------|-------------|
| `.appIdRequired` | Thrown when initialize is called with empty appId |

#### CeedAdsError

| Case | Description |
|------|-------------|
| `.notInitialized` | SDK methods called before initialization |
| `.invalidURL(String)` | Malformed API URL |
| `.requestFailed(statusCode:statusText:)` | HTTP request failed |
| `.decodingFailed` | Response parsing error |

## Advanced Usage

### Custom API Endpoint

For development or testing, you can specify a custom API endpoint:

```swift
try CeedAdsSDK.initialize(
    appId: "your-app-id",
    apiBaseUrl: "https://your-staging-server.com/api"
)
```

### User Tracking

Pass a user ID to enable user-level analytics:

```swift
let (ad, requestId) = try await CeedAdsSDK.requestAd(
    conversationId: conversationId,
    messageId: messageId,
    contextText: contextText,
    userId: "user-12345"
)
```

## Sample App

For a complete working implementation, see the sample app:

**[CeedAdsIOSSample](https://github.com/Ceed-dev/CeedAdsIOSSample)**

The sample demonstrates:
- SDK initialization
- Ad requesting in a chat context
- Displaying ads with `CeedAdsActionCardView`
- Handling loading and error states

## Troubleshooting

### Common Issues

**"CeedAds SDK not initialized"**
- Ensure `CeedAdsSDK.initialize()` is called before any other SDK methods
- Verify initialization happens early in app lifecycle (e.g., in `App.init()`)

**No ads returned**
- Verify your `appId` is valid and active
- Check that `contextText` contains meaningful content for matching
- Ads may not match if conversation context is too short or generic

**Network errors**
- Verify internet connectivity
- Check if custom `apiBaseUrl` is reachable (if using one)

## License

MIT License - see [LICENSE](LICENSE) for details.
