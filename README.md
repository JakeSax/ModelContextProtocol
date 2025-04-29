# A Swift Package for the Model Context Protocol

[![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%2013+%20|%20iOS%2016+-lightgray.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

This was something I was working on, but there is now [an official Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) so I can only recommend to use the official version. This package will no longer be maintained or developed, though I would mention that it does have some nice ergonomics + quality of life features that could be integrated into the official SDK.


ModelContextProtocol was an under-development Swift 6.0 implementation of Anthropic's [Model Context Protocol (MCP)](https://spec.modelcontextprotocol.io), with the goal of providing an easy-to-use, pluggable Swift Package for MCP use across macOS, iOS, + Linux. 

The package is split into three components:
1. MCPCore: The core data types and functionality shared between the MCPClient and MCPServer.
2. MCPClient: A relatively simple implementation for an MCPClient.
3. MCPServer: An interface for a server to provide MCP functionality.

## Features

- 🏃 **Modern Swift Concurrency** - Built with Swift 6.0, leveraging actors, async/await, + Sendable
- 🔒 **Type-Safe** - Full type safety for all MCP messages and operations
- 🔌 **Multiple Transports** - Support for stdio and Server-Sent Events (SSE)
- ⚡️ **Performance** - Efficient message handling with timeout and retry support
- 🛠 **Rich Capabilities** - Support for resources, prompts, tools, and more
- 📦 **SwiftPM Ready** - Easy integration through Swift Package Manager

## Contributing

1. Read the [MCP Specification](https://spec.modelcontextprotocol.io)
2. Fork the repository
3. Create a feature branch
4. Add tests for new functionality
5. Submit a pull request

## Limitations

- StdioTransport does not work in sandboxed environments
