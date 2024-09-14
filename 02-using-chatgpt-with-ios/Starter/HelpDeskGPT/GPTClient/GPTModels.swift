/// Copyright (c) 2024 Kodeco Inc.
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

/// Which GPT model to use when making endpoint calls.
/// * Prefer to use `.gpt35Turbo` as this is highly optimized and least expensive per call.
/// * Use `.gpt4Turbo` only when the latest-and-greatest and most recent event data is required, as it's the most expensive per call.
enum GPTModelVersion: String, Codable {
  /// Training data is up to Sep 2021
  case gpt35Turbo = "gpt-3.5-turbo"
  
  /// Training data is up to Oct 2023
  case gpt4o = "gpt-4o"
  
  /// Training data is up to Dec 2023
  case gpt4Turbo = "gpt-4-turbo"
}

struct GPTMessage: Codable, Hashable {
  let role: Role
  let content: String
  
  enum Role: String, Codable {
    case assistant
    case system
    case user
  }
}

extension Array where Element == GPTMessage {
  static func makeContext(_ contents: String...) -> [GPTMessage] {
    return contents.map { GPTMessage(role: .system, content: $0)}
  }
}

struct GPTChatRequest: Codable {
  let model: GPTModelVersion
  let messages: [GPTMessage]
  
  init(model: GPTModelVersion,
       messages: [GPTMessage]) {
    self.model = model
    self.messages = messages
  }
}

struct GPTChatResponse: Codable {
  let id: String  
  let created: Date
  let model: String
  let choices: [Choice]
  
  struct Choice: Codable {
    let message: GPTMessage
  }
}

enum GPTClientError: Error, CustomStringConvertible {
  case errorResponse(statusCode: Int, error: GPTErrorResponse?)
  case networkError(message: String? = nil, error: Error? = nil)
  
  var description: String {
    switch self {
    case .errorResponse(let statusCode, let error):
      return "GPTClientError.errorResponse: statusCode: \(statusCode), " +
      "error: \(String(describing: error))"
      
    case .networkError(let message, let error):
      return "GPTClientError.networkError: message: \(String(describing: message)), " +
      "error: \(String(describing: error))"
    }
  }
}

struct GPTErrorResponse: Codable {
  let error: ErrorDetail
  
  struct ErrorDetail: Codable {
    let message: String
    let type: String
    let param: String?
    let code: String?
  }
}
