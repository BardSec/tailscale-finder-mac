import Foundation
import Security

enum TailscaleAPIError: Error, LocalizedError {
    case tailscaleNotRunning
    case decodingFailed(String)
    case untrustedBinary

    var errorDescription: String? {
        switch self {
        case .tailscaleNotRunning:
            return "Could not connect to Tailscale. Make sure the Tailscale app is installed and running."
        case .decodingFailed:
            return "Failed to parse Tailscale status. The response format may have changed."
        case .untrustedBinary:
            return "The Tailscale binary could not be verified. Please reinstall Tailscale from the official source."
        }
    }
}

struct TailscaleAPIClient {
    private static let cliPath = "/Applications/Tailscale.app/Contents/MacOS/Tailscale"

    static func fetchStatus() async throws -> TailscaleStatusResponse {
        // Try local API first (works with standalone Tailscale)
        if let result = try? await fetchViaLocalAPI() {
            return result
        }

        // Fall back to CLI (works with App Store Tailscale)
        return try await fetchViaCLI()
    }

    private static func fetchViaLocalAPI() async throws -> TailscaleStatusResponse {
        let url = URL(string: "http://127.0.0.1:41112/localapi/v1/status")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(TailscaleStatusResponse.self, from: data)
    }

    /// Verify the Tailscale binary has a valid Apple code signature
    private static func verifyCodeSignature(atPath path: String) -> Bool {
        let url = URL(fileURLWithPath: path) as CFURL
        var staticCode: SecStaticCode?

        guard SecStaticCodeCreateWithPath(url, [], &staticCode) == errSecSuccess,
              let code = staticCode else {
            return false
        }

        // Validate the signature is intact and signed by a valid identity
        return SecStaticCodeCheckValidity(code, [], nil) == errSecSuccess
    }

    private static func fetchViaCLI() async throws -> TailscaleStatusResponse {
        guard FileManager.default.fileExists(atPath: cliPath) else {
            throw TailscaleAPIError.tailscaleNotRunning
        }

        guard verifyCodeSignature(atPath: cliPath) else {
            throw TailscaleAPIError.untrustedBinary
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = ["status", "--json"]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw TailscaleAPIError.tailscaleNotRunning
        }

        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        do {
            return try JSONDecoder().decode(TailscaleStatusResponse.self, from: data)
        } catch {
            throw TailscaleAPIError.decodingFailed(error.localizedDescription)
        }
    }
}
