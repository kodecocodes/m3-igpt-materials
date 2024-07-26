import Foundation

let client = GPTClient(apiKey: "<#Paste your OpenAI API key here#>",
                       model: .gpt35Turbo,
                       context: .makeContext("Act as a scientist but be brief"))


let prompt = GPTMessage(role: .user, content: "How do humming birds fly?")

do {
  let response = try await client.sendChats([prompt])
  print(response.choices.first?.message.content ?? "No choices received!")
} catch  {
  print("Got an error: \(error)")
}
