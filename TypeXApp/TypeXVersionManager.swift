import UIKit
import Combine
import Foundation

struct TypeXRelease: Identifiable, Codable {
    let id: Int
    let tagName: String
    let name: String
    let body: String
    let htmlURL: URL
    let publishedAt: Date?
    let prerelease: Bool

    var displayVersion: String {
        tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
    }
}

@MainActor
final class TypeXVersionManager: ObservableObject {
    @Published private(set) var releases: [TypeXRelease] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    let currentVersion: String
    private let releasesURL = URL(string: "https://api.github.com/repos/Lyte3075/TypeX/releases")!

    init() {
        currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var latestRelease: TypeXRelease? {
        releases.first
    }

    var hasUpdate: Bool {
        guard let latest = latestRelease else { return false }
        return compareVersions(latest.displayVersion, currentVersion) == .orderedDescending
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var request = URLRequest(url: releasesURL)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("TypeX-VersionManager", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let raw = try decoder.decode([GitHubRelease].self, from: data)
            releases = raw.map {
                TypeXRelease(
                    id: $0.id,
                    tagName: $0.tagName,
                    name: $0.name.isEmpty ? $0.tagName : $0.name,
                    body: $0.body ?? "",
                    htmlURL: $0.htmlURL,
                    publishedAt: $0.publishedAt,
                    prerelease: $0.prerelease
                )
            }
            .sorted { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }
        } catch {
            errorMessage = "Couldn't check GitHub right now. Check your connection and try again."
        }
    }

    func open(_ release: TypeXRelease) {
        #if os(iOS)
        UIApplication.shared.open(release.htmlURL)
        #endif
    }

    private func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = lhs.split(separator: ".").map { Int(String($0.filter { $0.isNumber })) ?? 0 }
        let right = rhs.split(separator: ".").map { Int(String($0.filter { $0.isNumber })) ?? 0 }
        for i in 0..<max(left.count, right.count) {
            let a = i < left.count ? left[i] : 0
            let b = i < right.count ? right[i] : 0
            if a != b { return a < b ? .orderedAscending : .orderedDescending }
        }
        return .orderedSame
    }
}

private struct GitHubRelease: Decodable {
    let id: Int
    let tagName: String
    let name: String
    let body: String?
    let htmlURL: URL
    let publishedAt: Date?
    let prerelease: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case tagName = "tag_name"
        case name
        case body
        case htmlURL = "html_url"
        case publishedAt = "published_at"
        case prerelease
    }
}
