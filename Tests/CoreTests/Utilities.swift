//
//  Utilities.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

import Foundation
import Testing

extension Data {
    /// Attemps to format the data as nicely formatted JSON.
    var prettyPrintedJSONString: NSString? { /// NSString gives us a nice sanitized debugDescription
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .withoutEscapingSlashes]
              ),
              let prettyPrintedString = NSString(
                data: data,
                encoding: String.Encoding.utf8.rawValue
              ) else {
            return nil
        }
        
        return prettyPrintedString
    }
}

enum CodingValidationError: Error {
    case invalidJSONString
    case jsonMismatch(expected: String, got: String)
    case invalidJSONStructure
}


/// Tests whether the provided object encodes to and decodes from the expected JSON representation
/// - Parameters:
///   - object: The object to test encoding and decoding
///   - expectedJSON: The JSON string that the object should encode to
func validateCoding<T: Codable>(
    of object: T,
    matchesJSON expectedJSON: String
) throws {
    
    // Encode the object
    let encoder = JSONEncoder()
    let encodedData = try encoder.encode(object)
    
    // Verify we can decode it back
    let decoder = JSONDecoder()
    let _ = try decoder.decode(T.self, from: encodedData)
    
    // Convert encoded data to dictionary
    guard let encodedJSON = try JSONSerialization.jsonObject(
        with: encodedData,
        options: []
    ) as? NSDictionary else {
        throw CodingValidationError.invalidJSONStructure
    }
    
    // Convert expected JSON string to data
    guard let expectedData = expectedJSON.data(using: .utf8) else {
        throw CodingValidationError.invalidJSONString
    }
    
    // Convert expected JSON to dictionary
    guard let expectedJSON = try JSONSerialization.jsonObject(
        with: expectedData,
        options: []
    ) as? NSDictionary else {
        throw CodingValidationError.invalidJSONStructure
    }
    
    // Compare the results
    #expect(encodedJSON == expectedJSON)
    }
