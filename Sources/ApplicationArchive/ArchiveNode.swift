//
//  Copyright © Marc Rollin.
//

import Dependencies
import Foundation
import Platform

// MARK: - ArchiveNode

public struct ArchiveNode: Sendable, Identifiable, Equatable {

    // MARK: Lifecycle

    init(
        from url: URL,
        name: String,
        sizeInBytes: Int,
        checksum: Checksum? = nil,
        resourceType: URLFileResourceType? = nil,
        contentType: ContentType? = nil,
        metadata: ArchiveNodeMetadata? = nil,
        children: [ArchiveNode] = []
    ) {
        self.url = url
        self.name = name
        category = .init(contentType: contentType, resourceType: resourceType)
        self.sizeInBytes = sizeInBytes
        self.checksum = checksum
        self.metadata = metadata
        self.children = children
    }

    init(from url: URL) async throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ArchiveNodeError.fileDoesNotExist(url)
        }

        let resourceType = try url.resourcesType
        let contentType = url.contentType
        let children = try await Self.children(from: url, resourceType: resourceType, contentType: contentType)

        self = .init(
            from: url,
            name: url.lastPathComponent,
            sizeInBytes: try await Self.sizeInBytes(from: url, resourceType: resourceType, children: children),
            checksum: try await Self.checksum(from: url, resourceType: resourceType, children: children),
            resourceType: resourceType,
            contentType: contentType,
            metadata: try await Self.metadata(from: url, resourceType: resourceType, contentType: contentType),
            children: children
        )
    }

    // MARK: Public

    public typealias Checksum = String

    public let url: URL
    public let name: String
    public let sizeInBytes: Int
    public let checksum: Checksum?
    public let metadata: ArchiveNodeMetadata?
    public let children: [ArchiveNode]
    public let category: ArchiveNodeCategory

    public var id: URL {
        url
    }

    public var childrenBySize: [ArchiveNode] {
        children.sorted(by: \.sizeInBytes, order: .reverse)
    }

    public var childrenByCategory: [ArchiveNode] {
        childrenBySize.sorted(by: \.category)
    }

    public static func == (lhs: ArchiveNode, rhs: ArchiveNode) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: Internal

    func findApps() -> [ArchiveApp] {
        children
            .reduce(category == .app ? [ArchiveApp(self)].compactMap { $0 } : []) { result, child in
                result + child.findApps()
            }
    }

    func findDuplicates() -> [[ArchiveNode]] {
        identifyDuplicates().values.map(Array.init)
    }

    func findTopLevelDuplicates() -> [[ArchiveNode]] {
        let duplicates = identifyDuplicates()
        var results = [ArchiveNode.Checksum: [ArchiveNode]]()
        topLevelDuplicates(from: self, duplicates: duplicates, results: &results)
        return results.values.map(Array.init)
    }

    func buildParentIndex() -> [ID: ArchiveNode] {
        var index = [ID: ArchiveNode]()
        buildParentIndex(from: self, index: &index)
        return index
    }

    func identifyDuplicates() -> [Checksum: [ArchiveNode]] {
        var duplicates = [Checksum: [ArchiveNode]]()
        identifyDuplicates(from: self, duplicates: &duplicates)
        return duplicates.filter { $0.value.count > 1 }
    }

    // MARK: Private

    @Dependency(\.uuid) private static var uuid

    private static func children(
        from url: URL,
        resourceType: URLFileResourceType?,
        contentType: ContentType?
    ) async throws -> [ArchiveNode] {
        switch resourceType {
        case .directory?:
            return try await FileManager.default
                .contentsOfDirectory(at: url, includingPropertiesForKeys: [])
                .compactMapAsync { try await .init(from: $0) }
        case .regular?:
            switch contentType {
            #if os(macOS)
            case .binary:
                if let content = try? await binaryContent(from: url) {
                    return content
                }
            case .package(.car):
                if let content = try? await assetCatalogContent(from: url) {
                    return content
                }
            #endif
            default:
                break
            }
            break
        default:
            break
        }

        return []
    }

    private static func checksum(
        from url: URL,
        resourceType: URLFileResourceType?,
        children: [ArchiveNode]
    )
    async throws -> Checksum? {
        switch resourceType {
        case .directory?:
            let checksum: String = children
                .compactMap(\.checksum)
                .sorted()
                .joined()
            guard checksum.isEmpty == false else {
                break
            }
            return checksum.sha256
        case .regular?:
            return try Data(contentsOf: url).sha256
        default:
            break
        }

        return nil
    }

    private static func sizeInBytes(
        from url: URL,
        resourceType: URLFileResourceType?,
        children: [ArchiveNode]
    )
    async throws -> Int {
        switch resourceType {
        case .directory?:
            children
                .map(\.sizeInBytes)
                .reduce(0, +)
        case .regular?:
            try url.fileSize ?? 0
        default:
            0
        }
    }

    private static func metadata(
        from url: URL,
        resourceType: URLFileResourceType?,
        contentType: ContentType?
    )
    async throws -> ArchiveNodeMetadata? {
        switch resourceType {
        case .directory?:
            switch contentType {
            case .package(.app):
                return (try? url.infoPlist).map { .app($0) }
            case .package(.appex):
                return (try? url.infoPlist).map { .appex($0) }
            default:
                break
            }
        case .regular?:
            break
        default:
            break
        }

        return nil
    }

    #if os(macOS)
    private static func binaryContent(from url: URL) async throws -> [ArchiveNode] {
        let lines = try await Terminal().runCommand("/usr/bin/size", arguments: [url.relativePath])
            .split(separator: "\n")
            .map {
                $0.split(separator: "\t")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
            }

        guard lines.count >= 2 else {
            throw ContentError.unexpectedOutputFormat("Invalid number of lines")
        }

        var sizeInfo: [String: Int] = Dictionary(
            uniqueKeysWithValues: zip(lines[0], lines[1])
                .compactMap { key, factor -> (String, Int)? in
                    guard key != "hex", let intValue = Int(factor) else {
                        return nil
                    }
                    return (key, intValue)
                }
        )

        guard let totalSize = sizeInfo.removeValue(forKey: "dec"), totalSize > 0 else {
            throw ContentError.unexpectedOutputFormat("Missing total size")
        }

        let sizeInBytes = try url.fileSize ?? 0
        return sizeInfo.reduce(into: [ArchiveNode]()) { result, keyValue in
            let (key, factor) = keyValue
            let nodeURL = url.appendingPathComponent(Self.uuid().uuidString)
            result.append(.init(
                from: nodeURL,
                name: key,
                sizeInBytes: Int(Float(factor) / Float(totalSize) * Float(sizeInBytes)),
                checksum: nodeURL.relativePath.sha256,
                contentType: .binarySection
            ))
        }
    }

    private static func assetCatalogContent(from url: URL) async throws -> [ArchiveNode] {
        var output = Data()

        for try await streamData in Terminal().streamCommand(
            "/usr/bin/xcrun",
            arguments: ["assetutil", "--info", url.relativePath]
        ) {
            output.append(streamData)
        }

        return try JSONDecoder()
            .decode([AssetInfo].self, from: output)
            .compactMap { asset in
                let fileName = [asset.name, asset.renditionName]
                    .compactMap { $0 }
                    .joined(separator: " · ")
                guard !fileName.isEmpty,
                      let sizeInBytes = asset.sizeOnDisk
                else {
                    return nil
                }
                return .init(
                    from: url.appendingPathComponent(Self.uuid().uuidString),
                    name: fileName,
                    sizeInBytes: sizeInBytes,
                    checksum: asset.sha1Digest,
                    contentType: .asset
                )
            }
    }
    #endif

    private struct AssetInfo: Codable {
        let assetType: String?
        let name: String?
        let renditionName: String?
        let sizeOnDisk: Int?
        let sha1Digest: String?
        let preservedVectorRepresentation: Bool?

        enum CodingKeys: String, CodingKey {
            case assetType = "AssetType"
            case name = "Name"
            case renditionName = "RenditionName"
            case sizeOnDisk = "SizeOnDisk"
            case sha1Digest = "SHA1Digest"
            case preservedVectorRepresentation = "Preserved Vector Representation"
        }
    }

    private enum ContentError: LocalizedError {
        case unexpectedOutputFormat(String)
    }

    private func buildParentIndex(from node: ArchiveNode, parent: ArchiveNode? = nil, index: inout [ID: ArchiveNode]) {
        if let parent {
            index[node.id] = parent
        }

        for child in node.children {
            buildParentIndex(from: child, parent: node, index: &index)
        }
    }

    private func identifyDuplicates(from node: ArchiveNode, duplicates: inout [Checksum: [ArchiveNode]]) {
        if let checksum = node.checksum {
            duplicates[checksum] = (duplicates[checksum] ?? []) + CollectionOfOne(node)
        }

        for child in node.children {
            identifyDuplicates(from: child, duplicates: &duplicates)
        }
    }

    private func topLevelDuplicates(
        from node: ArchiveNode,
        duplicates: [ArchiveNode.Checksum: [ArchiveNode]],
        results: inout [ArchiveNode.Checksum: [ArchiveNode]]
    ) {
        if let checksum = node.checksum, let duplicates = duplicates[checksum], !results.isEmpty {
            if results[checksum] == nil {
                results[checksum] = duplicates
            }
        } else {
            for child in node.children {
                topLevelDuplicates(from: child, duplicates: duplicates, results: &results)
            }
        }
    }

}

// MARK: - ArchiveNodeError

private enum ArchiveNodeError: LocalizedError {
    case fileDoesNotExist(URL)

    var errorDescription: String? {
        switch self {
        case .fileDoesNotExist(let url):
            "Unable to access file at \(url.relativePath)."
        }
    }
}
