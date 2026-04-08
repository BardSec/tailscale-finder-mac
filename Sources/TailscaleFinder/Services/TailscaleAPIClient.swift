import Foundation

enum TailscaleAPIError: Error, LocalizedError {
    case tailscaleNotRunning
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .tailscaleNotRunning:
            return "Could not connect to Tailscale. Make sure the Tailscale app is installed and running."
        case .decodingFailed(let msg):
            return "Failed to parse Tailscale status: \(msg)"
        }
    }
}

struct TailscaleAPIClient {
    static func fetchStatus() async throws -> TailscaleStatusResponse {
        let url = URL(string: "http://127.0.0.1:41112/localapi/v1/status")!
        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(from: url)
        } catch {
            throw TailscaleAPIError.tailscaleNotRunning
        }
        do {
            return try JSONDecoder().decode(TailscaleStatusResponse.self, from: data)
        } catch {
            throw TailscaleAPIError.decodingFailed(error.localizedDescription)
        }
    }
}
