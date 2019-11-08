//
//  URLRequestConvertibleSpec.swift
//  network-combineTests
//
//  Created by Derik Flanary on 11/7/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation
import XCTest

@testable import NetworkStackiOS

class URLRequestConvertibleSpec: XCTestCase {
    
    func testConvertsRouterToRequest() {
        let request = Router.MockObject.getObjects.urlRequest
        expect(notNil: request)
        expect(request?.httpMethod, equals: HTTPMethod.get.rawValue.uppercased())
    }
    
    
}

class URLConvertibleSpec: XCTestCase {
    
    func testConvertsStringToURL() {
        let testString = "www.apple.com"
        let url = try? testString.asURL()
        expect(notNil: url)
    }
    
}

class URLParameterEncodingSpec: XCTestCase {
    
    func testParametersAreEncoded() {
        let id = 1
        let request = Router.MockObject.postObject(id: 1).urlRequest!
        expect(request.url?.absoluteString, equals: "/object?id=\(id)")
    }
    
}
