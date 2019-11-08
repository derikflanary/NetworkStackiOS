//
//  CurlExtensions.swift
//  network-combine
//
//  Created by Derik Flanary on 10/15/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation

internal extension URLRequest {

    private struct Keys {
        static let applicationJSON = "application/json"
        static let authorizationHeader = "Authorization"
        static let basicFormat = "Basic %@"
        static let contentTypeHeader = "Content-type"
        static let formURLEncoded = "application/x-www-form-urlencoded"
        static let post = "POST"
    }

    func curlCommand(with session: URLSession) -> String? {
        var body = ""
        if let data = httpBody, httpMethod != "GET", httpMethod != "DELETE" {
            body = " -d '\(String(data: data, encoding: .utf8)!)'"
        }
        var command = ""
        var headerValues = [String]()
        if let requestHeaders = allHTTPHeaderFields {
            headerValues.append(contentsOf: requestHeaders.map { name, value in "-H '\(name): \(value)'" })
        }
        if let headers = session.configuration.httpAdditionalHeaders {
            headerValues.append(contentsOf: headers.map { name, value in "-H '\(name): \(value)'" })
            command = "\(Date()): curl -v -L \(headerValues.joined(separator: " ")) -X \(httpMethod!.uppercased())\(body) \(url!)"
        } else {
            command = "\(Date()): curl -v -L \(headerValues.joined(separator: " ")) -X \(httpMethod!.uppercased())\(body) \(url!)"
        }

        return command
    }

}


internal extension HTTPURLResponse {

    func curlOutput(with data: Data?) -> String? {
        var output = "HTTP/1.1 \(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))\n"
        for (key, value) in allHeaderFields {
            output += "\(key): \(value)\n"
        }
        if let data = data {
            output += "\n"
            output += String(data: data, encoding: .utf8)!
            output += "\n"
        }
        return output
    }

}
