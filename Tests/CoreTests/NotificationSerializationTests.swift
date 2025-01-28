//
//  NotificationSerializationTests.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/28/25.
//


import Testing
import Foundation
@testable import MCPCore

struct NotificationSerializationTests {
    
    @Test func encodeCancelledNotification() throws {
        let notification = CancelledNotification(
            params: .init(requestID: "1234", reason: "Timeout")
        )
        let expectedJSON = """
    {
        "method": "notifications/cancelled",
        "params": {
            "requestId": "1234",
            "reason": "Timeout"
        }
    }
    """
        try validateCoding(of: notification, matchesJSON: expectedJSON)
    }
    
    @Test func encodeInitializedNotification() throws {
        let notification = InitializedNotification(
            params: .init()
        )
        let expectedJSON = """
    {
        "method": "notifications/initialized",
        "params": {}
    }
    """
        try validateCoding(of: notification, matchesJSON: expectedJSON)
    }

    @Test func encodeProgressNotification() throws {
        let notification = ProgressNotification(
            params: .init(progress: 0.5, progressToken: "token123", total: 1.0)
        )
        let expectedJSON = """
    {
        "method": "notifications/progress",
        "params": {
            "progress": 0.5,
            "progressToken": "token123",
            "total": 1.0
        }
    }
    """
        try validateCoding(of: notification, matchesJSON: expectedJSON)
    }

    @Test func encodeRootsListChangedNotification() throws {
        let notification = RootsListChangedNotification(
            params: .init()
        )
        let expectedJSON = """
    {
        "method": "notifications/roots/list_changed",
        "params": {}
    }
    """
        try validateCoding(of: notification, matchesJSON: expectedJSON)
    }

    @Test func encodeResourceListChangedNotification() throws {
        let notification = ResourceListChangedNotification(
            params: .init()
        )
        let expectedJSON = """
    {
        "method": "notifications/resources/list_changed",
        "params": {}
    }
    """
        try validateCoding(of: notification, matchesJSON: expectedJSON)
    }

    @Test func encodeResourceUpdatedNotification() throws {
        let notification = ResourceUpdatedNotification(
            params: .init(uri: "https://example.com/updatedResource")
        )
        let expectedJSON = """
    {
        "method": "notifications/resources/updated",
        "params": {
            "uri": "https://example.com/updatedResource"
        }
    }
    """
        try validateCoding(of: notification, matchesJSON: expectedJSON)
    }

    @Test func encodePromptListChangedNotification() throws {
        let notification = PromptListChangedNotification(
            params: .init()
        )
        let expectedJSON = """
    {
        "method": "notifications/prompts/list_changed",
        "params": {}
    }
    """
        try validateCoding(of: notification, matchesJSON: expectedJSON)
    }

    @Test func encodeToolListChangedNotification() throws {
        let notification = ToolListChangedNotification(
            params: .init()
        )
        let expectedJSON = """
    {
        "method": "notifications/tools/list_changed",
        "params": {}
    }
    """
        try validateCoding(of: notification, matchesJSON: expectedJSON)
    }

    @Test func encodeLoggingMessageNotification() throws {
        let notification = LoggingMessageNotification(
            params: .init(level: .info, data: "This is a log message", logger: "ServerLogger")
        )
        let expectedJSON = """
    {
        "method": "notifications/message",
        "params": {
            "level": "info",
            "data": "This is a log message",
            "logger": "ServerLogger"
        }
    }
    """
        try validateCoding(of: notification, matchesJSON: expectedJSON)
    }

}
