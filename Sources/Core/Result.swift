//
//  SharedResults.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 1/27/25.
//

/// A non-distinct result type that allows for additional metadata in responses. It must
/// reserve the key `_meta` to allow clients and servers to attach additional metadata
/// to their results/notifications.
public typealias Result = OldParameters

/// Empty result type
public typealias EmptyResult = Result
