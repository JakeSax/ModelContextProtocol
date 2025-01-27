import Testing
@testable import MCPCore

@Test func jsonRPCCodability() async throws {
    let message = JSONRPCRequest(id: 5, method: "somemethod", params: ["someKey": "someValue"])
    
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
}
