//
//  Copyright © Marc Rollin.
//

import Foundation

extension Sequence {

    public func sorted(by keyPath: KeyPath<Element, some Comparable>, order: SortOrder = .forward) -> [Element] {
        sorted {
            switch order {
            case .forward: $0[keyPath: keyPath] < $1[keyPath: keyPath]
            case .reverse: $0[keyPath: keyPath] > $1[keyPath: keyPath]
            }
        }
    }
}
