//
//  Copyright © Marc Rollin.
//

import Foundation

public enum ArchiveNodeMetadata: Sendable, Equatable {
    case app(InfoPlist)
    case appex(InfoPlist)
}
