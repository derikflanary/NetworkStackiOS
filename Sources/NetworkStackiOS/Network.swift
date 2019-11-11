//
//  Network.swift
//  network-combine
//
//  Created by Derik Flanary on 10/15/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation
import Combine

// MARK: - Networkable Protocol

public protocol Networkable {
    func perform(_ urlRequest: URLRequest, with session: URLSession) -> URLSession.DataTaskPublisher
    func requestIgnoringError<T: Codable>(_ urlRequest: URLRequest, responseAs: T.Type) -> AnyPublisher<T?, Never>
    func request<T: Codable>(_ urlRequest: URLRequest, responseAs: T.Type, retryCount: Int) -> AnyPublisher<T, APIError>
}


// MARK: - Network class
    
public class Network: Networkable {
    
    // MARK: - Properties
    
    var environment: APIEnvironment?
    
    private var defaultSession: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10.0
        
        // Sets up protocolClass for a testing environment
        if let mock = environment as? MockAPIEnvironment, let protocolClass = mock.protocolClass {
            configuration.protocolClasses = [protocolClass]
            return URLSession(configuration: configuration)
        }
        
        guard let environment = environment as? ProtectedAPIEnvironment, let token = environment.bearerToken, !environment.isExpired else { return URLSession(configuration: configuration) }
        
        configuration.httpAdditionalHeaders = [NetworkKeys.authorization: "\(NetworkKeys.bearer) \(token)"]
        return URLSession(configuration: configuration)
    }
    
    
    // MARK: - Initialization
    
    public init(environment: APIEnvironment) {
        self.environment = environment
    }
    
    
    // MARK: - Preforming network requests
    
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
    public func requestIgnoringError<T: Codable>(_ urlRequest: URLRequest, responseAs: T.Type) -> AnyPublisher<T?, Never> {
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
    /// - Returns: A generic publisher with `Output` of T and `APIError` of Error
    public func request<T: Codable>(_ urlRequest: URLRequest, responseAs: T.Type, retryCount: Int = 3) -> AnyPublisher<T, APIError> {
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
        
    /// Perform a network request that will just return the `DataTaskPublisher<(Data, URLResponse), URLError>`
    ///
    /// - Note: Only to be used you need to access the URLResponse or Data directly from the DataTaskPublisher
    ///
    /// - Parameters:
    ///   - urlRequest: The url request that contains the endpoint and httpMethod
    ///   - session: the `URLSession` that will perform the request
    ///
    /// - Returns: URLSession.DataTaskPublisher
    public func perform(_ urlRequest: URLRequest, with session: URLSession) -> URLSession.DataTaskPublisher {
        return session.dataTaskPublisher(for: urlRequest)
    }

    
    // MARK: Error handling
    
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

    /// Convert a `URLError` into an `APIError`
    ///
    /// - Note: Will return an `APIError` based on the `code` of the `URLError`. Defaults to `APIError.networkError`
    ///
    /// - Parameters:
    ///   - urlError: The `URLError` returned from the network request
    ///
    /// - Returns: An `APIError`, defaults to `networkError`
    private func convertedError(from urlError: URLError) -> APIError {
        switch urlError.code {
        case .notConnectedToInternet:
            return APIError.noInternetConnection
        default:
            return APIError.networkError(urlError)
        }
    }

}


// MARK: - Adapter

extension Network {
    
    /// Adapts a URLRequest to include the `baseURL` from the environment and the correct `contentTypeHeader` for the `httpMethod`
    func adapt(_ urlRequest: URLRequest) -> URLRequest {
        var request = urlRequest
        request.url = request.url?.based(at: environment?.baseURL)
        if let method = request.httpMethod, method == HTTPMethod.post.rawValue, request.value(forHTTPHeaderField: NetworkKeys.contentTypeHeader) == nil {
            request.setValue(NetworkKeys.applicationJSON, forHTTPHeaderField: NetworkKeys.contentTypeHeader)
        }
        request.addValue(UUID().uuidString, forHTTPHeaderField: NetworkKeys.requestIdHeader)
        
        return request
    }
    
}
