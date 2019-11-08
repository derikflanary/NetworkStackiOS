//
//  APIError.swift
//  network-combine
//
//  Created by Derik Flanary on 10/15/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation

public enum APIError: Error {
    case noInternetConnection
    case networkError(Error?)
    case unsuccessfulRequest(String?)
    case responseCorrupted
    case validationFailed(String?)
    case invalidURL(url: URLConvertible)
    case decodingError(Error?)
}
