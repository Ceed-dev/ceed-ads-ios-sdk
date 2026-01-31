# CeedAdsSDK - Project Context

This document provides background context for AI assistants and developers working on the Ceed Ads iOS SDK.

## Purpose and Positioning

CeedAdsSDK is the iOS implementation of the Ceed Ads platform, enabling contextual advertising within AI-powered chat applications. It serves as the mobile counterpart to the existing Web SDK.

**Target Use Case:**
- AI chatbot applications (language learning, productivity, assistants)
- Apps where ads should feel native to the conversation flow
- Monetization for free-tier AI chat services

**Business Context:**
- Ceed Ads is a contextual advertising platform specifically designed for AI chat interfaces
- Ads are matched based on conversation content, not user tracking
- The platform prioritizes user experience by showing relevant, non-intrusive ads

## Architecture Overview

The SDK follows a modular architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                      Host Application                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                    CeedAdsSDK                        │    │
│  │  (Public API - Static methods on enum)               │    │
│  │                                                      │    │
│  │  • initialize(appId:apiBaseUrl:)                     │    │
│  │  • requestAd(conversationId:messageId:contextText:)  │    │
│  │  • trackImpression(ad:requestId:) [internal]         │    │
│  │  • trackClick(ad:requestId:) [internal]              │    │
│  └──────────────────────┬───────────────────────────────┘    │
│                         │                                    │
│         ┌───────────────┴───────────────┐                    │
│         ▼                               ▼                    │
│  ┌─────────────────┐           ┌─────────────────┐          │
│  │   APIClient     │           │  EventTracker   │          │
│  │                 │           │                 │          │
│  │ • initClient()  │◀──────────│ • initTracker() │          │
│  │ • requestAd()   │           │ • trackImpres() │          │
│  │ • sendEvent()   │           │ • trackClick()  │          │
│  └─────────────────┘           └─────────────────┘          │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              CeedAdsActionCardView                   │    │
│  │              (SwiftUI Component)                     │    │
│  │                                                      │    │
│  │  • Renders action_card format                        │    │
│  │  • Auto-tracks impression on appear                  │    │
│  │  • Handles CTA click → track → open URL              │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │        Backend API            │
              │   (ceed-ads.vercel.app)       │
              │                               │
              │  POST /api/requests           │
              │  POST /api/events             │
              └───────────────────────────────┘
```

### Key Design Decisions

1. **Static API via Enum**: `CeedAdsSDK` is an enum (not a class) to prevent instantiation. All methods are static.

2. **Internal Tracking**: `trackImpression` and `trackClick` are `internal` (not `public`) because they should only be called by SDK-provided UI components, not by the host app.

3. **Thread Safety**: Both `APIClient` and `EventTracker` use `DispatchQueue` for thread-safe state management, marked as `@unchecked Sendable`.

4. **Impression Deduplication**: `EventTracker` maintains a `Set<String>` of sent impressions to prevent duplicate tracking for the same ad/requestId pair.

## Backend API Communication

### Endpoint: POST /api/requests

Requests a contextual ad based on conversation context.

**Request:**
```json
{
  "appId": "string",
  "conversationId": "string",
  "messageId": "string",
  "contextText": "string",
  "language": "string | null",
  "userId": "string | null",
  "sdkVersion": "string"
}
```

**Response:**
```json
{
  "ok": true,
  "ad": {
    "id": "string",
    "advertiserId": "string",
    "advertiserName": "string",
    "format": "action_card",
    "title": "string",
    "description": "string",
    "ctaText": "string",
    "ctaUrl": "string"
  },
  "requestId": "string"
}
```

**Backend Behavior:**
1. Detects language using `franc` library (supports `eng` and `jpn`)
2. Enforces 60-second cooldown per conversationId
3. Translates Japanese context to English for tag matching
4. Matches ads by keyword tags in the context
5. Returns localized ad content based on detected language

### Endpoint: POST /api/events

Sends impression and click events for analytics.

**Request:**
```json
{
  "type": "impression | click",
  "adId": "string",
  "advertiserId": "string",
  "requestId": "string",
  "appId": "string",
  "conversationId": "string | null",
  "userId": "string | null"
}
```

## Ad Formats

### Currently Supported

| Format | Description | UI Component |
|--------|-------------|--------------|
| `action_card` | Card with title, description, and CTA button | `CeedAdsActionCardView` |

### Planned Future Formats

| Format | Description | Status |
|--------|-------------|--------|
| `lead_gen` | Form-based lead generation ads | Planned |
| `static` | Simple static banner/image ads | Planned |
| `followup` | Follow-up engagement prompts | Planned |

When adding new formats:
1. Add case to `AdFormat` enum in `Models.swift`
2. Create corresponding SwiftUI view component
3. Implement format-specific tracking if needed
4. Update `CeedAdsActionCardView` or create a format dispatcher

## iOS-Specific Considerations

### SwiftUI First
- UI components are SwiftUI native (no UIKit wrappers)
- Uses `@Environment(\.openURL)` for URL handling
- Leverages SwiftUI lifecycle (`onAppear`) for impression tracking

### Concurrency
- Modern async/await API (Swift Concurrency)
- `@unchecked Sendable` on stateful classes with manual synchronization
- No `@MainActor` on facade to avoid blocking main thread

### No DOM Equivalent
- Web SDK has `renderAd()` and `showAd()` for DOM manipulation
- iOS SDK provides SwiftUI views instead
- Host app is responsible for placement in their view hierarchy

### Platform Support
- iOS 15.0+ (required for async/await and modern SwiftUI)
- macOS 12.0+ (for Catalyst/Mac apps)

### URL Handling
- Uses SwiftUI's `openURL` environment action
- Opens in system browser (Safari)
- Click tracking fires before URL open

## Test Application

**Repository:** [CeedAdsIOSSample](https://github.com/Ceed-dev/CeedAdsIOSSample)

The sample app demonstrates:
- SDK initialization in `App.init()`
- Ad requesting based on mock conversation
- Integration of `CeedAdsActionCardView` in a chat-like UI
- State management for loading/displaying ads

**Relationship:**
- Sample app imports this SDK as a Swift Package dependency
- Used for manual QA and integration testing
- Serves as reference implementation for developers

## Development Notes

### Adding New Features

When extending the SDK:

1. **New Ad Formats**: Add to `AdFormat` enum, create SwiftUI view, ensure tracking works
2. **New API Endpoints**: Add to `APIClient`, create request/response models in `Models.swift`
3. **New Public API**: Add to `CeedAdsSDK` enum as static method

### Testing Considerations

- Mock `URLSession` for unit testing `APIClient`
- Use SwiftUI previews for UI component development
- Test with different iOS versions (15.0 minimum)

### Version Compatibility

- SDK version is hardcoded in `APIClient.SDKConfig` (`sdkVersion: "1.0.0"`)
- Update when releasing new versions
- Backend uses this for analytics and compatibility checks

## Related Projects

| Project | Description | Repository |
|---------|-------------|------------|
| ceed-ads | Backend + Web SDK | Internal |
| ceed-ads-ios-sdk | This iOS SDK | This repo |
| CeedAdsIOSSample | iOS sample app | [GitHub](https://github.com/Ceed-dev/CeedAdsIOSSample) |
| Admin Dashboard | Ad management UI | Internal |

## Session History

### 2026-01-31
- Initial documentation created (README.md updated, CONTEXT.md created)
- Documented architecture, API communication, and future ad formats
