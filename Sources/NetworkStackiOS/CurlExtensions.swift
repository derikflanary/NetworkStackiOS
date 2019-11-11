//
//  CurlExtensions.swift
//  network-combine
//
//  Created by Derik Flanary on 10/15/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation

internal extension HTTPURLResponse {

    /// Converts the data from a network response into a curl String
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
