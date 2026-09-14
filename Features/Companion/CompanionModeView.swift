import SwiftUI

// MARK: - 陪伴模式主界面
struct CompanionModeView: View {
    @EnvironmentObject var companionVM: CompanionViewModel
    @EnvironmentObject var chatVM: ChatViewModel
    @State private var showChatPanel = false
    @State private var showMemoryPanel = false
    @State private var showFocusPanel = false
    @State private var inputText = ""
    @State private var avatarPosition: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 70, y: 120)
    @State private var isDragging = false

    var body: some View {
        ZStack {
            // 背景（模拟手机屏幕内容）
            backgroundView

            // 场景选择条（顶部）
            VStack {
                sceneSelector
                    .padding(.top, 8)
                Spacer()
            }

            // 银狼悬浮形象（可拖拽）
            SilverWolfAvatarView(
                size: 90,
                isActive: companionVM.isTalking,
                onTap: {
                    withAnimation(.spring()) {
                        showChatPanel.toggle()
                    }
                }
            )
            .position(avatarPosition)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        avatarPosition = value.location
                    }
                    .onEnded { _ in
                        isDragging = false
                        // 自动吸附到边缘
                        withAnimation(.spring()) {
                            if avatarPosition.x < UIScreen.main.bounds.width / 2 {
                                avatarPosition.x = 60
                            } else {
                                avatarPosition.x = UIScreen.main.bounds.width - 60
                            }
                        }
                    }
            )

            // 对话气泡（银狼主动说话时显示）
            if companionVM.showChatBubble, !showChatPanel {
                chatBubble
                    .position(
                        x: avatarPosition.x < UIScreen.main.bounds.width / 2
                            ? avatarPosition.x + 110
                            : avatarPosition.x - 110,
                        y: avatarPosition.y - 20
                    )
                    .transition(.opacity.combined(with: .scale))
            }

            // 聊天面板（点击银狼展开）
            if showChatPanel {
                chatPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // 记忆面板
            if showMemoryPanel {
                memoryPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // 专注面板
            if showFocusPanel {
                focusPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // 操作确认弹窗
            if companionVM.showActionConfirmation, let intent = companionVM.pendingIntent {
                ActionConfirmationView(
                    intent: intent,
                    onConfirm: { companionVM.confirmPendingIntent() },
                    onCancel: { companionVM.cancelPendingIntent() },
                    onModify: { keyword in companionVM.modifyPendingIntent(keyword: keyword) }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // 底部控制栏
            VStack {
                Spacer()
                controlBar
                    .padding(.bottom, 20)
            }
        }
        .background(Color(hex: "0A0E17"))
        .navigationBarHidden(true)
        .onAppear {
            companionVM.enterCompanionMode()
        }
        .onDisappear {
            companionVM.exitCompanionMode()
        }
    }

    // MARK: - 背景（模拟刷手机内容）
    private var backgroundView: some View {
        VStack(spacing: 0) {
            // 模拟状态栏
            HStack {
                Text("9:41")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100")
                }
                .font(.system(size: 12))
                .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // 模拟内容区（根据场景变化）
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<8, id: \.self) { index in
                        mockContentCard(index: index)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .opacity(0.35)  // 半透明，突出银狼
    }

    private func mockContentCard(index: Int) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(hex: "1F2937"))
            .frame(height: 180)
            .overlay(
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "374151"))
                        .frame(height: 100)
                    Text("模拟内容 \(index + 1)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("这是模拟的手机屏幕内容...")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                }
                .padding(12)
            )
    }

    // MARK: - 场景选择器
    private var sceneSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CompanionScene.allCases) { scene in
                    Button {
                        companionVM.switchScene(scene)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: scene.icon)
                                .font(.system(size: 14))
                            Text(scene.rawValue)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(companionVM.currentScene == scene
                                      ? Color(hex: "9D4EDD")
                                      : Color(hex: "1F2937"))
                        )
                        .foregroundStyle(companionVM.currentScene == scene ? .white : Color(hex: "9CA3AF"))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - 对话气泡
    private var chatBubble: some View {
        Text(companionVM.currentBubbleText)
            .font(.system(size: 14))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "7B2CBF"))
            )
            .frame(maxWidth: 180, alignment: .leading)
            .shadow(color: Color(hex: "9D4EDD").opacity(0.4), radius: 8, x: 0, y: 4)
    }

    // MARK: - 聊天面板
    private var chatPanel: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                // 拖拽条
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "4B5563"))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                // 标题
                HStack {
                    Text("和银狼聊天")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        withAnimation(.spring()) {
                            showChatPanel = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // 消息列表
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(companionVM.companionMessages) { msg in
                            HStack {
                                if msg.role == "user" { Spacer() }
                                Text(msg.content)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(msg.role == "user"
                                                  ? Color(hex: "9D4EDD")
                                                  : Color(hex: "1F2937"))
                                    )
                                    .frame(maxWidth: 250, alignment: msg.role == "user" ? .trailing : .leading)
                                if msg.role == "silverwolf" { Spacer() }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .frame(height: 250)

                // 快捷操作面板
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        quickActionButton(icon: "takeoutbag.and.cup.and.straw.fill", color: "FFD100", title: "点外卖") {
                            companionVM.triggerQuickAction(.orderFood)
                        }
                        quickActionButton(icon: "music.note", color: "C20C0C", title: "放首歌") {
                            companionVM.triggerQuickAction(.playMusic)
                        }
                        quickActionButton(icon: "cart.fill", color: "FF5000", title: "去购物") {
                            companionVM.triggerQuickAction(.shop)
                        }
                        quickActionButton(icon: "tv.fill", color: "00A1D6", title: "看视频") {
                            companionVM.triggerQuickAction(.watchVideo)
                        }
                        quickActionButton(icon: "at.circle.fill", color: "E6162D", title: "刷社交") {
                            companionVM.triggerQuickAction(.browseSocial)
                        }
                        quickActionButton(icon: "magnifyingglass", color: "06B6D4", title: "搜索") {
                            companionVM.triggerQuickAction(.searchWeb)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 12)

                // 输入栏
                HStack(spacing: 10) {
                    TextField("和银狼说点什么...", text: $inputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color(hex: "1F2937"))
                        )
                        .onSubmit {
                            sendMessage()
                        }

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(inputText.isEmpty ? Color(hex: "4B5563") : Color(hex: "9D4EDD"))
                            )
                    }
                    .disabled(inputText.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(Color(hex: "111827"))
            .cornerRadius(24, corners: [.topLeft, .topRight])
        }
        .background(Color.black.opacity(0.4).ignoresSafeArea().onTapGesture {
            withAnimation(.spring()) {
                showChatPanel = false
            }
        })
    }

    // 快捷操作按钮
    private func quickActionButton(icon: String, color: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: color))
                Text(title)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "9CA3AF"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "1F2937"))
            )
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        companionVM.sendUserMessage(text)
        inputText = ""
    }

    // MARK: - 底部控制栏
    private var controlBar: some View {
        HStack(spacing: 14) {
            // 主动聊天开关
            controlButton(
                icon: companionVM.autoChatEnabled ? "message.badge.fill" : "message.badge",
                color: companionVM.autoChatEnabled ? "9D4EDD" : "6B7280",
                label: "主动聊天"
            ) {
                companionVM.toggleAutoChat()
            }

            // 智能场景开关
            controlButton(
                icon: companionVM.autoSceneDetectEnabled ? "brain.head.profile" : "brain",
                color: companionVM.autoSceneDetectEnabled ? "10B981" : "6B7280",
                label: "智能场景"
            ) {
                companionVM.toggleAutoSceneDetect()
            }

            // 逗她说话
            controlButton(
                icon: "sparkles",
                color: "FBBF24",
                label: "逗她"
            ) {
                companionVM.triggerAutoChat()
            }

            // 记忆查看
            controlButton(
                icon: "brain.fill",
                color: "EC4899",
                label: "记忆"
            ) {
                showMemoryPanel = true
            }

            // 专注模式
            controlButton(
                icon: companionVM.isFocusMode ? "timer.circle.fill" : "timer.circle",
                color: companionVM.isFocusMode ? "10B981" : "6B7280",
                label: companionVM.isFocusMode ? companionVM.focusTimeText : "专注"
            ) {
                showFocusPanel = true
            }

            // 间隔设置
            Menu {
                Button("30秒") { companionVM.setAutoChatInterval(30) }
                Button("45秒") { companionVM.setAutoChatInterval(45) }
                Button("1分钟") { companionVM.setAutoChatInterval(60) }
                Button("2分钟") { companionVM.setAutoChatInterval(120) }
                Button("5分钟") { companionVM.setAutoChatInterval(300) }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: "3B82F6"))
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(Color(hex: "1F2937")))
                    Text("\(Int(companionVM.autoChatInterval))秒")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                }
            }

            // 退出
            controlButton(
                icon: "rectangle.portrait.and.arrow.right",
                color: "EF4444",
                label: "退出"
            ) {
                companionVM.exitCompanionMode()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: "111827").opacity(0.9))
        )
        .padding(.horizontal, 16)
    }

    // 控制按钮组件
    private func controlButton(icon: String, color: String, label: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: color))
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color(hex: "1F2937")))
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "9CA3AF"))
        }
    }
}

// MARK: - 圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - 记忆面板
extension CompanionModeView {
    private var memoryPanel: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                // 拖拽条
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "4B5563"))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                // 标题
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("银狼的记忆")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                        Text(companionVM.memoryStats)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                    }
                    Spacer()
                    Button {
                        withAnimation(.spring()) {
                            showMemoryPanel = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // 记忆类型筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MemoryType.allCases) { type in
                            Button {
                                // 筛选（简化版：暂不实现筛选逻辑）
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 12))
                                    Text(type.rawValue)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: type.color).opacity(0.2))
                                )
                                .foregroundStyle(Color(hex: type.color))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)

                // 记忆列表
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if companionVM.lastMemorySaved != nil {
                            // 最近保存的记忆提示
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(Color(hex: "FBBF24"))
                                Text("刚记住了新东西")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color(hex: "FBBF24"))
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 4)
                        }

                        // 记忆条目（从MemoryStore读取）
                        MemoryListView()
                            .environmentObject(companionVM)
                    }
                    .padding(.bottom, 20)
                }
                .frame(height: 300)
            }
            .background(Color(hex: "111827"))
            .cornerRadius(24, corners: [.topLeft, .topRight])
        }
        .background(Color.black.opacity(0.4).ignoresSafeArea().onTapGesture {
            withAnimation(.spring()) {
                showMemoryPanel = false
            }
        })
    }
}

// MARK: - 记忆列表视图
struct MemoryListView: View {
    @EnvironmentObject var companionVM: CompanionViewModel
    @State private var memories: [Memory] = []

    var body: some View {
        VStack(spacing: 8) {
            if memories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(hex: "4B5563"))
                    Text("还没有记忆")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "6B7280"))
                    Text("和银狼聊天时，她会自动记住你的喜好和习惯")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "4B5563"))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal, 40)
            } else {
                ForEach(memories, id: \.id) { memory in
                    MemoryRow(memory: memory)
                }
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            loadMemories()
        }
    }

    private func loadMemories() {
        // 从AppState获取MemoryStore
        // 简化处理：这里通过通知或直接访问
        NotificationCenter.default.post(name: NSNotification.Name("LoadMemories"), object: nil)
    }
}

// MARK: - 记忆行
struct MemoryRow: View {
    let memory: Memory

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // 类型图标
            ZStack {
                Circle()
                    .fill(Color(hex: typeColor).opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: typeIcon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: typeColor))
            }

            // 内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(typeName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: typeColor))
                    Text(memory.category)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "6B7280"))
                    Spacer()
                    // 重要度星星
                    HStack(spacing: 1) {
                        ForEach(0..<memory.importance, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Color(hex: "FBBF24"))
                        }
                    }
                }

                Text(memory.content)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "E5E7EB"))
                    .fixedSize(horizontal: false, vertical: true)

                Text(formatDate(memory.createdAt))
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "1F2937"))
        )
    }

    private var typeName: String {
        MemoryType(rawValue: memory.type)?.rawValue ?? "记忆"
    }

    private var typeIcon: String {
        MemoryType(rawValue: memory.type)?.icon ?? "circle.fill"
    }

    private var typeColor: String {
        MemoryType(rawValue: memory.type)?.color ?? "9D4EDD"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 专注面板
extension CompanionModeView {
    private var focusPanel: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                // 拖拽条
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "4B5563"))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                // 标题
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("专注模式")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                        Text(companionVM.isFocusMode ? companionVM.focusManager.focusStatusText : "选择软件场景开始专注")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                    }
                    Spacer()
                    Button {
                        withAnimation(.spring()) {
                            showFocusPanel = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // 专注状态卡片（专注中显示）
                if companionVM.isFocusMode {
                    HStack(spacing: 20) {
                        // 专注时间
                        VStack(spacing: 4) {
                            Text(companionVM.focusTimeText)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981"))
                            Text("专注时长")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "9CA3AF"))
                        }
                        .frame(maxWidth: .infinity)

                        // 番茄钟
                        VStack(spacing: 4) {
                            Text("\(companionVM.pomodoroCount)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color(hex: "F59E0B"))
                            Text("番茄钟")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "9CA3AF"))
                        }
                        .frame(maxWidth: .infinity)

                        // 专注度
                        VStack(spacing: 4) {
                            Text("\(companionVM.focusScore)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color(hex: "9D4EDD"))
                            Text("专注度")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "9CA3AF"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }

                // 软件场景选择（按分类分组）
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择当前软件场景")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                        .padding(.horizontal, 20)

                    // 工作学习
                    VStack(alignment: .leading, spacing: 8) {
                        Text("工作学习")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "6B7280"))
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(SoftwareScene.allCases.filter { $0.category == "工作学习" }) { software in
                                softwareButton(software)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // 娱乐
                    VStack(alignment: .leading, spacing: 8) {
                        Text("娱乐")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "6B7280"))
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(SoftwareScene.allCases.filter { $0.category == "娱乐" }) { software in
                                softwareButton(software)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // 社交
                    VStack(alignment: .leading, spacing: 8) {
                        Text("社交")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "6B7280"))
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(SoftwareScene.allCases.filter { $0.category == "社交" }) { software in
                                softwareButton(software)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // 生活
                    VStack(alignment: .leading, spacing: 8) {
                        Text("生活")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "6B7280"))
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(SoftwareScene.allCases.filter { $0.category == "生活" }) { software in
                                softwareButton(software)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 16)

                // 操作按钮
                HStack(spacing: 12) {
                    if companionVM.isFocusMode {
                        // 结束专注
                        Button {
                            companionVM.endFocusMode()
                            withAnimation(.spring()) {
                                showFocusPanel = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("结束专注")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(hex: "EF4444"))
                            )
                        }
                    } else {
                        // 开始专注
                        Button {
                            companionVM.startFocusMode(software: companionVM.currentSoftware)
                            withAnimation(.spring()) {
                                showFocusPanel = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("开始专注")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(hex: "10B981"))
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(hex: "111827"))
            .cornerRadius(24, corners: [.topLeft, .topRight])
        }
        .background(Color.black.opacity(0.4).ignoresSafeArea().onTapGesture {
            withAnimation(.spring()) {
                showFocusPanel = false
            }
        })
        .onAppear {
            // 监听番茄钟完成通知
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("PomodoroComplete"),
                object: nil,
                queue: .main
            ) { _ in
                companionVM.handlePomodoroComplete()
            }
        }
    }

    // 软件场景按钮组件
    private func softwareButton(_ software: SoftwareScene) -> some View {
        Button {
            if companionVM.isFocusMode {
                companionVM.switchSoftwareScene(software)
            } else {
                companionVM.startFocusMode(software: software)
                withAnimation(.spring()) {
                    showFocusPanel = false
                }
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: software.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: software.color))
                Text(software.rawValue)
                    .font(.system(size: 9))
                    .foregroundStyle(companionVM.currentSoftware == software ? .white : Color(hex: "9CA3AF"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(companionVM.currentSoftware == software
                          ? Color(hex: software.color).opacity(0.2)
                          : Color(hex: "1F2937"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(companionVM.currentSoftware == software ? Color(hex: software.color) : Color.clear, lineWidth: 1)
            )
        }
    }
}
