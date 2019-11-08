//
//  FakeAPIEnvironment.swift
//  network-combineTests
//
//  Created by Derik Flanary on 11/7/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation
import Combine

@testable import Network_Stack

struct FakeAPIEnvironment: ProtectedAPIEnvironment, MockAPIEnvironment {
    
    var protocolClass: AnyClass? = MockURLProtocol.self
    var bearerToken: String? = nil
    var refreshToken: String? = nil
    var baseURL: URL? = nil

    var isExpired: Bool {
        return bearerToken == nil
    }
    
    func refresh(with token: String) -> AnyPublisher<JSONObject, Error> {
        return Result<JSONObject, Error>.Publisher(["blank": "blank"]).eraseToAnyPublisher()
    }
    
}

