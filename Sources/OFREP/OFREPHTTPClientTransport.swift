//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OpenFeature open source project
//
// Copyright (c) 2025 the Swift OpenFeature project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import AsyncHTTPClient
import Foundation
import HTTPTypes
import Logging
import NIOCore
import OpenAPIAsyncHTTPClient
import OpenAPIRuntime

struct OFREPHTTPClientTransport: OFREPClientTransport {
    let transport: AsyncHTTPClientTransport
    let shouldShutDownHTTPClient: Bool

    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (
        HTTPResponse,
        HTTPBody?
    ) {
        try await transport.send(request, body: body, baseURL: baseURL, operationID: operationID)
    }

    func shutdownGracefully() async throws {
        guard shouldShutDownHTTPClient else { return }
        try await transport.configuration.client.shutdown()
    }

    static let loggingDisabled = Logger(label: "OFREP-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() })
}

extension OFREPProvider<OFREPHTTPClientTransport> {
    /// - Parameters:
    ///   - serverURL: The OFREP server's base URL.
    ///   - headerFields: Sent with every request. Use it for credentials, e.g.
    ///     `[.authorization: "Bearer <token>"]` or `[HTTPField.Name("X-API-Key")!: "<key>"]`.
    ///   - httpClient: The HTTP client to send requests with.
    ///   - timeout: How long to wait for each request.
    public init(
        serverURL: URL,
        headerFields: HTTPFields = [:],
        httpClient: HTTPClient = .shared,
        timeout: Duration = .seconds(60)
    ) {
        self.init(
            serverURL: serverURL,
            headerFields: headerFields,
            transport: AsyncHTTPClientTransport(
                configuration: AsyncHTTPClientTransport.Configuration(
                    client: httpClient,
                    timeout: TimeAmount(timeout)
                )
            )
        )
    }

    /// - Parameters:
    ///   - serverURL: The OFREP server's base URL.
    ///   - headerFields: Sent with every request. Use it for credentials, e.g.
    ///     `[.authorization: "Bearer <token>"]` or `[HTTPField.Name("X-API-Key")!: "<key>"]`.
    public init(
        serverURL: URL,
        headerFields: HTTPFields = [:],
        configuration: HTTPClient.Configuration,
        eventLoopGroup: EventLoopGroup = HTTPClient.defaultEventLoopGroup,
        backgroundActivityLogger: Logger? = nil,
        timeout: Duration = .seconds(60)
    ) {
        let httpClient = HTTPClient(
            eventLoopGroupProvider: .shared(eventLoopGroup),
            configuration: configuration,
            backgroundActivityLogger: backgroundActivityLogger ?? OFREPHTTPClientTransport.loggingDisabled
        )
        let httpClientTransport = AsyncHTTPClientTransport(
            configuration: AsyncHTTPClientTransport.Configuration(
                client: httpClient,
                timeout: TimeAmount(timeout)
            )
        )
        self.init(
            serverURL: serverURL,
            headerFields: headerFields,
            transport: OFREPHTTPClientTransport(transport: httpClientTransport, shouldShutDownHTTPClient: true)
        )
    }

    package init(serverURL: URL, headerFields: HTTPFields = [:], transport: AsyncHTTPClientTransport) {
        self.init(
            serverURL: serverURL,
            headerFields: headerFields,
            transport: OFREPHTTPClientTransport(transport: transport, shouldShutDownHTTPClient: false)
        )
    }
}
