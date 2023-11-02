//
//  Copyright © Marc Rollin.
//

import Foundation

// MARK: - ErrorResponse

struct ErrorResponse: LocalizedError, Codable {
    let errors: [ErrorDetail]

    var errorDescription: String? {
        errors.map(\.detail).joined(separator: "\n")
    }
}

// MARK: - ErrorDetail

struct ErrorDetail: Codable {
    let status: String
    let code: String
    let title: String
    let detail: String
}
