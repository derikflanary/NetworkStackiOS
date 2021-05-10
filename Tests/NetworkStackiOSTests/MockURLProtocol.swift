//
//  MockURLProtocol.swift
//  network-combineTests
//
//  Created by Derik Flanary on 11/6/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Combine
import Foundation

@testable import NetworkStackiOS

class MockURLProtocol: URLProtocol {
    
    static var responseData: Data?
    static var statusCode = 200
    static var urlErrorCode: URLError.Code?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url else { return }
        
        let response = HTTPURLResponse(url: url, statusCode: MockURLProtocol.statusCode, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        
        if let responseData = MockURLProtocol.responseData {
            self.client?.urlProtocol(self, didLoad: responseData)
        } else {
            self.client?.urlProtocol(self, didFailWithError: URLError(.cannotParseResponse))
        }
        
        if let errorCode = MockURLProtocol.urlErrorCode {
            self.client?.urlProtocol(self, didFailWithError: URLError(errorCode))
        }
        self.client?.urlProtocolDidFinishLoading(self)
    }

    // this method is required but doesn't need to do anything
    override func stopLoading() {
        
    }

}


class MockObject: Codable, Equatable {
    
    var id = 1
    var name = "name"
    
    static func == (lhs: MockObject, rhs: MockObject) -> Bool {
        lhs.id == rhs.id
    }
    
}
