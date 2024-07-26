import Foundation

public enum GPTModelVersion: String, Codable {
  case gpt35Turbo = "gpt-3.5-turbo"
  case gpt4Turbo = "gpt-4-turbo"
  case gpt4o = "gpt-4o"
}

public struct GPTMessage: Codable, Hashable {
  public let role: Role
  public let content: String
  
  public init(role: Role, content: String) {
    self.role = role
    self.content = content
  }
  
  public enum Role: String, Codable {
    case assistant
    case system
    case user
  }
}

public extension Array where Element == GPTMessage {
  static func makeContext(_ contents: String...) -> [GPTMessage] {
    return contents.map { GPTMessage(role: .system, content: $0)}
  }
}

struct GPTChatRequest: Codable {
  let model: GPTModelVersion
  let messages: [GPTMessage]
  
  // These are optional properties
  let n: Int
  let temperature: Float?
  let top_p: Float?
  let stream: Bool?
  let stop: [String]?
  let max_tokens: Int?
  let presence_penalty: Float?
  let frequency_penalty: Float?
  let logit_bias: [String: Float]?
  let user: String?
  
  init(model: GPTModelVersion,
       messages: [GPTMessage],
       n: Int = 1,
       temperature: Float? = nil,
       top_p: Float? = nil,
       stream: Bool? = nil,
       stop: [String]? = nil,
       max_tokens: Int? = nil,
       presence_penalty: Float? = nil,
       frequency_penalty: Float? = nil,
       logit_bias: [String : Float]? = nil,
       user: String? = nil) {
    self.model = model
    self.messages = messages
    self.temperature = temperature
    self.top_p = top_p
    self.n = n
    self.stream = stream
    self.stop = stop
    self.max_tokens = max_tokens
    self.presence_penalty = presence_penalty
    self.frequency_penalty = frequency_penalty
    self.logit_bias = logit_bias
    self.user = user
  }
}

public struct GPTChatResponse: Codable {
  public let id: String
  public let created: Date
  public let model: String
  public let choices: [Choice]
  
  public init(id: String, created: Date, model: String, choices: [Choice]) {
    self.id = id
    self.created = created
    self.model = model
    self.choices = choices
  }
  
  public struct Choice: Codable {
    public let message: GPTMessage
  }
}

public enum GPTClientError: Error, CustomStringConvertible {
  case errorResponse(statusCode: Int, error: GPTErrorResponse?)
  case networkError(message: String? = nil, error: Error? = nil)
  
  public var description: String {
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

public struct GPTErrorResponse: Codable {
  let error: ErrorDetail
  
  struct ErrorDetail: Codable {
    let message: String
    let type: String
    let param: String?
    let code: String?
  }
}
