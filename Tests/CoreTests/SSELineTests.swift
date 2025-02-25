//
//  SSELineTests.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/25/25.
//

import Foundation
import Testing
@testable import MCPCore

@Suite("SSELine Tests")
struct SSELineTests {
    
    @Test("Parse empty line")
    func parseEmptyLine() {
        #expect(SSELine.parse("") == .empty)
    }
    
    @Test(
        "Parse event line",
        arguments: [
            ("event:message", "message"),
            ("event: message", "message"),
            ("event:  message  ", "message")
        ]
    )
    func parseEventLine(input: String, expected: String) {
        let parsed = SSELine.parse(input)
        #expect(parsed == .event(expected))
    }
    
    @Test(
        "Parse data line",
        arguments: [
            "data:hello",
            "data: hello",
            "data:  hello  "
        ]
    )
    func parseDataLine(input: String) {
        let parsed = SSELine.parse(input)
        guard case .data(let data) = parsed else {
            Issue.record("Expected .data case but got \(parsed)")
            return
        }
        
        guard let str = String(data: data, encoding: .utf8) else {
            Issue.record("Could not convert data to string")
            return
        }
        
        // Extract expected content by removing "data:" prefix and trimming
        let expected = input.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
        #expect(str == expected)
    }
    
    @Test(
        "Parse id line",
        arguments: [
            ("id:123", "123"),
            ("id: 123", "123"),
            ("id:  123  ", "123")
        ]
    )
    func testParseIdLine(input: String, expected: String) {
        let parsed = SSELine.parse(input)
        #expect(parsed == .id(expected))
    }
    
    @Test(
        "Parse retry line",
        arguments: [
            ("retry:1000", 1000),
            ("retry: 1000", 1000),
            ("retry:  1000  ", 1000)
        ]
    )
    func testParseRetryLine(input: String, expected: Int) {
        let parsed = SSELine.parse(input)
        #expect(parsed == .retry(milliseconds: expected))
    }
    
    @Test(
        "Parse comment line",
        arguments: [
            (":comment", "comment"),
            (": comment", "comment"),
            (":  comment  ", "comment")
        ]
    )
    func testParseCommentLine(input: String, expected: String) {
        let parsed = SSELine.parse(input)
        #expect(parsed == .comment(expected))
    }
    
    @Test(
        "Parse unknown line",
        arguments: [
            "foo:bar",
            "randomtext",
            "retry: notanumber"
        ]
    )
    func testParseUnknownLine(input: String) {
        let parsed = SSELine.parse(input)
        guard case .unknown(let content) = parsed else {
            Issue.record("Expected .unknown case but got \(parsed)")
            return
        }
        #expect(content == input)
    }
    
    struct NonAsciiTestCase {
        let input: String
        let expected: String
        let type: String // "data", "event", or "id"
    }
    
    @Test(
        "Test non-ASCII characters",
        arguments: [
            NonAsciiTestCase(input: "data: 你好", expected: "你好", type: "data"),
            NonAsciiTestCase(input: "event: événement", expected: "événement", type: "event"),
            NonAsciiTestCase(input: "id: id€£¥", expected: "id€£¥", type: "id")
        ]
    )
    func testNonAsciiCharacters(testCase: NonAsciiTestCase) {
        let parsed = SSELine.parse(testCase.input)
        
        switch parsed {
        case .data(let data):
            guard let str = String(data: data, encoding: .utf8) else {
                Issue.record("Could not convert data to string")
                return
            }
            #expect(str == testCase.expected)
            #expect(testCase.type == "data")
        case .event(let event):
            #expect(event == testCase.expected)
            #expect(testCase.type == "event")
        case .id(let id):
            #expect(id == testCase.expected)
            #expect(testCase.type == "id")
        default:
            Issue.record("Unexpected case: \(parsed)")
        }
    }
    
    struct ToStringTestCase: Sendable {
        let line: SSELine
        let expected: String
    }
    
    @Test(
        "Test toString conversion",
        arguments: [
            (SSELine.empty, ""),
            (SSELine.event("message"), "event: message"),
            (SSELine.data("hello".data(using: .utf8)!), "data: hello"),
            (SSELine.id("123"), "id: 123"),
            (SSELine.retry(milliseconds: 1000), "retry: 1000"),
            (SSELine.comment("keepalive"), ": keepalive"),
            (SSELine.unknown("some:weird:format"), "some:weird:format")
        ]
    )
    func testToString(line: SSELine, expected: String) {
        #expect(line.toString() == expected)
    }
    
    @Test(
        "Test roundtrip conversion",
        arguments: [
            "event: message",
            "data: {\"key\":\"value\"}",
            "id: 123",
            "retry: 1000",
            ": keepalive"
        ]
    )
    func testRoundtripConversion(original: String) {
        let parsed = SSELine.parse(original)
        let regenerated = parsed.toString()
        #expect(regenerated == original)
    }
}
