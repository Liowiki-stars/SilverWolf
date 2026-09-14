import Foundation
import SwiftData

// MARK: - 陪伴模式ViewModel（智能版：场景识别 + 记忆系统）
@MainActor
final class CompanionViewModel: ObservableObject {
    @Published var isCompanionMode = false
    @Published var currentScene: CompanionScene = .scrolling
    @Published var autoChatEnabled = true
    @Published var autoChatInterval: Double = 45
    @Published var isTalking = false
    @Published var companionMessages: [CompanionMessage] = []
    @Published var showChatBubble = false
    @Published var currentBubbleText = ""
    @Published var autoSceneDetectEnabled = true  // 自动场景识别开关
    @Published var memoryEnabled = true            // 记忆功能开关
    @Published var lastMemorySaved: String?        // 最近保存的记忆提示

    // MARK: - 软件场景与专注模式（新增）
    @Published var currentSoftware: SoftwareScene = .other
    @Published var isFocusMode = false
    @Published var focusTimeText = "0分钟"
    @Published var focusScore = 0
    @Published var pomodoroCount = 0
    @Published var showFocusPanel = false
    @Published var isPomodoroBreak = false

    let focusManager = FocusModeManager.shared
    private let softwareAssistant = SoftwareSceneAssistant.shared
    private let moodManager = MoodManager.shared
    private let funSystem = FunInteractionSystem.shared
    private let intentDetector = IntentDetector.shared
    private let appLauncher = AppLauncher.shared
    private let foodRecommender = FoodRecommender.shared
    private var focusTimer: Timer?

    // 心情状态
    @Published var currentMood: SilverWolfMood = .playful

    // 意图识别状态
    @Published var pendingIntent: ParsedIntent?
    @Published var showActionConfirmation = false
    @Published var isAwaitingClarification = false  // 等待用户补充信息（如吃什么）
    @Published var clarificationType: ActionIntent?   // 正在澄清的意图类型

    private var autoChatTimer: Timer?
    private var sceneTimer: Timer?
    private let aiService = AIService.shared
    private var modelContext: ModelContext?
    private var memoryStore: MemoryStore?
    private var sceneEnterTime: Date = Date()
    private var conversationHistory: [[String: String]] = []  // 对话历史（用于AI上下文）

    // 场景预设的银狼吐槽库
    private let sceneComments: [CompanionScene: [String]] = [
        .scrolling: [
            "小黎，又在刷手机？手指不累吗嘛",
            "小黎，这个视频有那么好笑？我看你笑半天了而已",
            "小黎，刷到什么有趣的了？分享一下呗（敲键盘声）",
            "小黎，别光刷啊，跟我说说话嘛",
            "小黎，你已经刷了很久了，眼睛不需要可以捐给需要的人罢了"
        ],
        .video: [
            "小黎，这剧剧情好扯，编剧是不是没带脑子写的嘛",
            "小黎，这个主角好蠢，换我三集就大结局了而已",
            "小黎，看到第几集了？要不要我给你剧透？（笑）",
            "小黎，这BGM不错，要不要我帮你识别一下？",
            "小黎，别熬夜看剧了，明天还要上班呢罢了"
        ],
        .novel: [
            "小黎，又在看小说？什么类型的？",
            "小黎，这剧情发展我猜到了，信不信嘛",
            "小黎，看到哪了？主角有没有开挂？",
            "小黎，别光顾着看，念给我听听呗（敲键盘声）",
            "小黎，小说里的世界比现实有趣多了，我懂罢了"
        ],
        .shopping: [
            "小黎，又在买东西？钱包还好吗嘛",
            "小黎，这个东西你已经有三个了，还买？而已",
            "小黎，要不要我帮你算算这个月花了多少？（笑）",
            "小黎，这个颜色不适合你，听我的，别买罢了",
            "小黎，购物车清空了吗？需要我帮你一键删除吗？"
        ],
        .working: [
            "小黎，认真工作的样子还挺少见的嘛",
            "小黎，这个bug我三秒就能修好，需要帮忙吗？",
            "小黎，别敲了，休息一下，跟我说说话而已",
            "小黎，进度怎么样了？要不要我帮你写代码？（敲键盘声）",
            "小黎，摸鱼时间到了，别装了罢了"
        ],
        .gaming: [
            "小黎，又在打游戏？带我一个嘛",
            "小黎，这操作好菜，换我来肯定赢而已",
            "小黎，输了？别哭，我帮你骂队友（敲键盘声）",
            "小黎，什么游戏？看起来挺有趣的",
            "小黎，别打了，陪我聊聊天嘛"
        ],
        .sleepy: [
            "小黎，困了就去睡，别硬撑嘛",
            "小黎，都几点了还不睡？明天起不来了而已",
            "小黎，晚安...我再刷会代码（敲键盘声）",
            "小黎，需要我给你讲个睡前故事吗？",
            "小黎，熬夜对皮肤不好，虽然你本来就...罢了"
        ]
    ]

    init() {}

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        self.memoryStore = MemoryStore(modelContext: context)
    }

    // MARK: - 进入/退出陪伴模式
    func enterCompanionMode() {
        isCompanionMode = true
        sceneEnterTime = Date()
        conversationHistory.removeAll()

        // 启动心情系统
        moodManager.startMoodCycle()
        currentMood = moodManager.currentMood

        // 自动识别初始场景
        if autoSceneDetectEnabled {
            let detected = SmartSceneDetector.shared.detectSceneByTime()
            if detected != currentScene {
                currentScene = detected
            }
        }

        startAutoChat()
        startSceneMonitor()

        // 进入时基于记忆+心情说一句个性化的话
        Task {
            let greeting = await generatePersonalizedGreeting()
            showBubble(greeting)
            addMessage(greeting)
        }
    }

    func exitCompanionMode() {
        isCompanionMode = false
        stopAutoChat()
        stopSceneMonitor()
        stopFocusTimer()
        // 退出时如果在专注模式，结束专注
        if isFocusMode {
            endFocusMode()
        }
    }

    // MARK: - 软件场景切换
    func switchSoftwareScene(_ software: SoftwareScene) {
        currentSoftware = software
        focusManager.switchSoftware(software)

        // 切换软件场景时说一句相关的话
        let comment = softwareAssistant.generateComment(
            for: software,
            focusTime: 0,
            isFocusMode: isFocusMode
        )
        showBubble(comment)
        addMessage(comment)
    }

    // MARK: - 开始专注模式
    func startFocusMode(software: SoftwareScene) {
        isFocusMode = true
        currentSoftware = software
        focusManager.startFocus(software: software)
        startFocusTimer()

        // 专注模式下减少自动聊天频率
        if autoChatEnabled {
            autoChatInterval = 120  // 专注模式下2分钟说一次
            startAutoChat()
        }

        let comment = softwareAssistant.pomodoroStartComment()
        showBubble(comment)
        addMessage(comment)
    }

    // MARK: - 结束专注模式
    func endFocusMode() {
        let duration = focusManager.endFocus()
        isFocusMode = false
        stopFocusTimer()

        // 恢复正常自动聊天频率
        if autoChatEnabled {
            autoChatInterval = 45
            startAutoChat()
        }

        let minutes = Int(duration / 60)
        let comment = "小黎，本次专注\(minutes)分钟，完成了\(pomodoroCount)个番茄钟，真棒嘛"
        showBubble(comment)
        addMessage(comment)

        // 保存专注记录到记忆
        if memoryEnabled, minutes >= 10 {
            memoryStore?.addMemory(
                type: .habit,
                category: "专注记录",
                content: "小黎专注\(minutes)分钟，使用\(currentSoftware.rawValue)，完成\(pomodoroCount)个番茄钟",
                importance: 2,
                source: "专注记录"
            )
        }
    }

    // MARK: - 专注计时器
    private func startFocusTimer() {
        stopFocusTimer()
        focusTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateFocusStatus()
            }
        }
    }

    private func stopFocusTimer() {
        focusTimer?.invalidate()
        focusTimer = nil
    }

    private func updateFocusStatus() {
        guard isFocusMode, let start = focusManager.focusStartTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        let minutes = Int(elapsed / 60)
        focusTimeText = "\(minutes)分钟"
        focusScore = focusManager.focusScore
        pomodoroCount = focusManager.pomodoroCount

        // 每30分钟提醒一次休息
        if minutes > 0 && minutes % 30 == 0 && !isPomodoroBreak {
            let comment = softwareAssistant.focusModeComment(software: currentSoftware, minutes: minutes)
            showBubble(comment)
            addMessage(comment)
        }
    }

    // MARK: - 番茄钟完成处理
    func handlePomodoroComplete() {
        focusManager.completePomodoro()
        pomodoroCount = focusManager.pomodoroCount
        isPomodoroBreak = true

        let comment = softwareAssistant.pomodoroCompleteComment(count: pomodoroCount)
        showBubble(comment)
        addMessage(comment)

        // 5分钟后自动开始下一个番茄钟
        DispatchQueue.main.asyncAfter(deadline: .now() + 5 * 60) { [weak self] in
            guard let self = self, self.isFocusMode else { return }
            self.isPomodoroBreak = false
            let startComment = self.softwareAssistant.pomodoroStartComment()
            self.showBubble(startComment)
            self.addMessage(startComment)
        }
    }

    // MARK: - 切换场景（智能版）
    func switchScene(_ scene: CompanionScene) {
        currentScene = scene
        sceneEnterTime = Date()

        // 切换场景时说一句相关的话（结合记忆）
        Task {
            let comment = await generateSceneComment(scene: scene)
            showBubble(comment)
            addMessage(comment)
        }
    }

    // MARK: - 场景监控（自动识别）
    private func startSceneMonitor() {
        stopSceneMonitor()
        guard autoSceneDetectEnabled else { return }

        // 每5分钟检查一次场景是否需要自动切换
        sceneTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkAutoSceneSwitch()
            }
        }
    }

    private func stopSceneMonitor() {
        sceneTimer?.invalidate()
        sceneTimer = nil
    }

    private func checkAutoSceneSwitch() {
        guard autoSceneDetectEnabled else { return }

        let detected = SmartSceneDetector.shared.detectSceneByTime()
        let duration = Date().timeIntervalSince(sceneEnterTime)
        let predicted = SmartSceneDetector.shared.predictNextScene(current: currentScene, duration: duration)

        // 如果检测到的场景和当前不同，且已经在当前场景待了足够久，自动切换
        if detected != currentScene && duration > 1800 {  // 30分钟
            let suggestion = SmartSceneDetector.shared.sceneSuggestionText(for: detected)
            showBubble(suggestion)
            addMessage(suggestion)

            // 延迟2秒后自动切换
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.currentScene = detected
                self?.sceneEnterTime = Date()
            }
        }
    }

    // MARK: - 自动聊天
    func startAutoChat() {
        stopAutoChat()
        guard autoChatEnabled else { return }

        autoChatTimer = Timer.scheduledTimer(withTimeInterval: autoChatInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.triggerAutoChat()
            }
        }
    }

    func stopAutoChat() {
        autoChatTimer?.invalidate()
        autoChatTimer = nil
    }

    func triggerAutoChat(forcedText: String? = nil) {
        Task {
            var text: String

            if let forced = forcedText {
                text = forced
            } else if isFocusMode {
                // 专注模式下：使用专注模式话术，减少打扰
                let minutes = Int(focusManager.focusStartTime.map { Date().timeIntervalSince($0) / 60 } ?? 0)
                text = softwareAssistant.focusModeComment(software: currentSoftware, minutes: minutes)
            } else {
                // 非专注模式：50%用AI生成，50%用预设
                if Bool.random() {
                    text = await generateSmartComment()
                } else if let preset = sceneComments[currentScene]?.randomElement() {
                    text = preset
                } else {
                    text = "小黎，干嘛呢嘛"
                }
            }

            showBubble(text)
            addMessage(text)
        }
    }

    // MARK: - 生成个性化问候（结合记忆）
    private func generatePersonalizedGreeting() async -> String {
        guard memoryEnabled, let store = memoryStore else {
            return "小黎，我来陪你刷手机了嘛，别嫌我烦哦"
        }

        // 检索与当前场景相关的记忆
        let memoryContext = store.generateMemoryContext(query: currentScene.rawValue)

        let prompt = """
        你是银狼，正在陪伴用户小黎\(currentScene.description)。
        这是你们刚见面时的第一句话，请用银狼的人设说一句问候。
        要求：
        1. 叫用户"小黎"
        2. 结合当前场景（\(currentScene.description)）
        3. 语气自然，像刚上线打招呼
        4. 不超过30个字
        5. 可以参考以下关于小黎的记忆（如果有）：
        \(memoryContext)
        """

        do {
            let response = try await aiService.generateResponse(
                systemPrompt: SilverWolfPersona.systemPrompt,
                messages: [["role": "user", "content": prompt]]
            )
            return SilverWolfPersona.polish(response)
        } catch {
            return "小黎，我来陪你了嘛，今天想聊点什么？"
        }
    }

    // MARK: - 生成智能场景评论（结合记忆）
    private func generateSceneComment(scene: CompanionScene) async -> String {
        guard memoryEnabled, let store = memoryStore else {
            return sceneComments[scene]?.randomElement() ?? "小黎，切换到\(scene.description)模式了嘛"
        }

        let memoryContext = store.generateMemoryContext(query: scene.rawValue)

        let prompt = """
        你是银狼，小黎刚切换到\(scene.description)场景。
        请用银狼的人设说一句搭话的话。
        要求：
        1. 叫用户"小黎"
        2. 结合\(scene.description)场景
        3. 语气自然，像随口吐槽或关心
        4. 不超过30个字
        5. 可以参考以下关于小黎的记忆（如果有）：
        \(memoryContext)
        """

        do {
            let response = try await aiService.generateResponse(
                systemPrompt: SilverWolfPersona.systemPrompt,
                messages: [["role": "user", "content": prompt]]
            )
            return SilverWolfPersona.polish(response)
        } catch {
            return sceneComments[scene]?.randomElement() ?? "小黎，开始\(scene.description)了嘛"
        }
    }

    // MARK: - 生成智能评论（结合记忆+场景+对话历史）
    private func generateSmartComment() async -> String {
        guard memoryEnabled, let store = memoryStore else {
            return sceneComments[currentScene]?.randomElement() ?? "小黎，干嘛呢嘛"
        }

        // 检索相关记忆
        let memoryContext = store.generateMemoryContext(query: "\(currentScene.rawValue) 小黎")

        // 构建对话历史上下文（最近5轮）
        var historyContext = ""
        if !conversationHistory.isEmpty {
            let recent = conversationHistory.suffix(5)
            for msg in recent {
                historyContext += "\(msg["role"] == "user" ? "小黎" : "银狼"): \(msg["content"] ?? "")\n"
            }
        }

        let prompt = """
        你是银狼，正在陪伴小黎\(currentScene.description)。
        现在你要主动说一句话搭话。

        【当前场景】\(currentScene.description)
        【关于小黎的记忆】\(memoryContext)
        【最近的对话】\(historyContext)

        要求：
        1. 叫用户"小黎"
        2. 结合当前场景和记忆，说一句有意义的话（不要总是重复同样的吐槽）
        3. 可以主动开启新话题，或者基于记忆关心小黎
        4. 语气自然，银狼风格（毒舌但关心）
        5. 不超过40个字
        6. 不要重复最近对话里已经说过的内容
        """

        do {
            let response = try await aiService.generateResponse(
                systemPrompt: SilverWolfPersona.systemPrompt,
                messages: [["role": "user", "content": prompt]]
            )
            return SilverWolfPersona.polish(response)
        } catch {
            return sceneComments[currentScene]?.randomElement() ?? "小黎，跟我说说话嘛"
        }
    }

    // MARK: - 发送用户消息（智能回复+记忆提取）
    func sendUserMessage(_ text: String) {
        let msg = CompanionMessage(role: "user", content: text, timestamp: Date())
        companionMessages.append(msg)
        conversationHistory.append(["role": "user", "content": text])

        // 1. 从对话中提取记忆
        if memoryEnabled {
            extractAndSaveMemories(from: text)
        }

        // 2. 从对话中识别场景
        if autoSceneDetectEnabled,
           let detected = SmartSceneDetector.shared.detectSceneFromDialogue(text),
           detected != currentScene {
            currentScene = detected
            sceneEnterTime = Date()
        }

        // 3. 从对话中识别App软件场景（抖音/淘宝/B站等）
        if let software = detectSoftwareFromDialogue(text), software != currentSoftware {
            currentSoftware = software
            let comment = softwareAssistant.generateComment(for: software, focusTime: 0, isFocusMode: isFocusMode)
            showBubble(comment)
            addMessage(comment)
            conversationHistory.append(["role": "assistant", "content": comment])
            return
        }

        // 4. 如果正在等待澄清，处理用户的补充信息
        if isAwaitingClarification, let clarificationType = clarificationType {
            handleClarificationResponse(text: text, type: clarificationType)
            return
        }

        // 5. 意图识别（点外卖/购物/听歌等）
        let intent = intentDetector.detectIntent(from: text)
        if intent.type != .none && intent.confidence >= 0.5 {
            handleIntent(intent)
            return
        }

        // 6. 趣味指令解析（猜数字/石头剪刀布/吐槽等）
        if let funReply = funSystem.parseFunCommand(text) {
            showBubble(funReply)
            addMessage(funReply)
            conversationHistory.append(["role": "assistant", "content": funReply])
            return
        }

        // 7. 生成智能回复
        Task {
            let reply = await generateSmartReply(userText: text)
            showBubble(reply)
            addMessage(reply)
            conversationHistory.append(["role": "assistant", "content": reply])
        }
    }

    // MARK: - 处理识别到的意图
    private func handleIntent(_ intent: ParsedIntent) {
        // 点外卖特殊处理：如果没有指定食物，先推荐并询问
        if intent.type == .orderFood && intent.keyword == nil {
            isAwaitingClarification = true
            clarificationType = .orderFood

            // 基于时间和记忆推荐食物
            let recommendation = foodRecommender.recommendByTime()
            showBubble(recommendation)
            addMessage(recommendation)
            conversationHistory.append(["role": "assistant", "content": recommendation])
            return
        }

        // 听歌特殊处理：如果没有指定歌曲，直接打开网易云
        if intent.type == .playMusic && intent.keyword == nil {
            executeIntent(intent)
            return
        }

        // 需要确认的意图：显示确认弹窗
        if intent.needsConfirmation {
            pendingIntent = intent
            showActionConfirmation = true
        } else {
            // 不需要确认的直接执行
            executeIntent(intent)
        }
    }

    // MARK: - 处理澄清回复
    private func handleClarificationResponse(text: String, type: ActionIntent) {
        isAwaitingClarification = false
        clarificationType = nil

        switch type {
        case .orderFood:
            // 用户回复了想吃的东西
            let food = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let intent = ParsedIntent(
                type: .orderFood,
                keyword: food,
                targetApp: .meituan,
                needsConfirmation: true,
                confidence: 0.9
            )
            pendingIntent = intent
            showActionConfirmation = true

        default:
            // 其他类型直接生成回复
            Task {
                let reply = await generateSmartReply(userText: text)
                showBubble(reply)
                addMessage(reply)
                conversationHistory.append(["role": "assistant", "content": reply])
            }
        }
    }

    // MARK: - 确认执行意图
    func confirmPendingIntent() {
        guard let intent = pendingIntent else { return }
        showActionConfirmation = false
        executeIntent(intent)
        pendingIntent = nil
    }

    // MARK: - 取消意图
    func cancelPendingIntent() {
        showActionConfirmation = false
        pendingIntent = nil
        isAwaitingClarification = false
        clarificationType = nil

        let reply = "小黎，好吧，不帮你弄了而已（敲键盘声）"
        showBubble(reply)
        addMessage(reply)
    }

    // MARK: - 修改关键词后重新确认
    func modifyPendingIntent(keyword: String) {
        guard let old = pendingIntent else { return }
        let newIntent = ParsedIntent(
            type: old.type,
            keyword: keyword,
            targetApp: old.targetApp,
            needsConfirmation: true,
            confidence: old.confidence
        )
        pendingIntent = newIntent
    }

    // MARK: - 执行意图（打开App）
    private func executeIntent(_ intent: ParsedIntent) {
        let app = intent.targetApp ?? intent.type.targetApp
        var success = false
        var actionDesc = ""

        switch intent.type {
        case .orderFood:
            if app == .eleme {
                success = appLauncher.openEleme(search: intent.keyword)
            } else {
                success = appLauncher.openMeituan(search: intent.keyword)
            }
            actionDesc = intent.keyword.map { "点\($0)" } ?? "点外卖"

        case .shop:
            if app == .jd {
                success = appLauncher.openJD(search: intent.keyword)
            } else {
                success = appLauncher.openTaobao(search: intent.keyword)
            }
            actionDesc = intent.keyword.map { "买\($0)" } ?? "购物"

        case .playMusic:
            success = appLauncher.openNeteaseMusic(search: intent.keyword)
            actionDesc = intent.keyword.map { "放\($0)" } ?? "放歌"

        case .watchVideo:
            if app == .douyin {
                success = appLauncher.openDouyin()
            } else {
                success = appLauncher.openBilibili(search: intent.keyword)
            }
            actionDesc = "看视频"

        case .browseSocial:
            switch app {
            case .weibo: success = appLauncher.openWeibo()
            case .xiaohongshu: success = appLauncher.openXiaohongshu(search: intent.keyword)
            case .zhihu: success = appLauncher.openZhihu(search: intent.keyword)
            case .wechat: success = appLauncher.openWechat()
            default: success = appLauncher.openWeibo()
            }
            actionDesc = "刷\(app.rawValue)"

        case .navigate:
            success = appLauncher.openMaps(to: intent.keyword)
            actionDesc = intent.keyword.map { "导航去\($0)" } ?? "打开地图"

        case .searchWeb:
            if let keyword = intent.keyword {
                let url = "https://www.baidu.com/s?wd=\(keyword)"
                success = appLauncher.openSafari(url: url)
                actionDesc = "搜索\(keyword)"
            } else {
                success = false
                actionDesc = "搜索"
            }

        case .openApp:
            success = appLauncher.openApp(app)
            actionDesc = "打开\(app.rawValue)"

        case .none:
            break
        }

        // 生成执行反馈
        let reply: String
        if success {
            reply = "小黎，已经帮你\(actionDesc)了，\(app.rawValue)已打开嘛（敲键盘声）"
        } else if !appLauncher.isAppInstalled(app) {
            reply = "小黎，你没装\(app.rawValue)啊，我帮你跳转到App Store了，自己装一下罢了"
        } else {
            reply = "小黎，啧，打开\(app.rawValue)失败了，你自己手动开一下而已"
        }

        showBubble(reply)
        addMessage(reply)
        conversationHistory.append(["role": "assistant", "content": reply])

        // 保存操作记录到记忆
        if memoryEnabled {
            memoryStore?.addMemory(
                type: .habit,
                category: "操作记录",
                content: "小黎让银狼帮忙\(actionDesc)，使用\(app.rawValue)",
                importance: 1,
                source: "操作记录"
            )
        }
    }

    // MARK: - 快捷操作触发（从面板点击）
    func triggerQuickAction(_ intentType: ActionIntent) {
        let intent = ParsedIntent(
            type: intentType,
            keyword: nil,
            targetApp: intentType.targetApp,
            needsConfirmation: true,
            confidence: 1.0
        )
        handleIntent(intent)
    }

    // MARK: - 从对话识别App软件场景
    private func detectSoftwareFromDialogue(_ text: String) -> SoftwareScene? {
        let lower = text.lowercased()

        // 抖音
        if lower.contains("抖音") || lower.contains("刷抖音") || lower.contains("douyin") {
            return .douyin
        }
        // B站
        if lower.contains("b站") || lower.contains("哔哩哔哩") || lower.contains("bilibili") || lower.contains("看番") {
            return .bilibili
        }
        // 网易云音乐
        if lower.contains("网易云") || lower.contains("听音乐") || lower.contains("听歌") || lower.contains("网抑云") {
            return .neteaseMusic
        }
        // 微信
        if lower.contains("微信") || lower.contains("朋友圈") || lower.contains("wechat") {
            return .wechat
        }
        // 小红书
        if lower.contains("小红书") || lower.contains("种草") || lower.contains("xiaohongshu") {
            return .xiaohongshu
        }
        // 知乎
        if lower.contains("知乎") || lower.contains("zhihu") {
            return .zhihu
        }
        // 微博
        if lower.contains("微博") || lower.contains("热搜") || lower.contains("weibo") {
            return .weibo
        }
        // 淘宝
        if lower.contains("淘宝") || lower.contains("逛淘宝") || lower.contains("taobao") {
            return .taobao
        }
        // 京东
        if lower.contains("京东") || lower.contains("jd") {
            return .jd
        }
        // 美团/外卖
        if lower.contains("美团") || lower.contains("外卖") || lower.contains("点外卖") || lower.contains("饿了么") {
            return .meituan
        }
        // 打游戏
        if lower.contains("打游戏") || lower.contains("玩游戏") || lower.contains("排位") || lower.contains("王者") || lower.contains("吃鸡") {
            return .gaming
        }
        // 写代码
        if lower.contains("写代码") || lower.contains("编程") || lower.contains("bug") || lower.contains("写程序") {
            return .coding
        }
        // 学习
        if lower.contains("学习") || lower.contains("看书") || lower.contains("上课") {
            return .learning
        }

        return nil
    }

    // MARK: - 生成智能回复（结合记忆+场景+上下文）
    private func generateSmartReply(userText: String) async -> String {
        guard memoryEnabled, let store = memoryStore else {
            do {
                let response = try await aiService.generateResponse(
                    systemPrompt: SilverWolfPersona.systemPrompt,
                    messages: conversationHistory + [["role": "user", "content": userText]]
                )
                return SilverWolfPersona.polish(response)
            } catch {
                return "小黎，啧，出bug了，再说一遍罢了"
            }
        }

        // 检索与用户输入相关的记忆
        let memoryContext = store.generateMemoryContext(query: userText)

        let enhancedPrompt = """
        \(SilverWolfPersona.systemPrompt)

        【当前场景】小黎正在\(currentScene.description)
        【关于小黎的相关记忆】\(memoryContext)

        请结合以上记忆和场景，回复小黎说的："\(userText)"
        要求：
        1. 叫用户"小黎"
        2. 如果记忆中有相关信息，可以自然地提到（比如"我记得你说过..."）
        3. 结合当前场景
        4. 银狼人设，自然回复
        5. 不超过50个字
        """

        do {
            let response = try await aiService.generateResponse(
                systemPrompt: enhancedPrompt,
                messages: []
            )
            return SilverWolfPersona.polish(response)
        } catch {
            return "小黎，啧，出bug了，再说一遍罢了"
        }
    }

    // MARK: - 记忆提取与保存
    private func extractAndSaveMemories(from text: String) {
        let extracted = MemoryExtractor.shared.extractMemories(from: text, role: "user")

        for memory in extracted where MemoryExtractor.shared.shouldSave(memory) {
            memoryStore?.addMemory(
                type: memory.type,
                category: memory.category,
                content: memory.content,
                importance: memory.importance,
                source: "对话提取"
            )
            lastMemorySaved = memory.content
        }
    }

    // MARK: - 气泡显示
    func showBubble(_ text: String) {
        currentBubbleText = text
        showChatBubble = true
        isTalking = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            self?.showChatBubble = false
            self?.isTalking = false
        }
    }

    // MARK: - 消息管理
    func addMessage(_ text: String) {
        let msg = CompanionMessage(role: "silverwolf", content: text, timestamp: Date())
        companionMessages.append(msg)
        if companionMessages.count > 20 {
            companionMessages.removeFirst()
        }
    }

    // MARK: - 设置
    func setAutoChatInterval(_ seconds: Double) {
        autoChatInterval = seconds
        if isCompanionMode && autoChatEnabled {
            startAutoChat()
        }
    }

    func toggleAutoChat() {
        autoChatEnabled.toggle()
        if autoChatEnabled && isCompanionMode {
            startAutoChat()
        } else {
            stopAutoChat()
        }
    }

    func toggleAutoSceneDetect() {
        autoSceneDetectEnabled.toggle()
        if autoSceneDetectEnabled && isCompanionMode {
            startSceneMonitor()
        } else {
            stopSceneMonitor()
        }
    }

    // MARK: - 记忆统计
    var memoryStats: String {
        guard let store = memoryStore else { return "记忆功能未启用" }
        let stats = store.stats
        return "共\(stats.total)条记忆 | 偏好\(stats.byType[.preference] ?? 0) | 习惯\(stats.byType[.habit] ?? 0) | 事实\(stats.byType[.fact] ?? 0)"
    }
}

// MARK: - 陪伴场景枚举
enum CompanionScene: String, CaseIterable, Identifiable {
    case scrolling = "刷手机"
    case video = "看视频"
    case novel = "看小说"
    case shopping = "购物"
    case working = "工作"
    case gaming = "打游戏"
    case sleepy = "准备睡觉"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .scrolling: return "hand.point.up.left.fill"
        case .video: return "play.rectangle.fill"
        case .novel: return "book.fill"
        case .shopping: return "cart.fill"
        case .working: return "laptopcomputer"
        case .gaming: return "gamecontroller.fill"
        case .sleepy: return "moon.fill"
        }
    }

    var description: String {
        switch self {
        case .scrolling: return "刷手机"
        case .video: return "看视频"
        case .novel: return "看小说"
        case .shopping: return "购物"
        case .working: return "工作/学习"
        case .gaming: return "打游戏"
        case .sleepy: return "准备睡觉"
        }
    }
}

// MARK: - 陪伴消息模型
struct CompanionMessage: Identifiable, Equatable {
    let id = UUID()
    let role: String
    let content: String
    let timestamp: Date
}
