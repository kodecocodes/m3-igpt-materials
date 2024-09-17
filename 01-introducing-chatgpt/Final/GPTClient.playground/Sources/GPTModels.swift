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

public struct GPTChatRequest: Codable {
  public let model: GPTModelVersion
  public let messages: [GPTMessage]
  
  public init(model: GPTModelVersion,
              messages: [GPTMessage]) {
    self.model = model
    self.messages = messages
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
