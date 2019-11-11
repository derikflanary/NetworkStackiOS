//
//  URLRequestConvertible.swift
//  network-combine
//
//  Created by Derik Flanary on 10/15/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation

public typealias JSONObject = [String: Any]


// MARK: - URLRequestConvertible

/// Types adopting the `URLRequestConvertible` protocol can be used to construct URL requests.
public protocol URLRequestConvertible {

    var method: HTTPMethod { get }
    
    var path: String { get }
    
    /// Returns a URL request or throws if an `Error` was encountered.
    ///
    /// - throws: An `Error` if the underlying `URLRequest` is `nil`.
    ///
    /// - returns: A URL request.
    func asURLRequest() throws -> URLRequest
    
}

extension URLRequestConvertible {
    /// The URL request.
    public var urlRequest: URLRequest? { return try? asURLRequest() }
}




// MARK: - URLConvertible

/// Types adopting the `URLConvertible` protocol can be used to construct URLs, which are then used to construct
/// URL requests.
public protocol URLConvertible {
    /// Returns a URL that conforms to RFC 2396 or throws an `Error`.
    ///
    /// - throws: An `Error` if the type cannot be converted to a `URL`.
    ///
    /// - returns: A URL or throws an `Error`.
    func asURL() throws -> URL
}

extension String: URLConvertible {
    /// Returns a URL if `self` represents a valid URL string that conforms to RFC 2396 or throws an `APIError`.
    ///
    /// - throws: An `APIError.invalidURL` if `self` is not a valid URL string.
    ///
    /// - returns: A URL or throws an error.
    public func asURL() throws -> URL {
        guard let url = URL(string: self) else { throw APIError.invalidURL(url: self) }
        return url
    }
}

extension URL: URLConvertible {
    /// Returns self.
    public func asURL() throws -> URL { return self }
}

extension URLComponents: URLConvertible {
    /// Returns a URL if `url` is not nil, otherwise throws an `Error`.
    ///
    /// - throws: An `APIError.invalidURL` if `url` is `nil`.
    ///
    /// - returns: A URL or throws an `AFError`.
    public func asURL() throws -> URL {
        guard let url = url else { throw APIError.invalidURL(url: self) }
        return url
    }
}


// MARK: - URL extensions

public extension URL {
    
    /// Adds the baseURl to the endpoint URL
    func based(at base: URL?) -> URL? {
        guard let base = base else { return self }
        guard let baseComponents = URLComponents(string: base.absoluteString) else { return self }
        guard var components = URLComponents(string: self.absoluteString) else { return self }
        guard components.scheme == nil else { return self }
        
        components.scheme = baseComponents.scheme
        components.host = baseComponents.host
        components.port = baseComponents.port
        components.path = baseComponents.path + components.path
        return components.url
    }
    
    /// Encodes a `JSONObject` into query items on a url
    ///
    /// - Note: Will return an `APIError` based on the statusCode of the URLResponse
    ///
    /// - Parameters:
    ///   - jsonObject: the parameters to be encoded. `[String: Any]`
    ///
    /// - Returns: An optional url that has the paremeters encoded into it
    func parameterEncoded(with jsonObject: JSONObject) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        var queryItems = [URLQueryItem]()
        for (name, value) in jsonObject {
            let queryItem = URLQueryItem(name: name, value: String(describing: value))
            queryItems.append(queryItem)
        }
        
        components?.queryItems = queryItems
        return components?.url
    }
    
}
