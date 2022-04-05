//
//  NetworkSpec.swift
//  network-combineTests
//
//  Created by Derik Flanary on 11/6/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation
import XCTest
import Combine

@testable import NetworkStackiOS

class NetworkSpec: XCTestCase {
    
    // MARK: - Properties
    
    var cancelable: Cancellable?
    let expectation = XCTestExpectation(description: "subscription fulfilled")
    let encoder = JSONEncoder()
    let mockObject = MockObject()
    var fakeGetRequest = Router.MockObject.getObjects.urlRequest!
    var fakePostRequest = Router.MockObject.postObject(id: 1).urlRequest!
    var subscribers = Set<AnyCancellable>()
    var session: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
    var expiredEnvironment: FakeAPIEnvironment {
        let expiredEnvironment = FakeAPIEnvironment()
        expiredEnvironment.bearerToken = nil
        return expiredEnvironment
    }

    
    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()
        cancelable = nil
        MockURLProtocol.responseData = nil
        MockURLProtocol.urlErrorCode = nil
        MockURLProtocol.statusCode = 200
    }
    
    
    // MARK: - Success Tests
    
    /// test that it returns a decoded object on a successful request
    func testThatItReturnsArrayASingleObject() {
        let data = try! encoder.encode(mockObject)
        MockURLProtocol.responseData = data
        
        cancelable = NetworkManager(environment: TestMockAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    break
                case .finished:
                    self.expectation.fulfill()
                }
            }) { object in
                self.expect(object, equals: self.mockObject)
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// test that it returns an array of decoded objects on a successful request
    func testThatItReturnsArrayOfObjects() {
        let data = try! encoder.encode([mockObject])
        MockURLProtocol.responseData = data
        
        cancelable = NetworkManager(environment: TestMockAPIEnvironment()).request(fakeGetRequest, responseAs: [MockObject].self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    break
                case .finished:
                    self.expectation.fulfill()
                }
            }) { objects in
                self.expect(objects, equals: [self.mockObject])
            }

        wait(for: [expectation], timeout: 5.0)
    }
    
    /// test that it return the decoded object and not nil
    func testThatItReturnsObjectAndNotNil() {
        let data = try! encoder.encode(mockObject)
        MockURLProtocol.responseData = data
        
        cancelable = NetworkManager(environment: TestMockAPIEnvironment()).requestIgnoringError(fakeGetRequest, responseAs: MockObject.self)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    break
                case .finished:
                    self.expectation.fulfill()
                }
            }) { value in
                self.expect(value, equals: self.mockObject)
            }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// test that it will return a success if a post is called
    func testThatSuccessfullyPosts() {
        let data = try! encoder.encode(mockObject)
            MockURLProtocol.responseData = data
            
            cancelable = NetworkManager(environment: TestMockAPIEnvironment()).requestIgnoringError(fakePostRequest, responseAs: MockObject.self)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure:
                        break
                    case .finished:
                        self.expectation.fulfill()
                    }
                }) { value in
                    self.expect(value, equals: self.mockObject)
                }
        expect(notNil: cancelable)
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// test that a subscription will cancel successfully
    func testSubscriptionCancelsSuccessfully() {
        cancelable = NetworkManager(environment: TestMockAPIEnvironment()).requestIgnoringError(fakePostRequest, responseAs: MockObject.self)
            .handleEvents(receiveCancel: {
                self.expectation.fulfill()
            })
            .sink(receiveCompletion: { completion in }) { _ in }
        
        cancelable!.cancel()
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    // MARK: - Failure Tests
    
    /// test that it throws an error when no data returns
    func testThatItThrowsAnErrorWhenNoDataReturns() {
        cancelable = NetworkManager(environment: TestMockAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    self.expectation.fulfill()
                    guard case .networkError(let err) = error else { XCTFail("Expected a network error"); return }
                    self.expect(notNil: err)
                case .finished:
                    break
                }
            }) { _ in }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testThatItThrowsAValidationFailedWith400Response() {
        MockURLProtocol.responseData = Data()
        MockURLProtocol.statusCode = 400
        cancelable = NetworkManager(environment: TestMockAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    guard case .validationFailed(_) = error else { XCTFail("Expected a validationFailed error"); return }
                    self.expectation.fulfill()
                case .finished:
                    break
                }
            }) { _ in }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testThatItThrowsUnsuccessfulRequestWithA500Response() {
        MockURLProtocol.responseData = Data()
        MockURLProtocol.statusCode = 500
        cancelable = NetworkManager(environment: TestMockAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    guard case .serverError(let output) = error else { XCTFail("Expected a validationFailed error"); return }
                    self.expect(output, equals: "HTTP/1.1 500 internal server error\n\n\n")
                    self.expectation.fulfill()
                case .finished:
                    break
                }
            }) { _ in }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// test that it return nil when an error is thrown
    func testThatItReturnsNilWithError() {
        cancelable = NetworkManager(environment: FakeAPIEnvironment()).requestIgnoringError(fakeGetRequest, responseAs: MockObject.self)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    break
                case .finished:
                    self.expectation.fulfill()
                }
            }) { value in
                self.expect(nil: value)
            }

        wait(for: [expectation], timeout: 5.0)
    }
    
    /// test that it throws an error with invalid data
    func testThatItThrowsAnErrorWithErrorWhenDecodingData() {
        MockURLProtocol.responseData = Data()
        cancelable = NetworkManager(environment: TestMockAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    guard case .decodingError(let err) = error else { XCTFail("Expected a decoding error"); return }
                    self.expectation.fulfill()
                    self.expect(notNil: err)
                case .finished:
                    break
                }
            }) { _ in }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// test throws correct error when there is no internet connection
    func testThrowsErrorWhenNoInternet() {
        MockURLProtocol.responseData = Data()
        MockURLProtocol.urlErrorCode = URLError.Code.notConnectedToInternet
        cancelable = NetworkManager(environment: TestMockAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    guard case .noInternetConnection = error else { XCTFail("Expected a no internet error"); return }
                    self.expectation.fulfill()
                case .finished:
                    break
                }
            }) { _ in }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    
    // MARK: - Refresh Tests
    
    /// test that the network call is still made succesfully if the refresh succeeds
    func testThatRefreshHappensWhenNoToken() {
        let data = try! encoder.encode(mockObject)
        MockURLProtocol.responseData = data

        let networkManager = NetworkManager(environment: expiredEnvironment)
        networkManager.defaultSession = session
        
        networkManager.request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    break
                case .finished:
                    break
                }
            }) { object in
                self.expectation.fulfill()
                self.expect(object, equals: self.mockObject)
            }
        .store(in: &subscribers)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testThatRefreshHappensOnlyOnceWhenNoToken() {
        let data = try! encoder.encode(mockObject)
        MockURLProtocol.responseData = data
        let environment = expiredEnvironment
        let networkManager = NetworkManager(environment: environment)
        networkManager.defaultSession = session
        
        networkManager.request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    break
                case .finished:
                    break
                }
            }) { object in
                self.expectation.fulfill()
                self.expect(object, equals: self.mockObject)
            }
        .store(in: &subscribers)
        
        let expectation1 = XCTestExpectation(description: self.debugDescription)
        networkManager.request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    break
                case .finished:
                    break
                }
            }) { object in
                expectation1.fulfill()
                self.expect(object, equals: self.mockObject)
            }
        .store(in: &subscribers)
        
        let expectation2 = XCTestExpectation(description: self.debugDescription)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            networkManager.request(self.fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure:
                        break
                    case .finished:
                        break
                    }
                }) { object in
                    expectation2.fulfill()
                    self.expect(object, equals: self.mockObject)
                }
                .store(in: &self.subscribers)
        }
        
        
        wait(for: [expectation, expectation1, expectation2], timeout: 5.0)
        expect(environment.refreshCount, equals: 1)
        expect(environment.queueCount, equals: 1)
        expect(environment.validTokenCount, equals: 1)
    }
    
    /// test that the correct error is thrown when refresh fails
    func testThatRefreshThrowsErrorWhenRefreshFails() {
        let environment = expiredEnvironment
        let networkManager = NetworkManager(environment: environment)
        networkManager.defaultSession = session
        environment.refreshSuccess = false
    
        cancelable = networkManager.request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    guard case .refreshFailed = error else { XCTFail("Expected refresh failed error"); return }
                    self.expectation.fulfill()
                case .finished:
                    break
                }
            }) { _ in }

        wait(for: [expectation], timeout: 5.0)
    }
    
    
    // MARK: - Adapter Tests
    
    /// Tests that the adapter adds the base url from the environment in front of the enpoint url
    func testThatAdapterAddsBaseURL() {
        let fakeBaseURLString = "www.baseurl.com/"
        let endpointURL = try! Router.MockObject.getObjects.path.asURL()
        let fakeEnvironment = FakeAPIEnvironment(protocolClass: MockURLProtocol.self, bearerToken: nil, refreshToken: nil, baseURL: URL(string: fakeBaseURLString))
        let network = NetworkManager(environment: fakeEnvironment)
        let adaptedRequest = network.adapt(Router.MockObject.getObjects.urlRequest!)
        expect(adaptedRequest.url!.absoluteString, equals: fakeBaseURLString + endpointURL.absoluteString)
    }
    
    /// Tests that on a post request that the application json header is added to the request
    func testPostRequestAddsApplicationJSONHeader() {
        let network = NetworkManager(environment: FakeAPIEnvironment())
        expect(fakePostRequest.httpMethod, equals: HTTPMethod.post.rawValue)
        let adaptedRequest = network.adapt(fakePostRequest)
        expect(adaptedRequest.allHTTPHeaderFields![NetworkKeys.contentTypeHeader], equals: NetworkKeys.applicationJSON)
    }
    
    
    // MARK: - Network Monitor Tests
    
    func testNetworkMonitorPath() {
        let fakeEnvironment = FakeAPIEnvironment()
        let network = NetworkManager(environment: fakeEnvironment)
        sleep(1)
        expect(notNil: network.networkPathState)
    }
    
}


// MARK: - Stress Tests

extension NetworkSpec {

    func testLargeNumberOfRequestsWithRefreshNeeded() {
        let data = try! encoder.encode(mockObject)
        MockURLProtocol.responseData = data

        let environment = expiredEnvironment
        let networkManager = NetworkManager(environment: environment)
        networkManager.defaultSession = session
                
        let requestCount = Int.random(in: 50...1000)
        let requests = Array(repeating: fakeGetRequest, count: requestCount)
        requests.publisher
            .flatMap { request in
                networkManager.request(request, responseAs: MockObject.self, decoder: JSONDecoder())
                    .receive(on: RunLoop.main)
                    
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    break
                case .finished:
                    break
                }
            }) { object in
                self.expectation.fulfill()
                self.expect(object, equals: self.mockObject)
            }
            .store(in: &subscribers)
        
        
        wait(for: [expectation], timeout: 5.0)
        expect(environment.refreshCount, equals: 1)
        expect(environment.queueCount, equals: requestCount - 1)
    }
    
    func testLargeNumberOfRequestsAfterOtherWithRefreshNeeded() {
        let data = try! encoder.encode(mockObject)
        MockURLProtocol.responseData = data

        let environment = expiredEnvironment
        let networkManager = NetworkManager(environment: environment)
        networkManager.defaultSession = session

        let requestCount = Int.random(in: 50...100)
        let requests = Array(repeating: fakeGetRequest, count: requestCount)
        requests.publisher
            .flatMap { request in
                networkManager.request(request, responseAs: MockObject.self, decoder: JSONDecoder())
                    .receive(on: RunLoop.main)
                    
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    break
                case .finished:
                    break
                }
            }) { object in
                self.expectation.fulfill()
                self.expect(object, equals: self.mockObject)
            }
            .store(in: &subscribers)
        
        let expectation1 = XCTestExpectation(description: self.debugDescription)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            requests.publisher
                .flatMap { request in
                    networkManager.request(request, responseAs: MockObject.self, decoder: JSONDecoder())
                        .receive(on: RunLoop.main)
                    
                }
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure:
                        break
                    case .finished:
                        break
                    }
                }) { object in
                    expectation1.fulfill()
                    self.expect(object, equals: self.mockObject)
                }
                .store(in: &self.subscribers)
        }
        
        wait(for: [expectation, expectation1], timeout: 5.0)
        expect(environment.refreshCount, equals: 1)
        expect(environment.queueCount, equals: requestCount - 1)
        expect(environment.validTokenCount, equals: requestCount)
    }
    
}


// MARK: - Async/Await tests

extension NetworkSpec {
    
    func testRefreshWithAsyncAwait() async throws {
        do {
            let environment = expiredEnvironment
            let token = try await environment.authToken()
            let token2 = try await environment.authToken()
            let token3 = try await environment.authToken()
            expect(token, equals: token2)
            expect(token, equals: token3)
        } catch {
            throw error
        }
    }
    
    /// test that it returns a decoded object on a successful request
    func testThatItReturnsASingleObject() async throws {
        let data = try! encoder.encode(mockObject)
        MockURLProtocol.responseData = data
        let network = NetworkManager(environment: TestMockAPIEnvironment())
        
        let object = try await network.request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
        expect(object, equals: mockObject)
    }
    
    /// test that it returns an array of decoded objects on a successful request
    func testThatItReturnsArrayOfObjects() async throws {
        let data = try! encoder.encode([mockObject])
        MockURLProtocol.responseData = data
        MockURLProtocol.responseData = data
        let network = NetworkManager(environment: TestMockAPIEnvironment())
        
        let object = try await network.request(fakeGetRequest, responseAs: [MockObject].self, decoder: JSONDecoder())
        expect(object, equals: [mockObject])
    }
    
    /// test that it will return a success if a post is called
    func testThatSuccessfullyPosts() async throws {
        let data = try! encoder.encode(mockObject)
        MockURLProtocol.responseData = data
        let network = NetworkManager(environment: TestMockAPIEnvironment())
        
        let object = try await network.request(fakePostRequest, responseAs: MockObject.self, decoder: JSONDecoder())
        expect(object, equals: mockObject)
    }
    
    
    // MARK: - Failure Tests
    
    /// test that it throws an error when no data returns
    func testThatItThrowsAnErrorWhenNoDataReturns() async throws {
        do {
            _ = try await NetworkManager(environment: TestMockAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
            XCTFail("Expected a network error")
        } catch {
            expect(notNil: error)
        }
    }
    
    func testThatItThrowsAValidationFailedWith400Response() async throws {
        MockURLProtocol.responseData = Data()
        MockURLProtocol.statusCode = 400
        do {
            _ = try await NetworkManager(environment: TestMockAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
            XCTFail("Expected a validationFailed error")
        } catch {
            expect(notNil: error)
        }
    }
    
    func testThatItThrowsUnsuccessfulRequestWithA500Response() async throws {
        MockURLProtocol.responseData = Data()
        MockURLProtocol.statusCode = 500
        do {
            _ = try await NetworkManager(environment: TestMockAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
            XCTFail("Expected a validationFailed error")
        } catch {
            print(error)
            guard case .decodingError(let err) = error as? APIError else { XCTFail("Expected a decoding error"); return }
            guard case .serverError(let output) = err as? APIError else { XCTFail("Expected a validationFailed error"); return }
            expect(output, equals: "HTTP/1.1 500 internal server error\n\n\n")
        }
    }
    
    /// test that it throws an error with invalid data
    func testThatItThrowsAnErrorWithErrorWhenDecodingData() async throws {
        MockURLProtocol.responseData = Data()
        do {
            _ = try await NetworkManager(environment: TestMockAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
            XCTFail("Expected a decoding error")
        } catch {
            print(error)
            guard case .decodingError(let err) = error as? APIError else { XCTFail("Expected a decoding error"); return }
            expect(notNil: err)
        }
    }
    
    /// test throws correct error when there is no internet connection
    func testThrowsErrorWhenNoInternet() async throws {
        MockURLProtocol.responseData = Data()
        MockURLProtocol.urlErrorCode = URLError.Code.notConnectedToInternet
        do {
            _ = try await NetworkManager(environment: TestMockAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self, decoder: JSONDecoder())
            XCTFail("Expected a no internet error")
        } catch {
            guard case .noInternetConnection = error as? APIError else { XCTFail("Expected a no internet error"); return }
            expect(notNil: error)
        }
    }
    
}
