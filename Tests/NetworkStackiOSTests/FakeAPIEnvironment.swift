//
//  FakeAPIEnvironment.swift
//  network-combineTests
//
//  Created by Derik Flanary on 11/7/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation
import Combine

@testable import NetworkStackiOS

class FakeAPIEnvironment: ProtectedAPIEnvironment {
    
    var protocolClass: AnyClass? = MockURLProtocol.self
    var bearerToken: String? = "fake-token"
    var refreshToken: String? = nil
    var baseURL: URL? = nil
    var refreshSuccess = true
    var refreshCount = 0
    var queueCount = 0
    var validTokenCount = 0
    private let queue = DispatchQueue(label: "Autenticator.\(UUID().uuidString)")
    private var refreshSubscriber: AnyCancellable?
    private let tokenSubject = PassthroughSubject<Token, Never>()

    var isExpired: Bool {
        return bearerToken == nil
    }
    
    init() { }
    
    init(protocolClass: AnyClass?, bearerToken: String?, refreshToken: String?, baseURL: URL?) {
        self.protocolClass = protocolClass
        self.bearerToken = bearerToken
        self.refreshToken = refreshToken
        self.baseURL = baseURL
    }
    
    var authTokenPublisher: AnyPublisher<Token, URLError> {
        return queue.sync { [weak self] in
            guard refreshSuccess else { return Fail<String, URLError>(error: URLError(.userAuthenticationRequired)).eraseToAnyPublisher()}
            if let bearerToken = self?.bearerToken, !isExpired {
                self?.validTokenCount += 1
                print("👍 Valid token used")
                return Just(bearerToken)
                    .setFailureType(to: URLError.self)
                    .eraseToAnyPublisher()
            }
            
            if self?.refreshSubscriber == nil {
                self?.refreshSubscriber = Just(UUID().uuidString)
                    .delay(for: .seconds(2), scheduler: RunLoop.current)
                    .sink(receiveCompletion: { _ in
                        self?.refreshSubscriber = nil
                    }, receiveValue: { token in
                        self?.bearerToken = token
                        self?.refreshCount += 1
                        self?.tokenSubject.send(token)
                        print("🔄 Refreshed")
                    })
            } else {
                self?.queueCount += 1
                print("⏸ Queued")
            }
            
            return tokenSubject
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
        }
    }
    
}

class TestMockAPIEnvironment: MockAPIEnvironment {
    var baseURL: URL? = nil
    var protocolClass: AnyClass? = MockURLProtocol.self
    
    init() { }
    
}
