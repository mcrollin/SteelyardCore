//
//  Copyright © Marc Rollin.
//

import ApplicationArchive
import SwiftUI

// MARK: - ApplicationArchiveNode + TreeMapDisplayable

extension ArchiveNode: TreeMapDisplayable {

    public var color: Color? {
        switch category {
        case .app: .teal
        case .appExtension: .brown
        case .assetCatalog: .green
        case .binary: .blue
        case .bundle: .indigo
        case .content: .mint
        case .data: .gray
        case .font: .cyan
        case .framework: .brown
        case .localization: .orange
        case .model: .purple
        case .folder: nil
        }
    }

    public var icon: some View {
        let systemName = switch category {
        case .app: "folder.fill.badge.gearshape"
        case .appExtension: "puzzlepiece.extension.fill"
        case .assetCatalog: "photo.on.rectangle.fill"
        case .binary: "apple.terminal.fill"
        case .bundle: "shippingbox.fill"
        case .content: "doc.text.fill"
        case .data: "doc.badge.gearshape.fill"
        case .font: "textformat"
        case .framework: "shippingbox.fill"
        case .localization: "character.bubble.fill"
        case .model: "doc.badge.gearshape.fill"
        case .folder: "folder.fill"
        }

        return Image(systemName: systemName)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    public var segments: [ArchiveNode] {
        childrenBySize
    }

    public var shouldShowDetails: Bool {
        !children.isEmpty
    }

    public var size: CGFloat {
        CGFloat(sizeInBytes)
    }
}
