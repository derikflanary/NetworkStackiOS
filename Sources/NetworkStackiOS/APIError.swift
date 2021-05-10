//
//  APIError.swift
//  network-combine
//
//  Created by Derik Flanary on 10/15/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation

/// Networking errors based on status codes and `URLError`s received.
public enum APIError: Error {
    case decodingError(Error?) // Error caused by a failure to decode a `Decodable`
    case invalidURL(url: URLConvertible) // The `URLConvertible` could not be converted into a `URL`
    case networkError(Error?) // A generic error when no response is returned from the network
    case noInternetConnection
    case refreshFailed // Call to refresh an access token fails
    case responseCorrupted // The response received from the network can not be read
    case serverError(String?) // A 500~ error
    case unsuccessfulRequest(String?) // An error response with a status other than a 500 or 400 or 200
    case validationFailed(String?) // A 400~ error
}
