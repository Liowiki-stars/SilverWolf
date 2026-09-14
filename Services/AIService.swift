import Foundation

// MARK: - AI大模型服务（可切换不同提供商）
final class AIService {
    static let shared = AIService()

    private let apiKey: String
    private let baseURL: String
    private let model: String

    private init() {
        // 从Info.plist或Keychain读取配置
        self.apiKey = Bundle.main.object(forInfoDictionaryKey: "AI_API_KEY") as? String ?? ""
        self.baseURL = Bundle.main.object(forInfoDictionaryKey: "AI_BASE_URL") as? String
            ?? "https://api.openai.com/v1/chat/completions"
        self.model = Bundle.main.object(forInfoDictionaryKey: "AI_MODEL") as? String
            ?? "gpt-3.5-turbo"
    }

    // MARK: - 生成对话回复
    func generateResponse(systemPrompt: String, messages: [[String: String]]) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIError.noAPIKey
        }

        var requestMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        // 只取最近10轮对话，避免token超限
        let recent = messages.suffix(10)
        requestMessages.append(contentsOf: recent)

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": requestMessages,
            "temperature": 0.7,
            "max_tokens": 300
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIError.requestFailed
        }

        let result = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        return result.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? "小黎，数据解析失败了嘛"
    }
}

// MARK: - API响应模型
struct ChatCompletionResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let role: String
    let content: String
}

// MARK: - 错误类型
enum AIError: LocalizedError {
    case noAPIKey
    case requestFailed
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "未配置API密钥"
        case .requestFailed: return "网络请求失败"
        case .parsingFailed: return "数据解析失败"
        }
    }
}
