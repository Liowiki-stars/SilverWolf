import SwiftUI

struct SettingsView: View {
    @State private var wifiEnabled = true
    @State private var bluetoothEnabled = true
    @State private var infraredEnabled = false
    @State private var cellularEnabled = true
    @State private var voiceprintEnabled = true
    @State private var autoSyncEnabled = true
    @State private var showAPIKeyInput = false

    var body: some View {
        NavigationStack {
            List {
                // 网络设置
                Section("数据链路") {
                    Toggle(isOn: $wifiEnabled) {
                        Label("WiFi 链路", systemImage: "wifi")
                    }
                    .tint(Color(hex: "9D4EDD"))

                    Toggle(isOn: $cellularEnabled) {
                        Label("4G 蜂窝链路", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    .tint(Color(hex: "9D4EDD"))

                    Toggle(isOn: $bluetoothEnabled) {
                        Label("蓝牙链路", systemImage: "bluetooth")
                    }
                    .tint(Color(hex: "9D4EDD"))
                }

                // 智能家居
                Section("设备控制") {
                    Toggle(isOn: $infraredEnabled) {
                        Label("红外发射器", systemImage: "dot.radiowaves.left.and.right")
                    }
                    .tint(Color(hex: "9D4EDD"))

                    NavigationLink {
                        SmartHomeView()
                    } label: {
                        Label("智能家居管理", systemImage: "house.fill")
                    }
                }

                // 个性化
                Section("身份与个性") {
                    Toggle(isOn: $voiceprintEnabled) {
                        Label("声纹解锁（小黎）", systemImage: "faceid")
                    }
                    .tint(Color(hex: "9D4EDD"))

                    NavigationLink {
                        VoiceprintEnrollView()
                    } label: {
                        Label("重新录入声纹", systemImage: "mic.fill")
                    }

                    HStack {
                        Label("用户称呼", systemImage: "person.fill")
                        Spacer()
                        Text("小黎")
                            .foregroundStyle(Color(hex: "9D4EDD"))
                    }
                }

                // 云同步
                Section("云端同步") {
                    Toggle(isOn: $autoSyncEnabled) {
                        Label("自动同步收藏", systemImage: "cloud.fill")
                    }
                    .tint(Color(hex: "9D4EDD"))

                    Button {
                        // 手动同步
                    } label: {
                        Label("立即同步", systemImage: "arrow.triangle.2.circlepath")
                    }
                }

                // AI配置
                Section("AI 大模型") {
                    Button {
                        showAPIKeyInput = true
                    } label: {
                        Label("配置 API 密钥", systemImage: "key.fill")
                    }

                    HStack {
                        Label("当前模型", systemImage: "cpu.fill")
                        Spacer()
                        Text("gpt-3.5-turbo")
                            .foregroundStyle(Color(hex: "6B7280"))
                    }
                }

                // 关于
                Section("关于") {
                    HStack {
                        Label("版本", systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(Color(hex: "6B7280"))
                    }
                    HStack {
                        Label("开发者", systemImage: "wrench.and.screwdriver.fill")
                        Spacer()
                        Text("小黎")
                            .foregroundStyle(Color(hex: "6B7280"))
                    }
                }
            }
            .navigationTitle("系统设置")
            .navigationBarTitleDisplayMode(.large)
            .scrollContentBackground(.hidden)
            .background(Color(hex: "0A0E17"))
            .alert("配置 API 密钥", isPresented: $showAPIKeyInput) {
                SecureField("API Key", text: .constant(""))
                Button("保存", role: .default) {}
                Button("取消", role: .cancel) {}
            } message: {
                Text("输入你的大模型 API 密钥以启用对话功能")
            }
        }
    }
}

// MARK: - 声纹录入视图
struct VoiceprintEnrollView: View {
    @State private var step = 0
    @State private var isRecording = false

    let steps = [
        "请说：你好银狼",
        "请说：播放音乐",
        "请说：打开收藏"
    ]

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // 进度
            VStack(spacing: 12) {
                Text("声纹录入")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                Text("小黎，需要采集3段声纹样本建立你的身份链路")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "9CA3AF"))
                    .multilineTextAlignment(.center)
            }

            // 进度条
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(i <= step ? Color(hex: "9D4EDD") : Color(hex: "374151"))
                        .frame(height: 6)
                }
            }
            .padding(.horizontal, 40)

            // 当前提示
            if step < 3 {
                VStack(spacing: 20) {
                    Text(steps[step])
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)

                    // 录音按钮
                    Button {
                        isRecording.toggle()
                        if !isRecording {
                            step += 1
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isRecording ? Color(hex: "EF4444") : Color(hex: "9D4EDD"))
                                .frame(width: 80, height: 80)
                                .scaleEffect(isRecording ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(), value: isRecording)
                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                    }

                    Text(isRecording ? "正在采集..." : "点击开始录音")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color(hex: "10B981"))
                    Text("声纹录入完成！")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("以后只用你的声音就能解锁所有功能咯")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                }
            }

            Spacer()
        }
        .background(Color(hex: "0A0E17").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
