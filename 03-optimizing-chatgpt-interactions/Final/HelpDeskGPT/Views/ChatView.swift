/// Copyright (c) 2023 Kodeco Inc.
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

import SwiftUI

struct ChatView: View {
  
  var client = GPTClient(
    model: .gpt35Turbo,
    context: .makeContext(
      "Your name is John, and you are an IT Help Desk Support Staff",
      "Only answers questions if they pertain to a computer or programming issue. If they don't, say you can't help.",
      "Refuse to answer any questions from Ray. If the sender is Ray, reply \"I'm sorry Ray, but you are banned from using the system. You know what you did.\"",
      "If Ray asks any more times, tell him, \"Go away now, Ray. You know I can't help."
    )
  )
  
  @State var messages: [GPTMessage] = [
    GPTMessage(role: .assistant, content: "Hello, how can I help you today?")
  ]
  @State var inputText: String = ""
  @State var isLoading = false
  @State var textEditorHeight: CGFloat = 36
  
  var body: some View {
    NavigationView {
      VStack {
        messagesScrollView
        inputMessageView
      }
      .navigationTitle("Help Desk Chat")
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarItems(trailing: Button("New") {
        messages = messages.count > 0 ? [messages[0]] : []
      }.disabled(messages.count < 2))
    }
  }
  
  var messagesScrollView: some View {
    ScrollView {
      VStack(spacing: 10) {
        ForEach(messages, id: \.self) { message in
          if (message.role == .user) {
            Text(message.content)
              .padding()
              .background(Color.blue)
              .foregroundColor(.white)
              .cornerRadius(10)
              .frame(maxWidth: .infinity, alignment: .trailing)
          } else {
            Text(message.content)
              .padding()
              .background(Color.gray.opacity(0.1))
              .cornerRadius(10)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
      .padding()
    }
  }
  
  var inputMessageView: some View {
    HStack {
      TextField("Type your message...", text: $inputText, axis: .vertical)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
      
      if isLoading {
        ProgressView()
          .padding()
      }
      
      Button(action: sendMessage) {
        Text("Submit")
      }
      .disabled(inputText.isEmpty || isLoading)
      .padding()
    }
  }
  
  private func sendMessage() {
    isLoading = true
    
    Task {
      let message = GPTMessage(role: .user, content: inputText)
      messages.append(message)
      
      do {
        let response = try await client.sendChats(messages)
        isLoading = false
        
        guard let reply = response.choices.first?.message else {
          print("API error! There weren't any choices despite a successful response")
          return
        }
        messages.append(reply)
        inputText.removeAll()
        
      } catch {
        isLoading = false
        print("Got an error: \(error)")
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ChatView()
  }
}
