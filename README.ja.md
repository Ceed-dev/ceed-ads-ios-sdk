[English](README.md) | [日本語](README.ja.md)

# CeedAdsSDK

iOS AIチャットアプリケーションにコンテキスト広告を統合するためのSwift SDKです。CeedAdsSDKは、会話のコンテキストに基づいて関連性の高い広告をチャットインターフェース内に表示できます。

## 概要

CeedAdsSDKは、コンテキスト広告による収益化を目指すAIチャットアプリケーション向けに設計されています。SDKは会話のコンテキストを分析し、ユーザーの関心事や議論のトピックに合った関連性の高い広告を表示します。

**主な機能:**
- 会話内容に基づくコンテキスト広告ターゲティング
- **4つの広告フォーマット**: アクションカード、リードジェネレーション、スタティック、フォローアップ
- インプレッション、クリック、インタラクションの自動トラッキング
- シームレスな統合のためのネイティブSwiftUIコンポーネント
- モダンなSwift並行処理のためのasync/await API設計

## 広告フォーマット

CeedAdsSDKは、異なるエンゲージメント目標に向けた4つの広告フォーマットをサポートしています：

| フォーマット | 説明 | ユースケース |
|------------|------|------------|
| **アクションカード** | タイトル、説明、CTAボタンを持つ従来型カード | 一般的なプロモーション、アプリダウンロード |
| **リードジェネレーション** | プライバシーポリシーリンク付きのメール収集フォーム | ニュースレター登録、リード獲得 |
| **スタティック** | オプション画像付きのバナースタイル広告 | ブランド認知、ビジュアルキャンペーン |
| **フォローアップ** | 選択可能なオプションを持つエンゲージメントカード | アンケート、プリファレンス収集 |

各フォーマットには対応するSwiftUIビューコンポーネントがあります：
- `.actionCard` → `CeedAdsActionCardView`
- `.leadGen` → `CeedAdsLeadGenView`
- `.staticAd` → `CeedAdsStaticView`
- `.followup` → `CeedAdsFollowupView`

## 動作要件

| 要件 | バージョン |
|-----|----------|
| iOS | 15.0以上 |
| macOS | 12.0以上 |
| Swift | 5.9以上 |
| Xcode | 15.0以上 |

## インストール

### Swift Package Manager

`Package.swift`の依存関係にパッケージを追加してください：

```swift
dependencies: [
    .package(url: "https://github.com/Ceed-dev/ceed-ads-ios-sdk.git", from: "1.0.0")
]
```

次に、ターゲットの依存関係に`CeedAdsSDK`を追加します：

```swift
.target(
    name: "YourApp",
    dependencies: ["CeedAdsSDK"]
)
```

### Xcode統合

1. **File > Add Package Dependencies...** を選択
2. リポジトリURL `https://github.com/Ceed-dev/ceed-ads-ios-sdk` を入力
3. バージョンルールを選択（例：`1.0.0`から「次のメジャーバージョンまで」）
4. ターゲットに`CeedAdsSDK`を追加

## クイックスタート

### 1. SDKの初期化

アプリ起動時にSDKを初期化します。通常、`App`構造体または`AppDelegate`で行います：

```swift
import CeedAdsSDK

@main
struct MyApp: App {
    init() {
        do {
            try CeedAdsSDK.initialize(appId: "your-app-id")
        } catch {
            print("CeedAdsSDKの初期化に失敗しました: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. 広告のリクエスト

チャットフローの適切なタイミングで広告をリクエストします。SDKは会話のコンテキストを使用して関連する広告を見つけます：

```swift
func requestAdForMessage() async {
    do {
        let (ad, requestId) = try await CeedAdsSDK.requestAd(
            conversationId: "conversation-123",
            messageId: "message-456",
            contextText: "ユーザーが英語の語彙学習について質問しています"
        )

        if let ad = ad {
            // 広告とrequestIdを表示用に保存
            self.currentAd = ad
            self.currentRequestId = requestId
        }
    } catch {
        print("広告リクエストに失敗しました: \(error)")
    }
}
```

#### 特定のフォーマットをリクエストする

`formats`パラメータを使用して、受け取りたい広告フォーマットを指定できます：

```swift
// アクションカードとリードジェネレーションフォーマットのみをリクエスト
let (ad, requestId) = try await CeedAdsSDK.requestAd(
    conversationId: "conversation-123",
    messageId: "message-456",
    contextText: "ユーザーが英語の語彙学習について質問しています",
    formats: [.actionCard, .leadGen]
)

// すべてのフォーマットをリクエスト（デフォルトの動作）
let (ad, requestId) = try await CeedAdsSDK.requestAd(
    conversationId: "conversation-123",
    messageId: "message-456",
    contextText: "ユーザーが英語の語彙学習について質問しています"
)
```

### 3. 広告の表示

#### CeedAdsViewの使用（推奨）

`CeedAdsView`は広告のフォーマットに基づいて適切なビューを自動的に選択します：

```swift
import SwiftUI
import CeedAdsSDK

struct ChatView: View {
    @State private var ad: ResolvedAd?
    @State private var requestId: String?

    var body: some View {
        ScrollView {
            LazyVStack {
                // チャットメッセージ...

                if let ad = ad {
                    CeedAdsView(
                        ad: ad,
                        requestId: requestId,
                        onLeadGenSubmit: { email in
                            print("メールが送信されました: \(email)")
                        },
                        onFollowupOptionSelected: { option in
                            print("オプションが選択されました: \(option.label)")
                        }
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
}
```

#### フォーマット別ビューの使用

フォーマット別のビューを直接使用することもできます：

```swift
// アクションカード
CeedAdsActionCardView(ad: ad, requestId: requestId)

// リードジェネレーション（メールコールバック付き）
CeedAdsLeadGenView(ad: ad, requestId: requestId) { email in
    print("メールが送信されました: \(email)")
}

// スタティック広告
CeedAdsStaticView(ad: ad, requestId: requestId)

// フォローアップ（オプションコールバック付き）
CeedAdsFollowupView(ad: ad, requestId: requestId) { option in
    print("オプションが選択されました: \(option.label)")
}
```

#### 自動トラッキング

すべての広告ビューはイベントトラッキングを自動的に処理します：

| ビュー | トラッキングされるイベント |
|-------|------------------------|
| `CeedAdsActionCardView` | インプレッション（表示時）、クリック（CTAタップ時） |
| `CeedAdsLeadGenView` | インプレッション（表示時）、送信（メール送信時） |
| `CeedAdsStaticView` | インプレッション（表示時）、クリック（カードタップ時） |
| `CeedAdsFollowupView` | インプレッション（表示時）、オプションタップ（選択時） |

## APIリファレンス

### CeedAdsSDK

SDK操作のメインエントリポイントです。

| メソッド | 説明 |
|---------|------|
| `initialize(appId:apiBaseUrl:)` | アプリの認証情報でSDKを初期化 |
| `requestAd(conversationId:messageId:contextText:userId:formats:)` | 会話に基づいてコンテキスト広告をリクエスト |

#### initialize(appId:apiBaseUrl:)

```swift
public static func initialize(
    appId: String,
    apiBaseUrl: String? = nil
) throws
```

**パラメータ:**
- `appId`: アプリケーションの一意識別子（必須）
- `apiBaseUrl`: カスタムAPIエンドポイント（オプション、デフォルトは本番環境）

**スロー:** appIdが空の場合、`CeedAdsSDKError.appIdRequired`

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

**パラメータ:**
- `conversationId`: 会話セッションの一意識別子
- `messageId`: 現在のメッセージの一意識別子
- `contextText`: コンテキストマッチングに使用する会話テキスト
- `userId`: パーソナライズ用のオプションユーザー識別子
- `formats`: 優先する広告フォーマットのオプション配列（nilの場合はすべてのフォーマットをリクエスト）

**戻り値:** マッチした広告（存在する場合）とトラッキング用のリクエストIDを含むタプル

### ResolvedAd

成功したリクエストから返される広告モデルです。

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `id` | `String` | 広告の一意識別子 |
| `advertiserId` | `String` | 広告主の一意識別子 |
| `advertiserName` | `String` | 広告主の表示名 |
| `format` | `AdFormat` | 広告フォーマットタイプ（`.actionCard`、`.leadGen`、`.staticAd`、`.followup`） |
| `title` | `String` | ローカライズされた広告見出し |
| `description` | `String` | ローカライズされた広告本文 |
| `ctaText` | `String` | CTAボタンのラベル |
| `ctaUrl` | `String` | CTAのリンク先URL |
| `leadGen` | `LeadGenConfig?` | リードジェネレーション広告の設定（`format == .leadGen`の場合のみ） |
| `staticAd` | `StaticAdConfig?` | スタティック広告の設定（`format == .staticAd`の場合のみ） |
| `followup` | `FollowupConfig?` | フォローアップ広告の設定（`format == .followup`の場合のみ） |

### AdFormat

サポートされる広告フォーマットタイプです。

```swift
public enum AdFormat: String, Codable {
    case actionCard = "action_card"
    case leadGen = "lead_gen"
    case staticAd = "static"
    case followup = "followup"
}
```

### 広告ビューコンポーネント

#### CeedAdsView

適切な広告フォーマットを自動的にレンダリングする統合ビューです。

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

**パラメータ:**
- `ad`: 表示する広告
- `requestId`: イベントトラッキング用のリクエストID（利用不可の場合は`nil`）
- `onLeadGenSubmit`: メール送信時のオプションコールバック（リードジェネレーション広告）
- `onFollowupOptionSelected`: オプション選択時のオプションコールバック（フォローアップ広告）

#### CeedAdsActionCardView

CTAボタン付きのアクションカード広告をレンダリングします。

```swift
public struct CeedAdsActionCardView: View {
    public init(ad: ResolvedAd, requestId: String?)
}
```

#### CeedAdsLeadGenView

メール入力付きのリードジェネレーションフォームをレンダリングします。

```swift
public struct CeedAdsLeadGenView: View {
    public init(
        ad: ResolvedAd,
        requestId: String?,
        onSubmit: ((String) -> Void)? = nil
    )
}
```

**コールバック:**
- `onSubmit`: 送信されたメールアドレスとともに呼び出されます

#### CeedAdsStaticView

スタティック/バナースタイルの広告をレンダリングします。

```swift
public struct CeedAdsStaticView: View {
    public init(ad: ResolvedAd, requestId: String?)
}
```

#### CeedAdsFollowupView

選択可能なオプション付きのフォローアップカードをレンダリングします。

```swift
public struct CeedAdsFollowupView: View {
    public init(
        ad: ResolvedAd,
        requestId: String?,
        onOptionSelected: ((FollowupOption) -> Void)? = nil
    )
}
```

**コールバック:**
- `onOptionSelected`: 選択された`FollowupOption`とともに呼び出されます

### エラータイプ

#### CeedAdsSDKError

| ケース | 説明 |
|-------|------|
| `.appIdRequired` | appIdが空の状態でinitializeが呼び出された場合にスロー |

#### CeedAdsError

| ケース | 説明 |
|-------|------|
| `.notInitialized` | 初期化前にSDKメソッドが呼び出された |
| `.invalidURL(String)` | 不正なAPI URL |
| `.requestFailed(statusCode:statusText:)` | HTTPリクエストが失敗 |
| `.decodingFailed` | レスポンスのパースエラー |

## 高度な使用方法

### カスタムAPIエンドポイント

開発やテスト用に、カスタムAPIエンドポイントを指定できます：

```swift
try CeedAdsSDK.initialize(
    appId: "your-app-id",
    apiBaseUrl: "https://your-staging-server.com/api"
)
```

### ユーザートラッキング

ユーザーレベルの分析を有効にするためにユーザーIDを渡します：

```swift
let (ad, requestId) = try await CeedAdsSDK.requestAd(
    conversationId: conversationId,
    messageId: messageId,
    contextText: contextText,
    userId: "user-12345"
)
```

## サンプルアプリ

完全な動作実装については、サンプルアプリをご覧ください：

**[CeedAdsIOSSample](https://github.com/Ceed-dev/CeedAdsIOSSample)**

サンプルでは以下を実演しています：
- SDKの初期化
- チャットコンテキストでの広告リクエスト
- `CeedAdsActionCardView`での広告表示
- ローディングとエラー状態の処理

## トラブルシューティング

### よくある問題

**「CeedAds SDK not initialized」**
- 他のSDKメソッドを呼び出す前に`CeedAdsSDK.initialize()`が呼び出されていることを確認
- 初期化がアプリのライフサイクルの早い段階で行われていることを確認（例：`App.init()`内）

**広告が返されない**
- `appId`が有効でアクティブであることを確認
- `contextText`にマッチングのための意味のあるコンテンツが含まれていることを確認
- 会話のコンテキストが短すぎるか一般的すぎる場合、広告がマッチしないことがあります

**ネットワークエラー**
- インターネット接続を確認
- カスタム`apiBaseUrl`を使用している場合、到達可能であることを確認

## ライセンス

MITライセンス - 詳細は[LICENSE](LICENSE)をご覧ください。
