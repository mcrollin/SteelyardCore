//
//  Copyright © Marc Rollin.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation
import SwiftJWT

actor AppStoreConnectClient {

    // MARK: Lifecycle

    init(keyID: String, issuerID: String, audience: String, privateKey: URL) throws {
        self.keyID = keyID
        self.issuerID = issuerID
        self.audience = audience
        self.privateKey = try Data(contentsOf: privateKey)
    }

    // MARK: Internal

    enum RequestError: LocalizedError {
        case http(code: Int, data: Data)

        var errorDescription: String? {
            switch self {
            case .http(let code, _):
                let explanation = switch code {
                case 400..<500:
                    "The request was invalid or cannot be otherwise served."
                case 500..<600:
                    "An error occurred on the server while processing the request."
                default:
                    "An unknown HTTP error occurred."
                }
                return "Network issue: Received HTTP status code \(code). \(explanation)"
            }
        }
    }

    func send(request: HTTPRequest) async throws -> Data {
        let jwt = try jwtToken(httpMethod: request.method.rawValue, path: request.path!)

        var request = request
        request.headerFields.append(.init(name: .authorization, value: "Bearer \(jwt)"))

        let (data, response) = try await URLSession.shared.data(for: request)

        switch response.status.kind {
        case .successful:
            return data
        default:
            throw RequestError.http(
                code: response.status.code,
                data: data
            )
        }
    }

    // MARK: Private

    private struct Claim: Claims {
        let iss: String
        var iat = Date()
        var exp = Date().addingTimeInterval(1200)
        let aud: String
        let scope: [String]
    }

    private let keyID: String
    private let issuerID: String
    private let audience: String
    private let privateKey: Data

    // Helper function to create the JWT token
    private func jwtToken(httpMethod: String, path: String) throws -> String {
        let header = Header(typ: "JWT", kid: keyID)
        let claim = Claim(iss: issuerID, aud: audience, scope: ["\(httpMethod) \(path)"])
        var jwt = JWT(header: header, claims: claim)
        return try jwt.sign(using: .es256(privateKey: privateKey))
    }
}
