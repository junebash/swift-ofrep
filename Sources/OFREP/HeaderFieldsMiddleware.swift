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

import Foundation
import HTTPTypes
import OpenAPIRuntime

/// Adds fixed header fields, such as `Authorization` or `X-API-Key`, to every request.
///
/// A field set here replaces any field of the same name already on the request.
struct HeaderFieldsMiddleware: ClientMiddleware {
    let headerFields: HTTPFields

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        for name in Set(headerFields.map(\.name)) {
            request.headerFields[name] = nil
        }
        request.headerFields.append(contentsOf: headerFields)
        return try await next(request, body, baseURL)
    }
}
