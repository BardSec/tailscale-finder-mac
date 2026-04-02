import Foundation
#if canImport(Security)
import Security
#endif

class InsecureURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Accept self-signed certs for Tailscale internal services
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

struct TitleFetcher {
    private static let delegate = InsecureURLSessionDelegate()

    private static var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 4
        config.timeoutIntervalForResource = 6
        config.httpShouldFollowRedirects = true // Corrected: this is the default
        return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }()

    /// Fetch the HTML <title> from a URL
    static func fetchTitle(url: URL) async -> String? {
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...399).contains(httpResponse.statusCode) else {
                return nil
            }

            // Only parse HTML responses
            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? ""
            guard contentType.contains("text/html") || contentType.contains("application/xhtml") || contentType.isEmpty else {
                // Non-HTML service - return content type info
                return describeContentType(contentType)
            }

            // Parse title from first 16KB of HTML
            let limit = min(data.count, 16384)
            let subset = data.prefix(limit)
            guard let html = String(data: subset, encoding: .utf8)
                    ?? String(data: subset, encoding: .ascii) else {
                return nil
            }

            return extractTitle(from: html)
        } catch {
            return nil
        }
    }

    /// Extract <title>...</title> from HTML string
    private static func extractTitle(from html: String) -> String? {
        let lowered = html.lowercased()
        guard let startRange = lowered.range(of: "<title") else { return nil }

        // Find the closing > of the opening tag (handles <title lang="en">)
        let afterTag = lowered[startRange.upperBound...]
        guard let tagClose = afterTag.range(of: ">") else { return nil }

        let contentStart = tagClose.upperBound
        let remaining = lowered[contentStart...]
        guard let endRange = remaining.range(of: "</title>") else { return nil }

        // Use original HTML (not lowered) for the actual title text
        let originalStart = html.index(html.startIndex, offsetBy: lowered.distance(from: lowered.startIndex, to: contentStart))
        let originalEnd = html.index(html.startIndex, offsetBy: lowered.distance(from: lowered.startIndex, to: endRange.lowerBound))

        let title = String(html[originalStart..<originalEnd])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return title.isEmpty ? nil : decodeHTMLEntities(title)
    }

    private static func describeContentType(_ contentType: String) -> String {
        if contentType.contains("application/json") { return "JSON API" }
        if contentType.contains("application/xml") || contentType.contains("text/xml") { return "XML Service" }
        if contentType.contains("text/plain") { return "Plain Text" }
        if contentType.contains("image/") { return "Image Server" }
        return "Web Service"
    }

    private static func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let entities: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'"),
            ("&#x27;", "'"), ("&nbsp;", " "), ("&#8211;", "–"),
            ("&#8212;", "—"), ("&#8230;", "…")
        ]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        // Handle numeric entities like &#123;
        if let regex = try? NSRegularExpression(pattern: "&#(\\d+);") {
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, range: range).reversed()
            for match in matches {
                if let numRange = Range(match.range(at: 1), in: result),
                   let code = Int(result[numRange]),
                   let scalar = Unicode.Scalar(code) {
                    let charRange = Range(match.range, in: result)!
                    result.replaceSubrange(charRange, with: String(scalar))
                }
            }
        }
        return result
    }
}
