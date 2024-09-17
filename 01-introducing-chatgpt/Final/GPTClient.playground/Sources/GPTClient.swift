import Foundation

public class GPTClient {
  
  public var model: GPTModelVersion
  public var context: [GPTMessage]
  
  private let apiKey: String
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let urlSession: URLSession
  
  public init(apiKey: String,
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
