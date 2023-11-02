//
//  Copyright © Marc Rollin.
//

import CoreGraphics
import Foundation
import Platform

// MARK: - Partitionable

public protocol Partitionable {
    var size: CGFloat { get }
}

// MARK: - Partition

public struct Partition<Segment: Partitionable> {
    public let rect: CGRect
    public let normalizedSize: CGFloat
    public let segment: Segment
}

// MARK: - SquarifyPartitioner

/// Squarify algorithm implementation loosely based on [Squarified Treemaps](https://www.win.tue.nl/~vanwijk/stm.pdf)
public enum SquarifyPartitioner {

    // MARK: Public

    public static func partition<Segment: Partitionable>(segments: [Segment], frame: CGRect) -> [Partition<Segment>] {
        let totalSize = segments.map(\.size).reduce(0, +)

        guard segments.count > 1 else {
            guard let singleSegment = segments.first else {
                return []
            }
            return [Partition(rect: frame, normalizedSize: 1, segment: singleSegment)]
        }

        var frame = frame
        var partitions: [Partition<Segment>] = []
        var normalizedSegments: [NormalizedSegment<Segment>] = segments
            .filter { $0.size > 0 }
            .map { .init(normalizedSize: ($0.size * frame.size.height * frame.size.width) / totalSize, segment: $0) }

        squarify(
            normalizedSegments: &normalizedSegments,
            width: biggestFittingSquare(for: frame.size).side,
            partitions: &partitions,
            frame: &frame
        )

        return partitions
    }

    // MARK: Private

    private struct SquareFit {
        enum Orientation {
            case vertical, horizontal
        }

        let orientation: Orientation
        let side: CGFloat
    }

    private struct NormalizedSegment<Segment: Partitionable> {
        let normalizedSize: CGFloat
        let segment: Segment
    }

    private static func worstRatio(row: [NormalizedSegment<some Partitionable>], width: CGFloat) -> CGFloat {
        let rowScaledSizes = row.map(\.normalizedSize)
        let sum = rowScaledSizes.reduce(0, +)

        guard let rowMax = rowScaledSizes.max(),
              let rowMin = rowScaledSizes.min(),
              sum != 0, width != 0
        else {
            return 0
        }

        let squareSum = pow(sum, 2)
        let squareWidth = pow(width, 2)

        return max(
            (squareWidth * rowMax) / squareSum,
            squareSum / (squareWidth * rowMin)
        )
    }

    private static func biggestFittingSquare(for size: CGSize) -> SquareFit {
        pow(size.height, 2) <= pow(size.width, 2)
            ? .init(orientation: .vertical, side: size.height)
            : .init(orientation: .horizontal, side: size.width)
    }

    private static func layoutRow<Segment: Partitionable>(
        row: [NormalizedSegment<Segment>],
        width: CGFloat,
        orientation: SquareFit.Orientation,
        partitions: inout [Partition<Segment>],
        frame: inout CGRect
    ) {
        guard width > 0 else { return }

        let rowHeight = row.map(\.normalizedSize).reduce(0, +) / width

        guard rowHeight > 0 else { return }

        for normalizedSegment in row {
            let rowWidth = normalizedSegment.normalizedSize / rowHeight

            var newFrame: CGRect
            switch orientation {
            case .vertical:
                newFrame = CGRect(x: frame.origin.x, y: frame.origin.y, width: rowHeight, height: rowWidth)
                frame.origin.y += rowWidth
            case .horizontal:
                newFrame = CGRect(x: frame.origin.x, y: frame.origin.y, width: rowWidth, height: rowHeight)
                frame.origin.x += rowWidth
            }

            partitions.append(.init(rect: newFrame, normalizedSize: normalizedSegment.normalizedSize, segment: normalizedSegment.segment))
        }

        switch orientation {
        case .vertical:
            frame.origin.x += rowHeight
            frame.origin.y -= width
            frame.size.width -= rowHeight
        case .horizontal:
            frame.origin.x -= width
            frame.origin.y += rowHeight
            frame.size.height -= rowHeight
        }
    }

    private static func squarify<Segment: Partitionable>(
        normalizedSegments: inout [NormalizedSegment<Segment>],
        row: [NormalizedSegment<Segment>] = [],
        width: CGFloat,
        partitions: inout [Partition<Segment>],
        frame: inout CGRect
    ) {
        guard normalizedSegments.count != 1 else {
            let maxSquareFit = biggestFittingSquare(for: frame.size)
            layoutRow(
                row: row,
                width: width,
                orientation: maxSquareFit.orientation,
                partitions: &partitions,
                frame: &frame
            )
            layoutRow(
                row: normalizedSegments,
                width: width,
                orientation: maxSquareFit.orientation,
                partitions: &partitions,
                frame: &frame
            )
            return
        }

        guard let firstNode = normalizedSegments.first else {
            return
        }

        let rowWithChild = row + CollectionOfOne(firstNode)
        if row.isEmpty || worstRatio(row: row, width: width) >= worstRatio(row: rowWithChild, width: width) {
            normalizedSegments.removeFirst()
            squarify(normalizedSegments: &normalizedSegments, row: rowWithChild, width: width, partitions: &partitions, frame: &frame)
        } else {
            layoutRow(
                row: row,
                width: width,
                orientation: biggestFittingSquare(for: frame.size).orientation,
                partitions: &partitions,
                frame: &frame
            )
            squarify(
                normalizedSegments: &normalizedSegments,
                width: biggestFittingSquare(for: frame.size).side,
                partitions: &partitions,
                frame: &frame
            )
        }
    }
}
