//
//  MockObjectRouter.swift
//  network-combineTests
//
//  Created by Derik Flanary on 11/7/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation

@testable import NetworkStackiOS

extension Router {
    
    enum MockObject: URLRequestConvertible {

        case getObjects
        case postObject(id: Int)

        
        var method: HTTPMethod {
            switch self {
            case .getObjects:
                return .get
            case .postObject:
                return .post
            }
        }
        
        var path: String {
            switch self {
            case .getObjects:
                return "/objects"
            case .postObject:
                return "/object"
            }
        }
        
        func asURLRequest() throws -> URLRequest {
            let url = try path.asURL()
            var urlRequest = URLRequest(url: url)
            
            switch self {
            case .getObjects:
                break
            case .postObject(let id):
                var params = JSONObject()
                params["id"] = id
                urlRequest = URLRequest(url: url.parameterEncoded(with: params) ?? url)
            }
            urlRequest.httpMethod = method.rawValue
            return urlRequest
        }
        
    }
}
