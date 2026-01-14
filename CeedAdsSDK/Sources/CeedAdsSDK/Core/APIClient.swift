import Foundation

// MARK: - Ceed Ads iOS SDK — API Client
//
// Responsibilities:
//  - POST /api/requests  (fetch an ad)
//  - POST /api/events    (send impression/click)
//
// Pure networking only. No UI logic.

public enum CeedAdsError: Error, LocalizedError, Equatable {
    case notInitialized
    case invalidURL(String)
    case requestFailed(statusCode: Int, statusText: String)
    case decodingFailed

    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "CeedAds SDK not initialized"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .requestFailed(let statusCode, let statusText):
            return "Request failed: \(statusCode) \(statusText)"
        case .decodingFailed:
            return "Failed to decode response"
        }
    }
}

// MARK: - Internal response envelope (server -> SDK)
//
// Mirrors TS response:
// { ok: boolean; ad: ResolvedAd | null; requestId: string | null }
private struct RequestAdResponse: Codable {
    let ok: Bool
    let ad: ResolvedAd?
    let requestId: String?
}

// MARK: - APIClient
public final class APIClient: @unchecked Sendable {

    // MARK: - Thread Safety
    // Protects mutable SDK state (config).
    private let queue = DispatchQueue(label: "com.ceedads.sdk.apiclient")

    // Internal SDK State (Populated by initialize())
    private var config = SDKConfig(
        appId: nil,
        apiBaseUrl: "https://ceed-ads.vercel.app/api",
        sdkVersion: "1.0.0",
        initialized: false
    )

    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    public init(session: URLSession = .shared) {
        self.session = session
        self.jsonEncoder = JSONEncoder()
        self.jsonDecoder = JSONDecoder()
    }

    // MARK: - Public: initialize client config
    // Matches TS: initClient(appId, apiBaseUrl?)
    public func initClient(appId: String, apiBaseUrl: String? = nil) {
        queue.sync {
            self.config.appId = appId
            self.config.initialized = true

            // Allow override only when explicitly provided
            if let apiBaseUrl, !apiBaseUrl.isEmpty {
                self.config.apiBaseUrl = apiBaseUrl
            }
        }
    }

    // MARK: - Public: Request an Ad (POST /api/requests)
    public func requestAd(
        conversationId: String,
        messageId: String,
        contextText: String,
        language: String? = nil,
        userId: String? = nil
    ) async throws -> (ad: ResolvedAd?, requestId: String?) {

        // Snapshot config (no await while locked)
        let snapshot: (appId: String, apiBaseUrl: String, sdkVersion: String, initialized: Bool) = queue.sync {
            (
                self.config.appId ?? "",
                self.config.apiBaseUrl,
                self.config.sdkVersion,
                self.config.initialized
            )
        }

        guard snapshot.initialized, !snapshot.appId.isEmpty else {
            throw CeedAdsError.notInitialized
        }

        let mergedPayload = RequestPayload(
            appId: snapshot.appId,
            conversationId: conversationId,
            messageId: messageId,
            contextText: contextText,
            language: language,
            userId: userId,
            sdkVersion: snapshot.sdkVersion
        )

        let urlString = "\(snapshot.apiBaseUrl)/requests"
        let response: RequestAdResponse = try await postJSON(urlString: urlString, body: mergedPayload)

        return (ad: response.ad, requestId: response.requestId)
    }

    // MARK: - Public: Send impression/click events (POST /api/events)
    public func sendEvent(_ event: EventPayload) async throws {

        // Snapshot config
        let snapshot: (apiBaseUrl: String, initialized: Bool, hasAppId: Bool) = queue.sync {
            (self.config.apiBaseUrl, self.config.initialized, self.config.appId != nil)
        }

        guard snapshot.initialized, snapshot.hasAppId else {
            throw CeedAdsError.notInitialized
        }

        let urlString = "\(snapshot.apiBaseUrl)/events"
        _ = try await postJSON(urlString: urlString, body: event) as EmptyResponse
    }

    // MARK: - Internal Helper — POST Wrapper
    private func postJSON<T: Decodable, Body: Encodable>(urlString: String, body: Body) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw CeedAdsError.invalidURL(urlString)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try jsonEncoder.encode(body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw CeedAdsError.requestFailed(statusCode: -1, statusText: "No HTTP response")
        }

        guard (200...299).contains(http.statusCode) else {
            let statusText = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw CeedAdsError.requestFailed(statusCode: http.statusCode, statusText: statusText)
        }

        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw CeedAdsError.decodingFailed
        }
    }

    // For endpoints that return no JSON body we care about.
    private struct EmptyResponse: Decodable {}
}
