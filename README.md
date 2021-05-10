# NetworkStackiOS

A simple network stack using Combine to perform requests and token refresh


## Usage
* Subscribe to  `request<T: Codable>(_ urlRequest: URLRequest, responseAs: T.Type)` on `NetworkManager` to perform a request. Pass in the url request and the Type you want to be returned that conforms to `Codable`. The publisher will publish `<T, APIError>` 

* For unprotected network requests (requests that do not require a token), initialize a `NetworkManager` with an object that conforms to `APIEnvironment`. Then call  `request` on the `NetworkManager` you created.

* To perform a protected network request (requests that require an auth token of some kind), create an object that conforms to `ProtectedAPIEnvironment` and then initialize a `NetworkManager` with that environment. Then call  `request` on the `NetworkManager` you created.

* You can use the `HTTPMethod` enum when setting the httpMethod on the `URLRequest`

* You can also set the `retryCount` and `JSONDecoder` when making the request. The network manager will retry the request if it fails when trying to make the request. The  `JSONDecoder` can be set for custom decoding of the json that will be returned from the request.

* You can subscribe to `requestIgnoringError<T: Codable>(_ urlRequest: URLRequest, responseAs: T.Type) -> AnyPublisher<T?, Never>` if you wish to make a request and want to ignore any possible errors.  If an error does occur then the publisher will publish `nil`

* In rare cases where you need to access to the    `URLSession.DataTaskPublisher.Output` directly, you can subscribe to `perform(_ urlRequest: URLRequest) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLError>` on the `NetworkManager`


## Example

 *  `guard let request = urlRequest else { return }`  - First create a `URLRequest`
 
 *  `let networkManger = NetworkManger(environment: ProtectedEnvironment())` - Initialize a `NetworkManager` with an object that comforms to an `APIEnvironment` or a `ProtectedAPIEnvironment`
 
 * `self.subscriber = networkManager.request(request, responseAs: CodableObject.self)
     .sink(receiveCompletion: { completion in
         switch completion {
         case .failure(let error):
             print(error)
         case .finished:
             break
         }
     }, receiveValue: { codableObject in
            self.handle(codableObject)
 })` - Subscribe to the `request` and then handle the published `error` or decoded object
