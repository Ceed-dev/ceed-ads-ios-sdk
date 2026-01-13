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
public final class APIClient {
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
        config.appId = appId
        config.initialized = true

        // Allow override only when explicitly provided
        if let apiBaseUrl, !apiBaseUrl.isEmpty {
            config.apiBaseUrl = apiBaseUrl
        }
    }

    // MARK: - Public: Request an Ad (POST /api/requests)
    //
    // TS takes: Omit<RequestPayload, "sdkVersion" | "appId">
    // Swift equivalent: pass the fields excluding appId/sdkVersion,
    // then we merge with config (same behavior as TS).
    public func requestAd(
        conversationId: String,
        messageId: String,
        contextText: String,
        language: String? = nil,
        userId: String? = nil
    ) async throws -> (ad: ResolvedAd?, requestId: String?) {
        guard config.initialized, let appId = config.appId else {
            throw CeedAdsError.notInitialized
        }

        let mergedPayload = RequestPayload(
            appId: appId,
            conversationId: conversationId,
            messageId: messageId,
            contextText: contextText,
            language: language,
            userId: userId,
            sdkVersion: config.sdkVersion
        )

        let urlString = "\(config.apiBaseUrl)/requests"
        let response: RequestAdResponse = try await postJSON(urlString: urlString, body: mergedPayload)

        // requestId is returned by the backend and used for event tracking.
        return (ad: response.ad, requestId: response.requestId)
    }

    // MARK: - Public: Send impression/click events (POST /api/events)
    public func sendEvent(_ event: EventPayload) async throws {
        guard config.initialized, config.appId != nil else {
            throw CeedAdsError.notInitialized
        }

        let urlString = "\(config.apiBaseUrl)/events"
        _ = try await postJSON(urlString: urlString, body: event) as EmptyResponse
        // No return value needed (matches TS)
    }

    // MARK: - Internal Helper — POST Wrapper
    // Executes a POST request with JSON payload.
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
