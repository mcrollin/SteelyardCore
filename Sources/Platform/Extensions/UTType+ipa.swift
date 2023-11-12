//
//  Copyright © Marc Rollin.
//

import Foundation
import UniformTypeIdentifiers

extension UTType {

    public static var ipa: UTType {
        UTType(exportedAs: "com.apple.itunes.ipa", conformingTo: .data)
    }
}
