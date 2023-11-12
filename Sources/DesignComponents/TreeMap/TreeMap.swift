//
//  Copyright © Marc Rollin.
//

import DesignSystem
import Platform
import SquarifyPartitioner
import SwiftUI

// MARK: - TreeMapDisplayable

public protocol TreeMapDisplayable: Partitionable, Identifiable {
    var name: String { get }
    var color: Color? { get }
    var shouldShowDetails: Bool { get }
    var segments: [Self] { get }
}

// MARK: - TreeMap

public struct TreeMap<Node: TreeMapDisplayable>: View {

    // MARK: Lifecycle

    public init(
        node: Node,
        hovering: Node? = nil,
        duplicates: Set<Node.ID>,
        onTap: ((Node) -> Void)? = nil,
        onHover: ((Node, Bool) -> Void)? = nil
    ) {
        self.node = node
        self.hovering = hovering
        self.duplicateIDs = duplicates
        self.onTap = onTap
        self.onHover = onHover
    }

    // MARK: Public

    public var body: some View {
        tree
            .padding(designSystem.spacing)
            .background(designSystem.color(.background))
    }

    // MARK: Private

    private let node: Node
    private let hovering: Node?
    private let duplicateIDs: Set<Node.ID>
    private let onTap: ((Node) -> Void)?
    private let onHover: ((Node, Bool) -> Void)?

    @Environment(DesignSystem.self) private var designSystem

    @ViewBuilder
    private var tree: some View {
        GeometryReader { geometry in
            drawTreemap(
                in: .init(
                    origin: .zero,
                    size: .init(width: geometry.size.width, height: geometry.size.height)
                ),
                node: node
            )
        }
    }

    private func drawTreemap(in rect: CGRect, node: Node) -> some View {
        let isDuplicate = duplicateIDs.contains(node.id)
        let background: Color = if isDuplicate {
            designSystem.color(.negative)
        } else {
            node.color ?? .clear
        }
        let foreground: Color = if isDuplicate {
            .white
        } else if node.shouldShowDetails {
            .primary
        } else {
            background
        }

        return drawTreemap(
            node: node,
            background: background,
            foreground: foreground,
            includeDetails: rect.size.canDisplayTitle
        )
        .border(hovering?.id == node.id ? designSystem.color(.highlight) : background)
        .padding(1)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?(node)
        }
        .onHover(perform: { hovering in
            onHover?(node, hovering)
        })
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.origin.x + rect.width / 2, y: rect.origin.y + rect.height / 2)
    }

    @ViewBuilder
    private func drawTreemap(node: Node, background: Color, foreground: Color, includeDetails: Bool) -> some View {
        if node.shouldShowDetails, includeDetails {
            detailedNode(node: node, background: background, foreground: foreground)
        } else {
            simpleNode(node: node, foreground: foreground, background: background, includeDetails: includeDetails)
        }
    }

    private func detailedNode(node: Node, background: Color, foreground: Color) -> some View {
        VStack(spacing: designSystem.spacing(.semiSmall)) {
            Text(node.name)
                .font(.headline)
                .foregroundColor(foreground)
                .lineLimit(1)
            GeometryReader { geometry in
                ZStack {
                    let partitions = partition(
                        node: node,
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    ForEach(partitions, id: \.segment.id) { partition in
                        AnyView(
                            drawTreemap(
                                in: partition.rect,
                                node: partition.segment
                            )
                        )
                    }
                }
                .background(designSystem.color(.backgroundSubdued))
            }
        }
        .padding(designSystem.spacing(.small))
        .background(background.opacity(designSystem.opacity(.medium)))
    }

    private func simpleNode(
        node: Node,
        foreground: Color,
        background: Color,
        includeDetails: Bool
    )
    -> some View {
        Rectangle()
            .fill(background.opacity(backgroundOpacity(node: node)))
            .overlay {
                if includeDetails {
                    Text(node.name)
                        .font(.subheadline)
                        .foregroundColor(foreground)
                        .padding(designSystem.spacing)
                        .clipped()
                }
            }
    }

    private func backgroundOpacity(node: Node) -> CGFloat {
        if duplicateIDs.contains(node.id) {
            designSystem.opacity(.dense)
        } else if node.shouldShowDetails {
            designSystem.opacity(.medium)
        } else {
            designSystem.opacity(.faint)
        }
    }

    private func partition(
        node: Node,
        width: CGFloat,
        height: CGFloat
    ) -> [Partition<Node>] {
        SquarifyPartitioner
            .partition(
                segments: node.segments,
                frame: .init(origin: .zero, size: .init(width: width, height: height))
            )
    }
}

extension CGSize {

    fileprivate var canDisplayTitle: Bool {
        (width >= 80 && height >= 50) || (height >= 80 && width >= 50)
    }
}
