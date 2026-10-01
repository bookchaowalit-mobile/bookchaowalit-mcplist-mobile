import Foundation

public enum Transport: Equatable {
    /// Local process started by the client. `envKeys` lists required variables;
    /// values are never stored in the directory.
    case stdio(command: String, args: [String], envKeys: [String])
    /// Remote server reached over streamable HTTP.
    case http(url: URL)
}

public struct MCPServer: Identifiable, Equatable {
    public var id: String { name }
    public var name: String
    public var summary: String
    public var categories: Set<String>
    public var transport: Transport
    public var official: Bool

    public init(name: String, summary: String, categories: Set<String>, transport: Transport, official: Bool = false) {
        self.name = name
        self.summary = summary
        self.categories = categories
        self.transport = transport
        self.official = official
    }
}

public enum Directory {
    /// Data-quality problems for one entry; empty when valid.
    public static func problems(_ s: MCPServer) -> [String] {
        var out: [String] = []
        if s.name.range(of: "^[a-z0-9]+(-[a-z0-9]+)*$", options: .regularExpression) == nil {
            out.append("name must be kebab-case")
        }
        if s.summary.trimmingCharacters(in: .whitespaces).isEmpty { out.append("summary is empty") }
        if s.categories.isEmpty { out.append("at least one category is required") }
        switch s.transport {
        case let .stdio(command, _, envKeys):
            if command.trimmingCharacters(in: .whitespaces).isEmpty { out.append("stdio command is empty") }
            for key in envKeys where key.range(of: "^[A-Z][A-Z0-9_]*$", options: .regularExpression) == nil {
                out.append("env key \(key) must be UPPER_SNAKE_CASE")
            }
        case let .http(url):
            let scheme = url.scheme?.lowercased()
            let host = url.host?.lowercased() ?? ""
            let local = host == "localhost" || host == "127.0.0.1"
            if !(scheme == "https" || (scheme == "http" && local)) {
                out.append("remote servers must use https (http only for localhost)")
            }
        }
        return out
    }

    /// Filters by free text (name/summary) and category, official servers first, then by name.
    public static func search(_ servers: [MCPServer], text: String = "", category: String? = nil) -> [MCPServer] {
        let q = text.trimmingCharacters(in: .whitespaces).lowercased()
        return servers
            .filter { s in
                let textMatches = q.isEmpty || s.name.contains(q) || s.summary.lowercased().contains(q)
                guard let category else { return textMatches }
                let categoryMatches = s.categories.contains(where: { $0.caseInsensitiveCompare(category) == .orderedSame })
                return textMatches && categoryMatches
            }
            .sorted { a, b in a.official != b.official ? a.official : a.name < b.name }
    }

    /// Category → count, sorted by count then name.
    public static func categoryCounts(_ servers: [MCPServer]) -> [(category: String, count: Int)] {
        var counts: [String: Int] = [:]
        for s in servers { for c in s.categories { counts[c, default: 0] += 1 } }
        return counts.map { (category: $0.key, count: $0.value) }
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0.category < $1.category }
    }

    /// `mcpServers` JSON snippet for an MCP client config. Env values are
    /// placeholders the user must replace; no secrets are ever filled in.
    public static func configSnippet(for servers: [MCPServer]) throws -> String {
        var entries: [String: Any] = [:]
        for s in servers {
            switch s.transport {
            case let .stdio(command, args, envKeys):
                var e: [String: Any] = ["command": command, "args": args]
                if !envKeys.isEmpty {
                    e["env"] = Dictionary(envKeys.map { ($0, "<\($0)>") }, uniquingKeysWith: { first, _ in first })
                }
                entries[s.name] = e
            case let .http(url):
                entries[s.name] = ["type": "http", "url": url.absoluteString]
            }
        }
        let data = try JSONSerialization.data(
            withJSONObject: ["mcpServers": entries],
            options: [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        )
        return String(decoding: data, as: UTF8.self)
    }
}
