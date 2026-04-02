import Foundation

enum TailscaleAPIError: Error, LocalizedError {
    case tailscaleNotFound
    case commandFailed(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .tailscaleNotFound:
            return "Tailscale CLI not found. Make sure Tailscale is installed."
        case .commandFailed(let msg):
            return "Tailscale command failed: \(msg)"
        case .decodingFailed(let msg):
            return "Failed to parse Tailscale status: \(msg)"
        }
    }
}

struct TailscaleAPIClient {
    private static let cliPaths = [
        "/usr/local/bin/tailscale",
        "/opt/homebrew/bin/tailscale",
        "/Applications/Tailscale.app/Contents/MacOS/Tailscale"
    ]

    static func fetchStatus() async throws -> TailscaleStatusResponse {
        // Try CLI first
        if let cliPath = cliPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) {
            return try await fetchViaCLI(path: cliPath)
        }

        // Fallback to local API
        return try await fetchViaLocalAPI()
    }

    private static func fetchViaCLI(path: String) async throws -> TailscaleStatusResponse {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["status", "--json"]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
            let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw TailscaleAPIError.commandFailed(errorString)
        }

        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        do {
            return try JSONDecoder().decode(TailscaleStatusResponse.self, from: data)
        } catch {
            throw TailscaleAPIError.decodingFailed(error.localizedDescription)
        }
    }

    private static func fetchViaLocalAPI() async throws -> TailscaleStatusResponse {
        let url = URL(string: "http://127.0.0.1:41112/localapi/v1/status")!
        let (data, _) = try await URLSession.shared.data(from: url)
        do {
            return try JSONDecoder().decode(TailscaleStatusResponse.self, from: data)
        } catch {
            throw TailscaleAPIError.decodingFailed(error.localizedDescription)
        }
    }
}
