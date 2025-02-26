//
//  MCPClient+State.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 2/26/25.
//

import Foundation
import MCPCore

extension MCPClient {
    
    enum State: Equatable {
        /// Client is disconnected
        case disconnected
        
        /// Client is connecting
        case connecting
        
        /// Client's transport has connected and now is performing initialization
        case initializing
        
        /// Client is connected and running with negotiated capabilities
        case running(serverCapabilities: ServerCapabilities)
        
        /// Client has failed
        case failed(_ error: Error)
        
        var serverCapabilities: ServerCapabilities? {
            switch self {
            case .running(serverCapabilities: let capabilities): capabilities
            default: nil
            }
        }
        
        var isRunning: Bool {
            switch self{
            case .running(_): true
            default: false
            }
        }
        
        // MARK: Equatable Conformance
        public static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected),
                (.connecting, .connecting),
                (.initializing, .initializing),
                (.failed, .failed): // Don't compare errors, just that both are failed
                true
            case (
                .running(serverCapabilities: let lhsCapabilities),
                .running(serverCapabilities: let rhsCapabilities)
            ): lhsCapabilities == rhsCapabilities
            default:
                false
            }
        }
    }
}
