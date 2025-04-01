//
//  MCPClient+PendingRequest.swift
//  ModelContextProtocol
//
//  Created by Jake Sax on 3/23/25.
//

import Foundation
import MCPCore

extension MCPClient {
    
    protocol PendingRequestProtocol: Actor, Hashable, Sendable {
        /// The expected type of Result for the request.
        associatedtype RequestResult: Result
        
        /// The request that was made.
        nonisolated var request: ClientRequest { get }
        
        /// The ID of the request that was made.
        nonisolated var requestID: RequestID { get }
        
        /// The current state of the request.
        var state: RequestState { get }
        
        /// Attempts to complete the request with the provided response.
        func complete(withResponse response: JSONRPCResponse) throws
        
        /// Attempts to cancel the request, if possible.
        func cancel() throws
        
        /// Marks the request as failed with the provied error.
        func fail(withError error: Error)
    }
    
    // MARK: Data Structures
    /// The state of a request.
    public enum RequestState: Sendable, Equatable {
        case pending, completed, cancelled, failed(_ error: Error)
        
        public static func == (lhs: MCPClient.RequestState, rhs: MCPClient.RequestState) -> Bool {
            switch (lhs, rhs) {
            case (.pending, .pending),
                (.completed, .completed),
                (.cancelled, .cancelled),
                (.failed, .failed):
                true
            default:
                false
            }
        }
    }
    
}

extension MCPClient.PendingRequestProtocol {
    nonisolated var method: ClientRequest.Method { request.method }
}

extension MCPClient {
    
    actor PendingRequest<RequestResult: Result>: PendingRequestProtocol {
        
        // MARK: Properties
        nonisolated let request: ClientRequest
        nonisolated let requestID: RequestID
        private let continuation: CheckedContinuation<RequestResult, any Error>
        private(set) var timeoutTask: Task<Void, Error>?
        private(set) var state: RequestState
        
        // MARK: Initialization
        init<T: AnyClientRequest>(
            request: T,
            requestID: RequestID,
            continuation: CheckedContinuation<T.Result, any Error>,
            timeoutDuration: Duration
        ) where RequestResult == T.Result {
            self.request = request.clientRequest
            self.requestID = requestID
            self.state = .pending
            self.continuation = continuation
            self.timeoutTask = nil
            Task {
                await self.timeout(after: timeoutDuration)
            }
        }
        
        // MARK: Methods
        func complete(withResponse response: JSONRPCResponse) throws {
            switch state {
            case .pending: break
            case .completed: return
            case .cancelled: throw MCPClientError.requestWasCancelled(requestID)
            case .failed(let error): throw error
            }
            
            timeoutTask?.cancel()
            
            do {
                let result = try response.asResult(RequestResult.self)
                self.state = .completed
                continuation.resume(returning: result)
            } catch {
                self.state = .failed(error)
                continuation.resume(throwing: error)
                throw error
            }
        }
        
        func cancel() throws {
            switch state {
            case .pending: break
            case .completed: throw MCPClientError.cannotCancelRequest(
                reason: "Request already completed"
            )
            case .failed(let failureError): throw MCPClientError.cannotCancelRequest(
                reason: "Request already failed with error: \(failureError.localizedDescription)"
            )
            case .cancelled: return
            }
            
            timeoutTask?.cancel()
            self.state = .cancelled
            continuation.resume(throwing: CancellationError())
        }
        
        func fail(withError error: Error) {
            switch state {
            case .pending: break
            case .completed, .failed, .cancelled: return
            }
            
            timeoutTask?.cancel()
            self.state = .failed(error)
            continuation.resume(throwing: error)
        }
        
        private func timeout(after timeoutDuration: Duration) {
            self.timeoutTask = Task {
                try await Task.sleep(for: timeoutDuration)
                self.fail(
                    withError: TransportError.timeout(
                        operation: "id: \(requestID.description) method: \(request.request.method)"
                    )
                )
            }
        }
        
        // MARK: Protocol Conformance
        nonisolated func hash(into hasher: inout Hasher) {
            hasher.combine(requestID)
        }
        
        static func == (lhs: PendingRequest, rhs: PendingRequest) -> Bool {
            lhs.requestID == rhs.requestID
        }
        
    }
}

public extension MCPClient {
    func clearStaleRequests() async {
        let stillPendingRequests = await {
            var requests: [RequestID : any PendingRequestProtocol] = [:]
            for (id, request) in self.pendingRequests {
                if await request.state == .pending {
                    requests[id] = request
                }
            }
            return requests
        }()
        self.pendingRequests = stillPendingRequests
    }
    
    func stateOfRequest(withID requestID: RequestID) async -> RequestState? {
        await self.pendingRequests[requestID]?.state
    }
    
    func cancelRequest(withID requestID: RequestID) async throws {
        guard let pendingRequest: any PendingRequestProtocol = pendingRequests.removeValue(forKey: requestID) else {
            throw MCPClientError.unknownRequestID(requestID)
        }
        try await pendingRequest.cancel()
    }
}
