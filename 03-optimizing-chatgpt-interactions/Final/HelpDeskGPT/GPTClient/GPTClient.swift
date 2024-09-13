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
/// merger, ation, distribution, sublicensing, creation of derivative works,
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

class GPTClient {
  
  var model: GPTModelVersion
  var context: [GPTMessage]
  
  private let apiKey: String
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let urlSession: URLSession
  
  init(apiKey: String = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "MISSING API KEY",
       model: GPTModelVersion,
       context: [GPTMessage] = [],
       urlSession: URLSession = .shared) {
    self.apiKey = apiKey
    self.model = model
    self.context = context
    self.urlSession = urlSession
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    self.decoder = decoder
    
    self.encoder = JSONEncoder()
  }
  
  private func requestFor(url: URL, httpMethod: String, httpBody: Data?) -> URLRequest {
    var request = URLRequest(url: url)
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.cachePolicy = .reloadIgnoringLocalCacheData
    request.httpMethod = "POST"
    request.httpBody = httpBody
    return request
  }
  
  public func sendChats(_ chats: [GPTMessage]) async throws -> GPTChatResponse {
    do {
      let chatRequest = GPTChatRequest(model: model, messages: context + chats)
      return try await sendChatRequest(chatRequest)
      
    } catch let error as GPTClientError {
      throw error
    } catch {
      throw GPTClientError.networkError(error: error)
    }
  }

  private func sendChatRequest(_ chatRequest: GPTChatRequest) async throws -> GPTChatResponse {
    let data = try encoder.encode(chatRequest)
    
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    let request = requestFor(url: url, httpMethod: "POST", httpBody: data)
    
    let (responseData, urlResponse) = try await urlSession.data(for: request)
    guard let httpResponse = urlResponse as? HTTPURLResponse else {
      throw GPTClientError.networkError(message: "URLResponse is not an HTTPURLResponse")
    }
    guard httpResponse.statusCode == 200 else {
      let errorResponse = try? decoder.decode(GPTErrorResponse.self, from: responseData)
      throw GPTClientError.errorResponse(statusCode: httpResponse.statusCode, error: errorResponse)
    }
        
    let chatResponse = try decoder.decode(GPTChatResponse.self, from: responseData)
    return chatResponse
  }
}
