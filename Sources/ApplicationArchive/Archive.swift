//
//  Copyright © Marc Rollin.
//

import Dependencies
import Foundation
import Platform
import Zip

public struct Archive: Sendable, Identifiable, Equatable {

    // MARK: Lifecycle

    public init(from url: URL, isCompressed: Bool = true) async throws {
        let archiveURL: URL

        if isCompressed {
            let uncompressed = FileManager.default
                .temporaryDirectory
                .appendingPathComponent(Self.uuid().uuidString)

            Zip.addCustomFileExtension(url.pathExtension)
            try Zip.unzipFile(url, destination: uncompressed, overwrite: true, password: nil)
            archiveURL = uncompressed
        } else {
            archiveURL = url
        }

        let root = try await ArchiveNode(from: archiveURL)

        self = .init(url: url, root: root)
    }

    private init(
        url: URL,
        root: ArchiveNode
    ) {
        self.url = url
        self.root = root
        apps = root.findApps()
        duplicates = root.findDuplicates()
        parents = root.buildParentIndex()
    }

    // MARK: Public

    public let url: URL
    public let root: ArchiveNode
    public let apps: [ArchiveApp]
    public let duplicates: [[ArchiveNode]]
    public let parents: [ArchiveNode.ID: ArchiveNode]

    public var id: URL {
        url
    }

    public var description: String {
        var description = ""
        describe(node: root, description: &description)
        return description
    }

    public var duplicateIDs: Set<ArchiveNode.ID> {
        Set(duplicates.flatMap { $0 }.map(\.id))
    }

    public func findTopLevelDuplicates() -> [[ArchiveNode]] {
        root.findTopLevelDuplicates()
    }

    public static func == (lhs: Archive, rhs: Archive) -> Bool {
        lhs.url == rhs.url
    }

    // MARK: Private

    @Dependency(\.uuid) private static var uuid

    private func describe(node: ArchiveNode, level: Int = 0, description: inout String) {
        let indentation = String(repeating: "   ", count: level)
        description.append("\(indentation)\(node)\n")

        for child in node.children {
            describe(node: child, level: level + 1, description: &description)
        }
    }
}
