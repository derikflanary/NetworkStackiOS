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

    
    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()
        cancelable = nil
        MockURLProtocol.responseData = nil
        MockURLProtocol.urlErrorCode = nil
        MockURLProtocol.statusCode = 200
    }
    
    
    // MARK: - Failure Tests
    
    /// test that it throws an error when no data returns
    func testThatItThrowsAnErrorWhenNoDataReturns() {
        cancelable = Network(environment: FakeAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    self.expectation.fulfill()
                    guard let error = error as? APIError else { XCTFail("Expected a APIError error"); return }
                    guard case .networkError(let err) = error else { XCTFail("Expected a network error"); return }
                    self.expect(notNil: err)
                case .finished:
                    break
                }
            }) { _ in }
        
        wait(for: [expectation], timeout: 12.0)
    }
    
    func testThatItThrowsAValidationFailedWith400Response() {
        MockURLProtocol.responseData = Data()
        MockURLProtocol.statusCode = 400
        cancelable = Network(environment: FakeAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    guard let error = error as? APIError else { XCTFail("Expected a APIError error"); return }
                    guard case .validationFailed(_) = error else { XCTFail("Expected a validationFailed error"); return }
                    self.expectation.fulfill()
                case .finished:
                    break
                }
            }) { _ in }
        
        wait(for: [expectation], timeout: 12.0)
    }
    
    /// test that it return nil when an error is thrown
    func testThatItReturnsNilWithError() {
        cancelable = Network(environment: FakeAPIEnvironment()).requestIgnoringError(fakeGetRequest, responseAs: MockObject.self)
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

        wait(for: [expectation], timeout: 12.0)
    }
    
    /// test that it throws an error with invalid data
    func testThatItThrowsAnErrorWithErrorWhenDecodingData() {
        MockURLProtocol.responseData = Data()
        cancelable = Network(environment: FakeAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    guard let error = error as? APIError else { XCTFail("Expected a APIError error"); return }
                    guard case .decodingError(let err) = error else { XCTFail("Expected a decoding error"); return }
                    self.expectation.fulfill()
                    self.expect(notNil: err)
                case .finished:
                    break
                }
            }) { _ in }
        
        wait(for: [expectation], timeout: 12.0)
    }
    
    /// test throws correct error when there is no internet connection
    func testThrowsErrorWhenNoInternet() {
        MockURLProtocol.responseData = Data()
        MockURLProtocol.urlErrorCode = URLError.Code.notConnectedToInternet
        cancelable = Network(environment: FakeAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    guard let error = error as? APIError else { XCTFail("Expected a APIError error"); return }
                    guard case .noInternetConnection = error else { XCTFail("Expected a no internet error"); return }
                    self.expectation.fulfill()
                case .finished:
                    break
                }
            }) { _ in }
        
        wait(for: [expectation], timeout: 12.0)
    }
    
    
    // MARK: - Success Tests
    
    /// test that it returns a decoded object on a successful request
    func testThatItReturnsArrayOfObjects() {
        let data = try! encoder.encode([mockObject])
        MockURLProtocol.responseData = data
        
        cancelable = Network(environment: FakeAPIEnvironment()).request(fakeGetRequest, responseAs: [MockObject].self)
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

        wait(for: [expectation], timeout: 12.0)
    }
    
    /// test that it returns a decoded object on a successful request
    func testThatItReturnsArrayASingleObject() {
        let data = try! encoder.encode(mockObject)
        MockURLProtocol.responseData = data
        
        cancelable = Network(environment: FakeAPIEnvironment()).request(fakeGetRequest, responseAs: MockObject.self)
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
        
        wait(for: [expectation], timeout: 12.0)
    }

    
    /// test that it return the decoded object and not nil
    func testThatItReturnsObjectAndNotNil() {
        let data = try! encoder.encode(mockObject)
        MockURLProtocol.responseData = data
        
        cancelable = Network(environment: FakeAPIEnvironment()).requestIgnoringError(fakeGetRequest, responseAs: MockObject.self)
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
        
        wait(for: [expectation], timeout: 12.0)
    }
    
    /// test that it will return a success if a post is called
    func testThatSucessfullyPosts() {
        let data = try! encoder.encode(mockObject)
            MockURLProtocol.responseData = data
            
            cancelable = Network(environment: FakeAPIEnvironment()).requestIgnoringError(fakePostRequest, responseAs: MockObject.self)
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
        wait(for: [expectation], timeout: 12.0)
    }
    
    /// test that a subscription will cancel successfully
    func testSubscriptionCancelsSuccessfully() {
        cancelable = Network(environment: FakeAPIEnvironment()).requestIgnoringError(fakePostRequest, responseAs: MockObject.self)
            .handleEvents(receiveCancel: {
                self.expectation.fulfill()
            })
            .sink(receiveCompletion: { completion in }) { _ in }
        
        cancelable!.cancel()
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    // MARK: - Adapter Tests
    
    /// Tests that the adapter adds the base url from the environment in front of the enpoint url
    func testThatAdapterAddsBaseURL() {
        let fakeBaseURLString = "www.baseurl.com/"
        let endpointURL = try! Router.MockObject.getObjects.path.asURL()
        let fakeEnvironment = FakeAPIEnvironment(protocolClass: MockURLProtocol.self, bearerToken: nil, refreshToken: nil, baseURL: URL(string: fakeBaseURLString))
        let network = Network(environment: fakeEnvironment)
        let adaptedRequest = network.adapt(Router.MockObject.getObjects.urlRequest!)
        expect(adaptedRequest.url!.absoluteString, equals: fakeBaseURLString + endpointURL.absoluteString)
    }
    
    /// Tests that on a post request that the application json header is added to the request
    func testPostRequestAddsApplicationJSONHeader() {
        let network = Network(environment: FakeAPIEnvironment())
        expect(fakePostRequest.httpMethod, equals: HTTPMethod.post.rawValue.uppercased())
        let adaptedRequest = network.adapt(fakePostRequest)
        expect(adaptedRequest.allHTTPHeaderFields![NetworkKeys.contentTypeHeader], equals: NetworkKeys.applicationJSON)
    }
    
}


