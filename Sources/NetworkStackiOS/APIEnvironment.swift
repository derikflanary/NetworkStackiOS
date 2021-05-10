//
//  API.swift
//  network-combine
//
//  Created by Derik Flanary on 10/15/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation
import Combine

public typealias Token = String

/// A `NetworkManager` can be initialized with any object that comforms to this protocol.
/// - Note: This is used mostly to make unauthenticated network requests
public protocol APIEnvironment {
    var baseURL: URL? { get }
}

/// A `NetworkManager` can be initialized with any object that comforms to this protocol.
/// - Note: This is used mostly to make authenticated network requests. The `NetworkManager` will call `authTokenPublisher` to get back a valid `Token`
public protocol ProtectedAPIEnvironment: APIEnvironment {
    var isExpired: Bool { get }
    var authTokenPublisher: AnyPublisher<Token, URLError> { get }
}

/// This will allow you to control the responses returned to the `NetworkManager` when in a testing environment
/// - Note: Only to be used for testing
public protocol MockAPIEnvironment: APIEnvironment {
    var protocolClass: AnyClass? { get }
}
