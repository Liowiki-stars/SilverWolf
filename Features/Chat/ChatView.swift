import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @EnvironmentObject var appState: AppState
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatVM.messages) { msg in
                                MessageBubble(message: msg)
                                    .id(msg.id)
                            }

                            // 加载中指示
                            if chatVM.isProcessing {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.leading, 16)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    }
                    .onChange(of: chatVM.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(chatVM.messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                }
                .background(Color(hex: "0A0E17"))

                // 输入栏
                InputBar(
                    text: $chatVM.inputText,
                    isProcessing: chatVM.isProcessing,
                    onSend: chatVM.sendMessage
                )
                .background(Color(hex: "111827"))
            }
            .navigationTitle("银狼")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // 陪伴模式入口
                        Button {
                            appState.showCompanionMode = true
                        } label: {
                            Image(systemName: "person.crop.rectangle.stack.fill")
                                .foregroundStyle(Color(hex: "9D4EDD"))
                        }

                        Menu {
                            Button(role: .destructive) {
                                chatVM.clearHistory()
                            } label: {
                                Label("清空对话", systemImage: "trash")
                            }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color(hex: "9D4EDD"))
                    }
                    }
                }
            }
            .toolbarBackground(Color(hex: "111827"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - 消息气泡
struct MessageBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !isUser {
                // 银狼头像
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "9D4EDD"), Color(hex: "7B2CBF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("狼")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundStyle(isUser ? .white : Color(hex: "E5E7EB"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(isUser ? Color(hex: "9D4EDD") : Color(hex: "1F2937"))
                    )
                    .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)

                Text(formatTime(message.timestamp))
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .padding(.horizontal, 4)
            }

            if isUser {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 打字中指示器
struct TypingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color(hex: "9D4EDD"))
                    .frame(width: 8, height: 8)
                    .offset(y: animate ? -4 : 0)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.15),
                        value: animate
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "1F2937"))
        )
        .onAppear { animate = true }
    }
}

// MARK: - 输入栏
struct InputBar: View {
    @Binding var text: String
    let isProcessing: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 语音按钮（预留）
            Button {
                // 语音输入
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "9D4EDD"))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color(hex: "1F2937"))
                    )
            }

            // 文本输入
            TextField("和银狼说点什么...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(hex: "1F2937"))
                )
                .lineLimit(1...4)

            // 发送按钮
            Button {
                onSend()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(text.trimmingCharacters(in: .whitespaces).isEmpty
                                  ? Color(hex: "4B5563")
                                  : Color(hex: "9D4EDD"))
                    )
            }
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0)
    }
}

// MARK: - Color扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
