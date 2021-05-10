//
//  XCTestCase+Matchers.swift
//  greatwork
//
//  Created by Tim on 4/14/17.
//  Copyright © 2017 OC Tanner Company, Inc. All rights reserved.
//
import Foundation
import XCTest

extension XCTestCase {
    
    // MARK: - Throws
    
    func shouldNotThrow(filePath: String = #filePath, line: Int = #line, _ block: () throws -> Void) {
        do {
            _ = try block()
        } catch {
            var issue = XCTIssue(type: .thrownError, compactDescription: "Should not have thrown an error")
            issue.associatedError = error
            issue.sourceCodeContext = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: filePath, lineNumber: line))
            record(issue)
        }
    }
    
    func shouldThrow(filePath: String = #filePath, line: Int = #line, _ block: () throws -> Void) {
        do {
            _ = try block()
            
            var issue = XCTIssue(type: .assertionFailure, compactDescription: "Should have thrown an error")
            issue.sourceCodeContext = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: filePath, lineNumber: line))
            record(issue)
        } catch {
        }
    }
    
    
    // MARK: - Equals
    
    func expect(nil expression: @autoclosure () -> Any?, filePath: String = #filePath, line: Int = #line) {
        if let it = expression() {
            var issue = XCTIssue(type: .assertionFailure, compactDescription: "Expected \(it) to be nil")
            issue.sourceCodeContext = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: filePath, lineNumber: line))
            record(issue)
        }
    }
    
    func expect(notNil expression: @autoclosure () -> Any?, filePath: String = #filePath, line: Int = #line) {
        if expression() == nil {
            var issue = XCTIssue(type: .assertionFailure, compactDescription: "Expected this NOT to be nil")
            issue.sourceCodeContext = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: filePath, lineNumber: line))
            record(issue)
        }
    }
    
    func expect(exists element: XCUIElement, filePath: String = #filePath, line: Int = #line) {
        if !element.exists {
            var issue = XCTIssue(type: .assertionFailure, compactDescription: "Expected \(element) to exist")
            issue.sourceCodeContext = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: filePath, lineNumber: line))
            record(issue)
        }
    }
    
    func expect(true expression: @autoclosure () -> Bool?, or otherExpression: @autoclosure () -> Bool?, filePath: String = #filePath, line: Int = #line) {
        var issue = XCTIssue(type: .assertionFailure, compactDescription: "Expected true")
        issue.sourceCodeContext = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: filePath, lineNumber: line))

        guard let actual = expression(), let otherActual = otherExpression() else {
            issue.compactDescription = "Expect 'nil' to be true"
            record(issue)
            return
        }
        if actual != true && otherActual != true {
            issue.compactDescription = "Expected this to be true"
            record(issue)
        }
    }
    
    func expect(doesNotExist element: XCUIElement, filePath: String = #filePath, line: Int = #line) {
        if element.exists {
            var issue = XCTIssue(type: .assertionFailure, compactDescription: "Expected \(element) to not exist")
            issue.sourceCodeContext = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: filePath, lineNumber: line))
            record(issue)
        }
    }

    func expect(false expression: @autoclosure () -> Bool?, filePath: String = #filePath, line: Int = #line) {
        var issue = XCTIssue(type: .assertionFailure, compactDescription: "Expected false")
        issue.sourceCodeContext = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: filePath, lineNumber: line))

        guard let actual = expression() else {
            issue.compactDescription = "Expected 'nil' to be false"
            record(issue)
            return
        }
        if actual != false {
            issue.compactDescription = "Expected this to be false"
            record(issue)
        }
    }
    
    func expect(true expression: @autoclosure () -> Bool?, filePath: String = #filePath, line: Int = #line) {
        var issue = XCTIssue(type: .assertionFailure, compactDescription: "Expected true")
        issue.sourceCodeContext = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: filePath, lineNumber: line))

        guard let actual = expression() else {
            issue.compactDescription = "Expect 'nil' to be true"
            record(issue)
            return
        }
        if actual != true {
            issue.compactDescription = "Expected this to be true"
            record(issue)
        }
    }
    
    func expect<T: Equatable>(_ this: @autoclosure () -> T?, equals expression: @autoclosure () -> T?, filePath: String = #filePath, line: Int = #line) {
        let actual = this()
        let expected = expression()
        if !equals(actual, expected) {
            var issue = XCTIssue(type: .assertionFailure, compactDescription: "Expected '\(String(describing: actual))' to equal '\(String(describing: expected))]")
            issue.sourceCodeContext = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: filePath, lineNumber: line))
            record(issue)
        }
    }
    
    func expect<T: Equatable>(_ this: @autoclosure () -> T?, notEquals expression: @autoclosure () -> T?, filePath: String = #filePath, line: Int = #line) {
        let actual = this()
        let expected = expression()
        if equals(actual, expected) {
            var issue = XCTIssue(type: .assertionFailure, compactDescription: "Expected '\(String(describing: actual))' to not equal '\(String(describing: expected))]")
            issue.sourceCodeContext = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: filePath, lineNumber: line))
            record(issue)
        }
    }
    
    func expect(date thisDate: Date?, equals thatDate: Date?, downToThe component: Calendar.Component = .second, filePath: String = #filePath, line: Int = #line) {
        var issue = XCTIssue(type: .assertionFailure, compactDescription: "Expected dates to be equal")
        issue.sourceCodeContext = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: filePath, lineNumber: line))

        guard let thisDate = thisDate, let thatDate = thatDate else {
            issue.compactDescription = "Expected dates to not be nil"
            record(issue)
            return
        }
        if !Calendar.current.isDate(thisDate, equalTo: thatDate, toGranularity: component) {
            issue.compactDescription = "Expected \(thisDate) to equal: \(thatDate)"
            record(issue)
        }
    }
    
    
    // MARK: - Contains
    
    func expect(_ actual: String, contains expected: String..., filePath: String = #filePath, line: Int = #line) {
        let result = expected.map { actual.contains($0) }
        if let index = result.firstIndex(of: false) {
            var issue = XCTIssue(type: .assertionFailure, compactDescription: "Expected '\(actual)' to contain '\(expected[index])'")
            issue.sourceCodeContext = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: filePath, lineNumber: line))
            record(issue)
        }
    }
    
    func expect(_ actual: String, doesNotContain expected: String..., filePath: String = #filePath, line: Int = #line) {
        let result = expected.map { actual.contains($0) }
        if let index = result.firstIndex(of: true) {
            var issue = XCTIssue(type: .assertionFailure, compactDescription: "Expected '\(actual)' to not contain '\(expected[index])'")
            issue.sourceCodeContext = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: filePath, lineNumber: line))
            record(issue)
        }
    }
    
    
    // MARK: - Async
    
    typealias AsyncExecution = () -> Void
    fileprivate static var defaultTimeout: TimeInterval { return 10.0 }
    
    func async(description: String = "Waiting", _ block: (AsyncExecution) -> Void) {
        let waiter = expectation(description: description)
        block {
            waiter.fulfill()
        }
        wait(for: [waiter], timeout: 5)
    }
    
    func expectEventually(nil expression: @autoclosure @escaping () -> Any?, timeout: TimeInterval = XCTestCase.defaultTimeout, filePath: String = #filePath, line: Int = #line) {
        let expected = expectation { () -> Bool in
            return expression() == nil
        }
        
        wait(for: "this", toEventually: "be nil", timeout: timeout, with: [expected], filePath: filePath, line: line)
    }
    
    func expectEventually(notNil expression: @autoclosure @escaping () -> Any?, timeout: TimeInterval = XCTestCase.defaultTimeout, filePath: String = #filePath, line: Int = #line) {
        let expected = expectation { () -> Bool in
            return expression() != nil
        }
        
        wait(for: "this", toEventually: "not be nil", timeout: timeout, with: [expected], filePath: filePath, line: line)
    }
    
    func expectEventually(exists element: XCUIElement, timeout: TimeInterval = XCTestCase.defaultTimeout, filePath: String = #filePath, line: Int = #line) {
        if !element.waitForExistence(timeout: timeout) {
            expect(exists: element, filePath: filePath, line: line)
        }
    }
    
    func expectEventually(doesNotExist element: XCUIElement, timeout: TimeInterval = XCTestCase.defaultTimeout, filePath: String = #filePath, line: Int = #line) {
        let expected = expectation { () -> Bool in
            return !element.exists
        }
        
        wait(for: element.description, toEventually: "not exist", timeout: timeout, with: [expected], filePath: filePath, line: line)
    }
    
    func expectEventually(false expression: @autoclosure @escaping () -> Bool, timeout: TimeInterval = XCTestCase.defaultTimeout, filePath: String = #filePath, line: Int = #line) {
        let expected = expectation { () -> Bool in
            return expression() == false
        }
        
        wait(for: "this", toEventually: "be false", timeout: timeout, with: [expected], filePath: filePath, line: line)
    }
    
    func expectEventually(true expression: @autoclosure @escaping () -> Bool, timeout: TimeInterval = XCTestCase.defaultTimeout, filePath: String = #filePath, line: Int = #line) {
        let expected = expectation { () -> Bool in
            return expression() == true
        }
        
        wait(for: "this", toEventually: "be true", timeout: timeout, with: [expected], filePath: filePath, line: line)
    }
    
    func expectEventually<T: Equatable>(_ this: @autoclosure @escaping () -> T, equals expression: @autoclosure @escaping () -> T, timeout: TimeInterval = XCTestCase.defaultTimeout, filePath: String = #filePath, line: Int = #line) {
        var lastActual = this()
        var lastExpected = expression()
        guard lastActual != lastExpected else { return }
        
        let expected = expectation { () -> Bool in
            lastActual = this()
            lastExpected = expression()
            return lastActual == lastExpected
        }
        
        wait(for: "'\(lastActual)'", toEventually: "equal '\(lastExpected)'", timeout: timeout, with: [expected], filePath: filePath, line: line)
    }
    
    func expectEventually<T: Equatable>(_ this: @autoclosure @escaping () -> T?, equals expression: @autoclosure @escaping () -> T, timeout: TimeInterval = XCTestCase.defaultTimeout, filePath: String = #filePath, line: Int = #line) {
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
        wait(for: "'\(actualString)'", toEventually: "equal '\(lastExpected)'", timeout: timeout, with: [expected], filePath: filePath, line: line)
    }
    
    private func equals<T: Equatable>(_ lhs: T?, _ rhs: T?) -> Bool {
        if lhs == nil && rhs == nil {
            return true
        }
        guard let actual = lhs, let expected = rhs else {
            return false
        }
        return actual == expected
    }
    
    private func expectation(from block: @escaping () -> Bool) -> XCTestExpectation {
        let predicate = NSPredicate { _, _ -> Bool in
            return block()
        }
        let expected = expectation(for: predicate, evaluatedWith: NSObject())
        return expected
    }
    
    // swiftlint:disable:next function_parameter_count
    private func wait(for subject: String, toEventually outcome: String, timeout: TimeInterval, with expectations: [XCTestExpectation], filePath: String, line: Int) {
        let result = XCTWaiter().wait(for: expectations, timeout: timeout)
        
        var issue = XCTIssue(type: .assertionFailure, compactDescription: "Timeout occurred")
        issue.sourceCodeContext = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: filePath, lineNumber: line))

        switch result {
        case .completed:
            return
        case .timedOut:
            issue.compactDescription = "Expected \(subject) to eventually \(outcome). Timed out after \(timeout)s."
            record(issue)
        default:
            issue.compactDescription = "Unexpected result while waiting for \(subject) to eventually \(outcome): \(result)"
            record(issue)
        }
    }
    
}
