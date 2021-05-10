//
//  Network.swift
//  network-combine
//
//  Created by Derik Flanary on 10/15/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation
import Combine
import Network

// MARK: - Network class
    
public class NetworkManager {
    
    // MARK: - Properties
    
    private var environment: APIEnvironment?
    private let monitor = NWPathMonitor()
    var defaultSession = URLSession(configuration: .default)
    
    
    // MARK: - Path
    
    @Published public var networkPathState: NWPath?
    
    
    // MARK: - Initialization
    
    public init(environment: APIEnvironment) {
        self.environment = environment
        setUpNetworkMonitor()
        setUpDefaultSession()
    }
    
    /// Sets up network connectivity monitoring on a background queue
    /// - Note: Will update the @Published variable of `networkPathState` whenever the monitor notices a change
    private func setUpNetworkMonitor() {
        networkPathState = monitor.currentPath
        monitor.pathUpdateHandler = { path in
            self.networkPathState = path
        }
        let queue = DispatchQueue(label: NetworkKeys.networkMonitorQueue)
        monitor.start(queue: queue)
    }
    
    
    // MARK: - Performing network requests
    
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
    public func requestIgnoringError<T: Decodable>(_ urlRequest: URLRequest, responseAs: T.Type) -> AnyPublisher<T?, Never> {
        let request = adapt(urlRequest)
        
        return perform(request)
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
    ///   - responseAs: Type of the Decodable object that the publisher will return in its `Output`
    ///   - retryCount: Int value for how many times the session should retry the network call if it fails
    ///   - jsonDecoder: JSONDecoder to be used for decoding the json into the Decodable Type
    ///
    /// - Returns: A generic publisher with `Output` of T and `APIError` of Error
    public func request<T: Decodable, S: TopLevelDecoder>(_ urlRequest: URLRequest, responseAs: T.Type, retryCount: Int = 3, decoder: S) -> AnyPublisher<T, APIError> where S.Input == Data {
        let request = adapt(urlRequest)
                
        return perform(request)
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
            .decode(type: T.self, decoder: decoder)
            .mapError{ error -> APIError in
                error as? APIError ?? APIError.decodingError(error)
            }
            .eraseToAnyPublisher()
    }
        
    /// Perform a network request that will just return the `DataTaskPublisher<(Data, URLResponse), URLError>`
    /// Fetches the auth token in needed from the `ProtectedAPIEnvironment`
    ///
    /// - Note: Only to be used when you need to access the URLResponse or Data directly from the DataTaskPublisher
    ///
    /// - Parameters:
    ///   - urlRequest: The url request that contains the endpoint and httpMethod
    ///
    /// - Returns: `URLSession.DataTaskPublisher.eraseToAnyPublisher()`
    public func perform(_ urlRequest: URLRequest) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLError> {
        if let mockEnvironment = self.environment as? MockAPIEnvironment, mockEnvironment.protocolClass != nil {
            return defaultSession.dataTaskPublisher(for: urlRequest).eraseToAnyPublisher()
        }
        
        guard let environment = self.environment as? ProtectedAPIEnvironment else { return defaultSession.dataTaskPublisher(for: urlRequest).eraseToAnyPublisher() }
            return environment.authTokenPublisher
                .flatMap { token -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLError> in
                    var request = urlRequest
                    request.setValue("\(NetworkKeys.bearer) \(token)", forHTTPHeaderField: NetworkKeys.authorization)
                    return self.defaultSession.dataTaskPublisher(for: request).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
    }

    
    // MARK: - Error handling
    
    /// Convert a URLResponse and data into an `APIError`
    ///
    /// - Note: Will return an `APIError` based on the statusCode of the URLResponse
    ///
    /// - Parameters:
    ///   - response: The `URLResponse` returned from the network call/dataTaskPublisher
    ///   - data: The `Data` returned from the network request.
    ///
    /// - Returns: An `APIError` or nil on a successful request
    public func error(for response: URLResponse?, data: Data) -> APIError? {
        guard let response = response as? HTTPURLResponse else {
            return APIError.networkError(nil)
        }
        switch response.statusCode {
        case 500..<599:
            return APIError.serverError(response.curlOutput(with: data))
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
        case .userAuthenticationRequired:
            return APIError.refreshFailed
        default:
            return APIError.networkError(urlError)
        }
    }
    
}


// MARK: - Adapter

extension NetworkManager {
    
    /// Creates a default session and adds the `protocolClass` to the configuation if the environment contains one
    func setUpDefaultSession() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 45.0
        
        if let mock = environment as? MockAPIEnvironment, let protocolClass = mock.protocolClass {
            // Sets up protocolClass for a testing environment
            configuration.protocolClasses = [protocolClass]
        }
        self.defaultSession = URLSession(configuration: configuration)
    }
    
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
    
    /// Add Multipart Form Data to your request.
    /// - Note: Only  supports`String` parameters currently
    /// - Parameters:
    ///   - request: `URLRequest` to be adapted
    ///   - boundaryString: Whatever we want it to be; i.e. "CULTURE-CLOUD"
    ///   - fileName: The name of the file the server will write to; i.e. custom.jpeg
    ///   - imageName: The name of the image. i.e. "ProfileImage"
    ///   - mimeType: Mime Type is the file extension for an image (i.e. `jpeg` or `gif`)
    ///   - imageData: `Data` representation of the object to be uploaded
    ///   - parameters: `[String: Any]` Any parameters to be added to the form data
    /// - Returns: The urlrequest adapted with Multipart Form Data
    public func adaptFormMultipartFormData(_ request: URLRequest, boundaryString: String, fileName: String, imageName: String, mimeType: String, imageData: Data?, parameters: JSONObject?) -> URLRequest {
        let boundaryTag = "--"
        var urlRequest = request
        var body = Data()
        
        guard let boundary = boundaryString.data(using: .utf8),
            let contentDisposition = "Content-Disposition: form-data; name=\"\(imageName)\"; filename=\"\(fileName)\"".data(using: .utf8),
            let contentType = "\(NetworkKeys.contentTypeHeader): \(mimeType)".data(using: .utf8),
            let carriageReturn = "\r\n".data(using: .utf8),
            let boundaryTagData = boundaryTag.data(using: .utf8)
            else { return urlRequest }
        
        // "--\(boundry)\r\n"
        body.append(boundaryTagData)
        body.append(boundary)
        body.append(carriageReturn)
        
        if let imageData = imageData {
            // "Content-Disposition: form-data; name=\"\(imageName)\"; filename=\"\(fileName)\"\r\n"
            body.append(contentDisposition)
            body.append(carriageReturn)
            
            // "Content-Type: \(mimeType)\r\n\r\n"
            body.append(contentType)
            body.append(carriageReturn)
            body.append(carriageReturn)
            
            // "\(imageData)\r\n
            body.append(imageData)
            body.append(carriageReturn)
        }
        
        if let parameters = parameters {
            for (key, value) in parameters {
                // Only supports String values
                guard let stringValue = value as? String,
                      let stringData = stringValue.data(using: .utf8),
                      let stringDisposition = "Content-Disposition: form-data; name=\"\(key)\"".data(using: .utf8),
                      let stringContentType = "Content-Type: String".data(using: .utf8)
                      else { continue }
                
                // "--\(boundry)\r\n"
                body.append(boundaryTagData)
                body.append(boundary)
                body.append(carriageReturn)
                
                // "Content-Disposition: form-data; name=\"\key\"\r\n"
                body.append(stringDisposition)
                body.append(carriageReturn)
                
                // "Content-Type: \(contentType)\r\n\r\n"
                body.append(stringContentType)
                body.append(carriageReturn)
                body.append(carriageReturn)
                    
                // "\(message)\r\n
                body.append(stringData)
                body.append(carriageReturn)
            }
        }
        
        // "--\(boundry)--\r\n"
        body.append(boundaryTagData)
        body.append(boundary)
        body.append(boundaryTagData)
        body.append(carriageReturn)

        urlRequest.httpBody = body
        urlRequest.httpMethod = HTTPMethod.post.rawValue
        urlRequest.addValue("multipart/form-data; boundary=\(boundaryString)", forHTTPHeaderField: NetworkKeys.contentTypeHeader)
        urlRequest.addValue("\(body.count)", forHTTPHeaderField: NetworkKeys.contentLength)
        return urlRequest
    }
    
}
