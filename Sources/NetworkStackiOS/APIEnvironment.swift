//
//  API.swift
//  network-combine
//
//  Created by Derik Flanary on 10/15/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation
import Combine

protocol APIEnvironment {
    var baseURL: URL? { get }
}


protocol ProtectedAPIEnvironment: APIEnvironment {
    var bearerToken: String? { get }
    var refreshToken: String? { get }
    var isExpired: Bool { get }
    
    func refresh(with token: String) -> AnyPublisher<JSONObject, Error>
}


protocol MockAPIEnvironment: APIEnvironment {
    var protocolClass: AnyClass? { get }
}
