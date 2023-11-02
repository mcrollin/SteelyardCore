//
//  Copyright © Marc Rollin.
//

import ApplicationArchive
import SwiftUI

extension ArchiveApp.Platform {

    public var icon: some View {
        let systemName = switch self {
        case .iphone: "iphone"
        case .mac: "macbook"
        case .ipad: "ipad"
        case .tv: "appletv"
        case .watch: "applewatch"
        }

        return Image(systemName: systemName)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}
