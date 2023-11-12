//
//  Copyright © Marc Rollin.
//

import Foundation

extension Collection where Element: Equatable {

    public func element(after element: Element) -> Element? {
        if let currentIndex = firstIndex(of: element),
           index(after: currentIndex) < endIndex {
            self[index(after: currentIndex)]
        } else {
            nil
        }
    }
}

extension BidirectionalCollection where Element: Equatable {

    public func element(before element: Element) -> Element? {
        if let currentIndex = firstIndex(of: element),
           currentIndex > startIndex {
            self[index(before: currentIndex)]
        } else {
            nil
        }
    }
}
