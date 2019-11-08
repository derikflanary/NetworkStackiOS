//
//  Network.swift
//  network-combine
//
//  Created by Derik Flanary on 10/15/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation
import Combine

internal protocol Networkable {
    func perform(_ urlRequest: URLRequest, with session: URLSession) -> URLSession.DataTaskPublisher
    func requestIgnoringError<T: Codable>(_ urlRequest: URLRequest, responseAs: T.Type) -> AnyPublisher<T?, Never>
    func request<T: Codable>(_ urlRequest: URLRequest, responseAs: T.Type, retryCount: Int) -> AnyPublisher<T, Error>
}

    
class Network: Networkable {
    
    var environment: ProtectedAPIEnvironment?
    
    private var defaultSession: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10.0
        if let mock = environment as? MockAPIEnvironment, let protocolClass = mock.protocolClass {
            configuration.protocolClasses = [protocolClass]
        }
        guard let environment = environment, let token = environment.bearerToken, !environment.isExpired else { return URLSession(configuration: configuration) }
        configuration.httpAdditionalHeaders = [NetworkKeys.authorization: "\(NetworkKeys.bearer) \(token)"]
        return URLSession(configuration: configuration)
    }
    
    init(environment: ProtectedAPIEnvironment) {
        self.environment = environment
    }
    
    /// Perform a network request that will return a publisher that ignores the error and instead returns an optional value
    ///
    /// - Note: This will return `nil` if an error occurs either on the network request or on the decoding of the json data.
    ///         This will retry the request at most 3 times if the network call fails.
    ///
    /// - Parameters:
    ///   - T: The type of the object the decoder will decode the json into
    ///   - urlRequest: The url request that contains the endpoint and httpMethod
    ///
    /// - Returns: A generic publisher with `Output` of T? and Never for the `Error`
    func requestIgnoringError<T: Codable>(_ urlRequest: URLRequest, responseAs: T.Type) -> AnyPublisher<T?, Never> {
        let request = adapt(urlRequest)
        
        return perform(request, with: defaultSession)
            .retry(3)
            .map { $0.data }
            .decode(type: T?.self, decoder: JSONDecoder())
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    
    /// Perform a network request that will return a publisher with the output of `T` or `Error`
    ///
    /// - Note: This returns a publisher that should be subscribed to
    ///
    /// - Parameters:
    ///   - T: The type of the object the decoder will decode the json into
    ///   - urlRequest: The url request that contains the endpoint and httpMethod
    ///   - responseAs: Type of the Codable object that the publisher will return in its `Output`
    ///   - retryCount: Int value for how many times the session should retry the network call if it fails
    ///
    /// - Returns: A generic publisher with `Output` of T and `Error` of Error
    func request<T: Codable>(_ urlRequest: URLRequest, responseAs: T.Type, retryCount: Int = 3) -> AnyPublisher<T, Error> {
        let request = adapt(urlRequest)
                
        return perform(request, with: defaultSession)
            .retry(retryCount)
            .mapError{ error -> APIError in
                self.convertedError(from: error)
            }
            .tryMap { output in
                if let error = self.error(for: output.response, data: output.data) {
                    throw error
                }
                return output.data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError{ error -> APIError in
                error as? APIError ?? APIError.decodingError(error)
            }
            .eraseToAnyPublisher()
    }
        
    func perform(_ urlRequest: URLRequest, with session: URLSession) -> URLSession.DataTaskPublisher {
        return session.dataTaskPublisher(for: urlRequest)
    }

    /// Convert a URLResponse and data into an `APIError`
    ///
    /// - Note: Will return an `APIError` based on the statusCode of the URLResponse
    ///
    /// - Parameters:
    ///   - response: The `URLResponse` returned from the network call/dataTaskPublisher
    ///   - data: The `Data` returned from the network request.
    ///
    /// - Returns: An `APIError` or nil on a successful request
    private func error(for response: URLResponse?, data: Data) -> APIError? {
        guard let response = response as? HTTPURLResponse else {
            return APIError.networkError(nil)
        }
        switch response.statusCode {
        case 400, 422:
            let detail = String(data: data, encoding: .utf8)
            return APIError.validationFailed(detail)
        case 200..<299:
            return nil
        default:
            return APIError.unsuccessfulRequest(response.curlOutput(with: data))
        }
    }

    private func convertedError(from urlError: URLError) -> APIError {
        switch urlError.code {
        case .notConnectedToInternet:
            return APIError.noInternetConnection
        default:
            return APIError.networkError(urlError)
        }
    }

}


// Adapter

extension Network {
    
    /// Adapts a URLRequest to include the `baseURL` from the environment and the correct `contentTypeHeader` for the `httpMethod`
    func adapt(_ urlRequest: URLRequest) -> URLRequest {
        var request = urlRequest
        request.url = request.url?.based(at: environment?.baseURL)
        if let method = request.httpMethod, method == HTTPMethod.post.rawValue.uppercased(), request.value(forHTTPHeaderField: NetworkKeys.contentTypeHeader) == nil {
            request.setValue(NetworkKeys.applicationJSON, forHTTPHeaderField: NetworkKeys.contentTypeHeader)
        }
        request.addValue(UUID().uuidString, forHTTPHeaderField: NetworkKeys.requestIdHeader)
        
        return request
    }
    
}


extension URL {
    
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
    
}

