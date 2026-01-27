[English](README.md) | [日本語](README.ja.md)

# CeedAdsSDK

iOSアプリケーションにCeed Adsを統合するためのSwift SDKです。

## 動作要件

- iOS 15.0以上
- macOS 12.0以上
- Swift 5.9以上

## インストール

### Swift Package Manager

`Package.swift`の依存関係にパッケージを追加してください：

```swift
dependencies: [
    .package(url: "https://github.com/Ceed-dev/ceed-ads-ios-sdk.git", from: "1.0.0")
]
```

または、Xcodeで：
1. **File → Add Package Dependencies...** を選択
2. リポジトリURL `https://github.com/Ceed-dev/ceed-ads-ios-sdk` を入力
3. バージョンを選択してターゲットに追加

## 使い方

### 1. SDKの初期化

アプリ起動時にSDKを初期化します（App構造体またはAppDelegateなど）：

```swift
import CeedAdsSDK

// アプリIDで初期化
do {
    try CeedAdsSDK.initialize(appId: "your-app-id")
} catch {
    print("SDKの初期化に失敗しました: \(error)")
}
```

### 2. 広告のリクエスト

会話のコンテキストに基づいて広告をリクエストします：

```swift
do {
    let (ad, requestId) = try await CeedAdsSDK.requestAd(
        conversationId: "conversation-123",
        messageId: "message-456",
        contextText: "ユーザーが英語学習について質問しています"
    )

    if let ad = ad {
        // 広告を表示
    }
} catch {
    print("広告のリクエストに失敗しました: \(error)")
}
```

### 3. 広告の表示

組み込みのSwiftUIビューを使用して広告をレンダリングします：

```swift
import SwiftUI
import CeedAdsSDK

struct ChatView: View {
    var ad: ResolvedAd?
    var requestId: String?

    var body: some View {
        VStack {
            // チャットコンテンツ...

            if let ad = ad {
                CeedAdsActionCardView(ad: ad, requestId: requestId)
            }
        }
    }
}
```

`CeedAdsActionCardView`は以下を自動的に処理します：
- インプレッショントラッキング（広告が表示された時）
- クリックトラッキング（ユーザーがCTAをタップした時）
- リンク先URLを開く

## APIリファレンス

### CeedAdsSDK

| メソッド | 説明 |
|---------|------|
| `initialize(appId:apiBaseUrl:)` | アプリIDでSDKを初期化 |
| `requestAd(conversationId:messageId:contextText:userId:)` | コンテキストに基づいて広告をリクエスト |

### ResolvedAd

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `id` | String | 広告の一意識別子 |
| `advertiserId` | String | 広告主の識別子 |
| `advertiserName` | String | 広告主の表示名 |
| `format` | AdFormat | 広告フォーマット（例：`.actionCard`） |
| `title` | String | 広告タイトル |
| `description` | String | 広告の説明文 |
| `ctaText` | String | CTAボタンのテキスト |
| `ctaUrl` | String | リンク先URL |

### CeedAdsActionCardView

アクションカード広告をレンダリングするSwiftUIビューです。

```swift
CeedAdsActionCardView(ad: ResolvedAd, requestId: String?)
```

## サンプルアプリ

完全な動作例はサンプルアプリのリポジトリをご覧ください：

[CeedAdsIOSSample](https://github.com/Ceed-dev/CeedAdsIOSSample)

## ライセンス

MITライセンス - 詳細は[LICENSE](LICENSE)をご覧ください。
