//
//  Copyright © Marc Rollin.
//

import Foundation
import Platform
import Zip

// MARK: - ApplicationArchive

public struct ApplicationArchive {

    // MARK: Lifecycle

    public init(at url: URL, isCompressed: Bool = true) async throws {
        let archiveURL: URL

        if isCompressed {
            let uncompressed = FileManager.default
                .temporaryDirectory
                .appendingPathComponent(UUID().uuidString)

            Zip.addCustomFileExtension(url.pathExtension)
            try Zip.unzipFile(url, destination: uncompressed, overwrite: true, password: nil)
            archiveURL = uncompressed
        } else {
            archiveURL = url
        }

        root = try await Self.buildNode(from: archiveURL, name: url.lastPathComponent)
        root.computeSizes()
        buildIndex(from: root)
        markDuplicates()
    }

    // MARK: Public

    public final class Node {

        // MARK: Lifecycle

        public init(
            from url: URL,
            parent: Node?,
            name: String? = nil,
            resourceType: URLFileResourceType? = nil,
            contentType: ContentType? = nil
        ) {
            self.url = url
            self.parent = parent
            self.name = name ?? url.lastPathComponent
            self.resourceType = resourceType ?? (try? url.resourcesType)
            self.contentType = contentType ?? url.contentType
            if let fileSize = try? url.fileSize {
                sizeInBytes = fileSize
            }
        }

        // MARK: Public

        public typealias Checksum = String

        public let url: URL
        public let parent: Node?
        public let name: String
        public let resourceType: URLFileResourceType?
        public let contentType: ContentType?
        public var sizeInBytes = -1
        public var children: [Node] = []
        public var isDuplicate = false
        public var checksum: Checksum?
    }

    public struct Duplicate {
        public let nodes: [Node]

        public var sizeInBytes: Int {
            nodes.first?.sizeInBytes ?? -1
        }

        public var duplicateSizeInBytes: Int {
            sizeInBytes * (nodes.count - 1)
        }
    }

    public let root: Node

    public var allDuplicates: [Duplicate] {
        index.allDuplicates
    }

    public var topLevelDuplicates: [Duplicate] {
        var duplicates = [Node.Checksum: Duplicate]()
        topLevelDuplicates(from: root, duplicates: &duplicates)
        return Array(duplicates.values)
    }

    public var description: String {
        var description = ""
        describe(node: root, description: &description)
        return description
    }

    // MARK: Internal

    // MARK: - TreeError

    enum TreeError: Error {
        case fileDoesNotExist
    }

    // MARK: Private

    private final class Index {

        // MARK: Internal

        var allDuplicates: [Duplicate] {
            byChecksum.values
                .filter { $0.count > 1 }
                .map(Duplicate.init)
        }

        func duplicate(from node: Node) -> Duplicate? {
            guard let checksum = node.checksum,
                  let nodes = byChecksum[checksum],
                  nodes.count > 1
            else {
                return nil
            }

            return .init(nodes: nodes)
        }

        func insert(node: Node) {
            guard let checksum = node.checksum else { return }
            byChecksum[checksum] = (byChecksum[checksum] ?? []) + CollectionOfOne(node)
        }

        // MARK: Private

        private var byChecksum = [Node.Checksum: [Node]]()
    }

    private static let fileManager = FileManager.default

    private var index = Index()

    private static func buildNode(from url: URL, parent: Node? = nil, name: String? = nil) async throws -> Node {
        guard Self.fileManager.fileExists(atPath: url.path) else {
            throw TreeError.fileDoesNotExist
        }

        return try await .init(from: url, parent: parent, name: name)..{
            try await configure(node: $0)
        }
    }

    private static func configure(node: Node) async throws {
        switch node.resourceType {
        case .directory?: try await configureDirectory(node)
        case .regular?: try await configureFile(node)
        default: break
        }
    }

    private static func configureDirectory(_ node: Node) async throws {
        node.children = try await Self.fileManager.contentsOfDirectory(at: node.url, includingPropertiesForKeys: [])
            .compactMapAsync { try await buildNode(from:$0, parent: node) }

        let checksum: String = node.children
            .compactMap(\.checksum)
            .sorted()
            .joined()

        if checksum.isEmpty == false {
            node.checksum = checksum.sha256
        }
    }

    private static func configureFile(_ node: Node) async throws {
        switch node.contentType {
        case .package(.car):
            if let content = try? await node.assetCatalogContent(parent: node) {
                node.children = content
            }
        case .binary:
            if let content = try? await node.binaryContent(parent: node) {
                node.children = content
            }
        default:
            break
        }

        node.checksum = try Data(contentsOf: node.url).sha256
    }

    private func buildIndex(from node: Node) {
        index.insert(node: node)
        node.children.forEach(buildIndex(from:))
    }

    private func markDuplicates() {
        index.allDuplicates
            .flatMap(\.nodes)
            .forEach { $0.isDuplicate = true }
    }

    private func topLevelDuplicates(from node: Node, duplicates: inout [Node.Checksum: Duplicate]) {
        if let checksum = node.checksum, let duplicate = index.duplicate(from: node) {
            if duplicates[checksum] == nil {
                duplicates[checksum] = duplicate
            }
        } else {
            node.children.forEach {
                topLevelDuplicates(from: $0, duplicates: &duplicates)
            }
        }
    }

    private func describe(node: ApplicationArchive.Node, level: Int = 0, description: inout String) {
        let indentation = String(repeating: "   ", count: level)
        description.append("\(indentation)\(node)\n")

        for child in node.children {
            describe(node: child, level: level + 1, description: &description)
        }
    }
}

extension ApplicationArchive.Node {

    // MARK: Fileprivate

    @discardableResult
    fileprivate func computeSizes() -> Int {
        if children.isEmpty {
            return sizeInBytes
        }

        sizeInBytes = children
            .map { $0.computeSizes() }
            .reduce(0, +)

        return sizeInBytes
    }

    fileprivate func binaryContent(parent: ApplicationArchive.Node) async throws -> [ApplicationArchive.Node] {
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
                .compactMap { key, value -> (String, Int)? in
                    guard key != "hex", let intValue = Int(value) else {
                        return nil
                    }
                    return (key, intValue)
                }
        )

        guard let totalSize = sizeInfo.removeValue(forKey: "dec"), totalSize > 0 else {
            throw ContentError.unexpectedOutputFormat("Missing total size")
        }

        return sizeInfo.reduce(into: [ApplicationArchive.Node]()) { result, keyValue in
            let (key, value) = keyValue
            result.append(.init(
                from: url.appendingPathComponent(UUID().uuidString),
                parent: parent,
                name: key,
                contentType: .binarySection
            )..{
                $0.checksum = $0.url.relativePath.sha256
                $0.sizeInBytes = Int(Float(value) / Float(totalSize) * Float(sizeInBytes))
            })
        }
    }

    fileprivate func assetCatalogContent(parent: ApplicationArchive.Node) async throws -> [ApplicationArchive.Node] {
        var output = Data()

        for try await streamData in Terminal().streamCommand(
            "/usr/bin/xcrun",
            arguments: ["assetutil", "--info", url.relativePath]
        ) {
            output.append(streamData)
        }

        return try JSONDecoder().decode([AssetInfo].self, from: output)
            .compactMap { asset in
                guard let fileName = asset.renditionName ?? asset.name,
                      let size = asset.sizeOnDisk
                else { return nil }
                return .init(
                    from: url.appendingPathComponent(UUID().uuidString),
                    parent: parent,
                    name: fileName,
                    contentType: .asset
                )..{
                    $0.checksum = asset.sha1Digest
                    $0.sizeInBytes = size
                }
            }
    }

    // MARK: Private

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

    private enum ContentError: Error {
        case unexpectedOutputFormat(String)
    }
}
