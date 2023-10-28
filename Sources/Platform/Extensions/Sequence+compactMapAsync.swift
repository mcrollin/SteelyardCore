//
//  Copyright © Marc Rollin.
//

import Foundation

extension Sequence {

    public func compactMapAsync<T>(
        _ transform: @escaping (Element) async throws -> T?
    ) async throws -> [T] {
        var result = [T]()
        for element in self {
            if let transformed = try await transform(element) {
                result.append(transformed)
            }
        }
        return result
    }
}
