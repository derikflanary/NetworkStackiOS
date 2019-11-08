//
//  XCTestCase+Extensions.swift
//  network-combineTests
//
//  Created by Derik Flanary on 11/7/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation
import XCTest


extension XCTestCase {

    // MARK: - Throws

    func shouldNotThrow(file: String = #file, line: Int = #line, _ block: () throws -> Void) {
        do {
            _ = try block()
        } catch {
            recordFailure(withDescription: "Boo! \(error)", inFile: file, atLine: line, expected: true)
        }
    }

    func shouldThrow(file: String = #file, line: Int = #line, _ block: () throws -> Void) {
        do {
            _ = try block()
            recordFailure(withDescription: "Should have thrown!", inFile: file, atLine: line, expected: true)
        } catch {
        }
    }

    func expectNoError(_ expression: @autoclosure () -> Error?, file: String = #file, line: Int = #line) {
        if let it = expression() {
            recordFailure(withDescription: "Unexpected error: '\(it)'", inFile: file, atLine: line, expected: true)
        }
    }


    // MARK: - Equals

    func expect(nil expression: @autoclosure () -> Any?, file: String = #file, line: Int = #line) {
        if let it = expression() {
            recordFailure(withDescription: "Expected '\(it)' to be nil.", inFile: file, atLine: line, expected: true)
        }
    }

    func expect(notNil expression: @autoclosure () -> Any?, file: String = #file, line: Int = #line) {
        if expression() == nil {
            recordFailure(withDescription: "Expected this not to be nil.", inFile: file, atLine: line, expected: true)
        }
    }

    func expect(false expression: @autoclosure () -> Bool, file: String = #file, line: Int = #line) {
        let actual = expression()
        if actual != false {
            recordFailure(withDescription: "Expected this to be false.", inFile: file, atLine: line, expected: true)
        }
    }

    func expect(true expression: @autoclosure () -> Bool, file: String = #file, line: Int = #line) {
        let actual = expression()
        if actual != true {
            recordFailure(withDescription: "Expected this to be true.", inFile: file, atLine: line, expected: true)
        }
    }

    func expect<T: Equatable>(_ this: @autoclosure () -> T, equals expression: @autoclosure () -> T, file: String = #file, line: Int = #line) {
        let actual = this()
        let expected = expression()
        if actual != expected {
            recordFailure(withDescription: "Expected '\(actual)' to equal '\(expected)]", inFile: file, atLine: line, expected: true)
        }
    }

    func expect<T: Equatable>(_ this: @autoclosure () -> T?, equals expression: @autoclosure () -> T, file: String = #file, line: Int = #line) {
        guard let actual = this() else {
            recordFailure(withDescription: "Expected 'nil' to equal '\(expression())'", inFile: file, atLine: line, expected: true)
            return
        }
        expect(actual, equals: expression(), file: file, line: line)
    }

    func expect(_ this: @autoclosure () -> [String: Any]?, equals expression: @autoclosure () -> [String: Any], file: String = #file, line: Int = #line) {
        guard let actual = this() else {
            recordFailure(withDescription: "Expected 'nil' to equal '\(expression())'", inFile: file, atLine: line, expected: true)
            return
        }
        let actualDictionary = NSDictionary(dictionary: actual)
        let expected = expression()
        if !actualDictionary.isEqual(to: expected) {
            recordFailure(withDescription: "Expected '\(actual)' to equal '\(expected)]", inFile: file, atLine: line, expected: true)
        }
    }

    // MARK: - Async

    typealias AsyncExecution = () -> Void

    func async(description: String = "Waiting", _ block: (AsyncExecution) -> Void) {
        let waiter = expectation(description: description)
        block {
            waiter.fulfill()
        }
        wait(for: [waiter], timeout: 5)
    }

    func eventually(nil expression: @autoclosure @escaping () -> Any?, file: String = #file, line: Int = #line) {
        let expected = expectation { () -> Bool in
            return expression() == nil
        }

        wait(for: "this", toEventually: "be nil", with: [expected], file: file, line: line)
    }

    func eventually(notNil expression: @autoclosure @escaping () -> Any?, file: String = #file, line: Int = #line) {
        let expected = expectation { () -> Bool in
            return expression() != nil
        }

        wait(for: "this", toEventually: "not be nil", with: [expected], file: file, line: line)
    }

    func eventually(false expression: @autoclosure @escaping () -> Bool, file: String = #file, line: Int = #line) {
        let expected = expectation { () -> Bool in
            return expression() == false
        }

        wait(for: "this", toEventually: "be false", with: [expected], file: file, line: line)
    }

    func eventually(true expression: @autoclosure @escaping () -> Bool, file: String = #file, line: Int = #line) {
        let expected = expectation { () -> Bool in
            return expression() == true
        }

        wait(for: "this", toEventually: "be true", with: [expected], file: file, line: line)
    }

    func never(true expression: @autoclosure @escaping () -> Bool, file: String = #file, line: Int = #line) {
        let expected = expectation { () -> Bool in
            return expression() == true
        }
        expected.isInverted = true

        wait(for: "this", toEventually: "be true", timeout: 2.0, with: [expected], file: file, line: line)
    }

    func eventually<T: Equatable>(_ this: @autoclosure @escaping () -> T, equals expression: @autoclosure @escaping () -> T, file: String = #file, line: Int = #line) {
        var lastActual = this()
        var lastExpected = expression()
        guard lastActual != lastExpected else { return }

        let expected = expectation { () -> Bool in
            lastActual = this()
            lastExpected = expression()
            return lastActual == lastExpected
        }

        wait(for: "'\(lastActual)'", toEventually: "equal '\(lastExpected)'", with: [expected], file: file, line: line)
    }

    func eventually<T: Equatable>(_ this: @autoclosure @escaping () -> T?, equals expression: @autoclosure @escaping () -> T, file: String = #file, line: Int = #line) {
        var lastActual = this()
        var lastExpected = expression()
        guard let actual = lastActual, actual == lastExpected else { return }

        let expected = expectation { () -> Bool in
            lastActual = this()
            lastExpected = expression()
            guard let actual = lastActual else { return false }
            return actual == lastExpected
        }

        let actualString = (lastActual == nil) ? "nil" : "\(lastActual!)"
        wait(for: "'\(actualString)'", toEventually: "equal '\(lastExpected)'", with: [expected], file: file, line: line)
    }

    private func expectation(from block: @escaping () -> Bool) -> XCTestExpectation {
        let predicate = NSPredicate { _, _ -> Bool in
            return block()
        }
        let expected = expectation(for: predicate, evaluatedWith: NSObject())
        return expected
    }

    private func wait(for subject: String, toEventually outcome: String, timeout: TimeInterval = 15.0, with expectations: [XCTestExpectation], file: String, line: Int) {
        let result = XCTWaiter().wait(for: expectations, timeout: timeout)

        switch result {
        case .completed:
            return
        case .timedOut:
            self.recordFailure(withDescription: "Expected \(subject) to eventually \(outcome). Timed out after \(timeout)s.", inFile: file, atLine: line, expected: true)
        case .invertedFulfillment:
            self.recordFailure(withDescription: "Expected \(subject) to never \(outcome) within \(timeout)s.", inFile: file, atLine: line, expected: true)
        default:
            self.recordFailure(withDescription: "Unexpected result while waiting for \(subject) to eventually \(outcome): \(result)", inFile: file, atLine: line, expected: false)
        }
    }

}
