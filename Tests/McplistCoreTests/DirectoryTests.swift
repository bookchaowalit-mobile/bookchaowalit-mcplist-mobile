import XCTest
@testable import McplistCore

final class DirectoryTests: XCTestCase {
    private let filesystem = MCPServer(
        name: "filesystem", summary: "Read and write local files", categories: ["Files"],
        transport: .stdio(command: "npx", args: ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"], envKeys: []),
        official: true
    )
    private let github = MCPServer(
        name: "github", summary: "Issues and pull requests", categories: ["Dev", "Git"],
        transport: .stdio(command: "docker", args: ["run", "-i", "ghcr.io/github/github-mcp-server"], envKeys: ["GITHUB_PERSONAL_ACCESS_TOKEN"])
    )
    private let docs = MCPServer(
        name: "docs-search", summary: "Search product docs", categories: ["Dev"],
        transport: .http(url: URL(string: "https://mcp.example.com/mcp")!)
    )

    func testValidEntriesHaveNoProblems() {
        for s in [filesystem, github, docs] { XCTAssertEqual(Directory.problems(s), [], s.name) }
    }

    func testReportsProblems() {
        let bad = MCPServer(
            name: "My Server", summary: " ", categories: [],
            transport: .stdio(command: "", args: [], envKeys: ["api_key"])
        )
        XCTAssertEqual(Directory.problems(bad), [
            "name must be kebab-case", "summary is empty", "at least one category is required",
            "stdio command is empty", "env key api_key must be UPPER_SNAKE_CASE",
        ])
        let insecure = MCPServer(name: "x", summary: "x", categories: ["x"], transport: .http(url: URL(string: "http://mcp.example.com")!))
        XCTAssertEqual(Directory.problems(insecure), ["remote servers must use https (http only for localhost)"])
        let local = MCPServer(name: "x", summary: "x", categories: ["x"], transport: .http(url: URL(string: "http://localhost:3000/mcp")!))
        XCTAssertEqual(Directory.problems(local), [])
    }

    func testSearchAndCategories() {
        let all = [docs, github, filesystem]
        XCTAssertEqual(Directory.search(all).map(\.name), ["filesystem", "docs-search", "github"])
        XCTAssertEqual(Directory.search(all, category: "dev").map(\.name), ["docs-search", "github"])
        XCTAssertEqual(Directory.search(all, text: "PULL").map(\.name), ["github"])
        let counts = Directory.categoryCounts(all)
        XCTAssertEqual(counts.map { $0.category }, ["Dev", "Files", "Git"])
        XCTAssertEqual(counts.map { $0.count }, [2, 1, 1])
    }

    func testConfigSnippetUsesPlaceholdersNotSecrets() throws {
        let json = try Directory.configSnippet(for: [github, docs])
        let parsed = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let servers = try XCTUnwrap(parsed["mcpServers"] as? [String: Any])
        let gh = try XCTUnwrap(servers["github"] as? [String: Any])
        XCTAssertEqual(gh["command"] as? String, "docker")
        XCTAssertEqual(gh["env"] as? [String: String], ["GITHUB_PERSONAL_ACCESS_TOKEN": "<GITHUB_PERSONAL_ACCESS_TOKEN>"])
        let remote = try XCTUnwrap(servers["docs-search"] as? [String: String])
        XCTAssertEqual(remote, ["type": "http", "url": "https://mcp.example.com/mcp"])
    }
}
