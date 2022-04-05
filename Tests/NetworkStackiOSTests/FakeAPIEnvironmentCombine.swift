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
    var bearerToken: String? = nil
    var refreshToken: String? = "refresh-token"
    var baseURL: URL? = nil
    var refreshSuccess = true
    var refreshCount = 0
    var queueCount = 0
    var validTokenCount = 0
    private let queue = DispatchQueue(label: "Autenticator.\(UUID().uuidString)")
    private var refreshSubscriber: AnyCancellable?
    private let tokenSubject = PassthroughSubject<Token, Never>()
    private var refresher: Refresher = Refresher(authToken: nil, refreshToken: "refresh-token")

    var isExpired: Bool {
        return bearerToken == nil
    }
    
    init() { }
    
    init(protocolClass: AnyClass?, bearerToken: String?, refreshToken: String?, baseURL: URL?) {
        self.protocolClass = protocolClass
        self.bearerToken = bearerToken
        self.refreshToken = refreshToken
        self.baseURL = baseURL
        self.refresher = Refresher(authToken: bearerToken, refreshToken: refreshToken)
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
    
    func authToken() async throws -> String {
        if let bearerToken = bearerToken {
            return bearerToken
        } else {
            return try await refresher.refresh()
        }
    }
    
}

class TestMockAPIEnvironment: MockAPIEnvironment {
    var baseURL: URL? = nil
    var protocolClass: AnyClass? = MockURLProtocol.self
    
    init() { }
    
}

actor Refresher {
    
    private enum Status {
        case inProgress(Task<String, Error>)
        case ready
    }
    
    private var authToken: String?
    private var refreshToken: String?
    private var status: Status = .ready
    private var isExpired: Bool {
        authToken == nil

    }
    init(authToken: String?, refreshToken: String? = "refreshToken") {
        self.authToken = authToken
        self.refreshToken = refreshToken
    }

    func refresh() async throws -> String {
        guard let refreshToken = refreshToken else { throw APIError.unauthorized }
            
        switch status {
        case .inProgress(let handle):
            return try await handle.value
        case .ready:
            if let authToken = authToken, !isExpired {
                return authToken
            }
            let handle = Task {
                try await newAuthToken(with: refreshToken)
            }
            status = .inProgress(handle)

            do {
                let newToken = try await handle.value
                authToken = newToken
                status = .ready
                return newToken
            } catch {
                throw error
            }
        }
    }
    
    private func newAuthToken(with refreshToken: String) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000)
        let token = "\(Int.random(in: 1..<100))"
        authToken = token
        print(token)
        print("🔄 is refreshing")
        return token
    }
    
}
