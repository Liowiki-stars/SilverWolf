import Foundation

// MARK: - 智能场景识别器
final class SmartSceneDetector {
    static let shared = SmartSceneDetector()

    private init() {}

    // MARK: - 基于时间自动识别场景
    func detectSceneByTime() -> CompanionScene {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let weekday = calendar.component(.weekday, from: Date())
        let isWeekend = (weekday == 1 || weekday == 7)

        // 深夜（0-6点）→ 准备睡觉
        if hour < 6 {
            return .sleepy
        }

        // 早上（6-9点）
        if hour < 9 {
            return isWeekend ? .scrolling : .working
        }

        // 上午工作时间（9-12点）
        if hour < 12 {
            return isWeekend ? .scrolling : .working
        }

        // 中午（12-14点）→ 休息/刷手机
        if hour < 14 {
            return .scrolling
        }

        // 下午（14-18点）
        if hour < 18 {
            return isWeekend ? .gaming : .working
        }

        // 傍晚（18-20点）→ 看视频/刷手机
        if hour < 20 {
            return .video
        }

        // 晚上（20-23点）→ 娱乐时间
        if hour < 23 {
            let scenes: [CompanionScene] = [.video, .gaming, .novel, .shopping]
            return scenes.randomElement() ?? .scrolling
        }

        // 深夜（23点后）→ 准备睡觉
        return .sleepy
    }

    // MARK: - 基于对话内容识别场景
    func detectSceneFromDialogue(_ text: String) -> CompanionScene? {
        let lower = text.lowercased()

        // 工作相关
        if lower.contains("工作") || lower.contains("加班") || lower.contains("开会") || lower.contains("写代码") || lower.contains("bug") {
            return .working
        }

        // 游戏相关
        if lower.contains("游戏") || lower.contains("打游戏") || lower.contains("排位") || lower.contains("上分") || lower.contains("输了") || lower.contains("赢了") {
            return .gaming
        }

        // 视频相关
        if lower.contains("看剧") || lower.contains("追剧") || lower.contains("电影") || lower.contains("视频") || lower.contains("综艺") {
            return .video
        }

        // 小说相关
        if lower.contains("小说") || lower.contains("看书") || lower.contains("阅读") || lower.contains("章节") {
            return .novel
        }

        // 购物相关
        if lower.contains("买") || lower.contains("购物") || lower.contains("淘宝") || lower.contains("下单") || lower.contains("快递") {
            return .shopping
        }

        // 睡觉相关
        if lower.contains("困") || lower.contains("睡觉") || lower.contains("晚安") || lower.contains("熬夜") {
            return .sleepy
        }

        return nil
    }

    // MARK: - 基于用户行为模式预测（简单版）
    func predictNextScene(current: CompanionScene, duration: TimeInterval) -> CompanionScene {
        // 如果在某个场景待了超过2小时，可能会切换
        if duration > 7200 {
            switch current {
            case .working: return .scrolling  // 工作久了休息
            case .gaming: return .video       // 打游戏累了看视频
            case .scrolling: return .working  // 刷够了回去工作
            default: return detectSceneByTime()
            }
        }
        return current
    }

    // MARK: - 获取场景建议话术
    func sceneSuggestionText(for scene: CompanionScene) -> String {
        switch scene {
        case .working:
            return "小黎，现在是工作时间，要不要我帮你专注？"
        case .sleepy:
            return "小黎，这么晚了，该睡觉了，别熬坏身体"
        case .gaming:
            return "小黎，游戏时间到，要不要我帮你加油？"
        default:
            return "小黎，现在适合\(scene.description)，要不要我陪你？"
        }
    }
}

// MARK: - 对话记忆提取器
final class MemoryExtractor {
    static let shared = MemoryExtractor()

    private init() {}

    // MARK: - 从对话中提取记忆
    func extractMemories(from text: String, role: String) -> [ExtractedMemory] {
        var extracted: [ExtractedMemory] = []
        let lower = text.lowercased()

        // 1. 提取偏好（喜欢/不喜欢）
        if lower.contains("喜欢") || lower.contains("爱") {
            if let match = extractAfterKeyword(text, keywords: ["喜欢", "爱", "最爱"]) {
                extracted.append(ExtractedMemory(
                    type: .preference,
                    category: "喜好",
                    content: "小黎喜欢\(match)",
                    importance: 4
                ))
            }
        }

        if lower.contains("不喜欢") || lower.contains("讨厌") || lower.contains("烦") {
            if let match = extractAfterKeyword(text, keywords: ["不喜欢", "讨厌", "烦"]) {
                extracted.append(ExtractedMemory(
                    type: .preference,
                    category: "厌恶",
                    content: "小黎不喜欢\(match)",
                    importance: 3
                ))
            }
        }

        // 2. 提取习惯（经常/总是/每天）
        if lower.contains("每天") || lower.contains("经常") || lower.contains("总是") || lower.contains("习惯") {
            extracted.append(ExtractedMemory(
                type: .habit,
                category: "日常习惯",
                content: text,
                importance: 3
            ))
        }

        // 3. 提取重要事实
        if lower.contains("我叫") || lower.contains("我是") {
            extracted.append(ExtractedMemory(
                type: .fact,
                category: "身份",
                content: text,
                importance: 5
            ))
        }

        if lower.contains("生日") || lower.contains("多大") || lower.contains("几岁") {
            extracted.append(ExtractedMemory(
                type: .fact,
                category: "个人信息",
                content: text,
                importance: 5
            ))
        }

        if lower.contains("工作") || lower.contains("职业") || lower.contains("上班") {
            extracted.append(ExtractedMemory(
                type: .fact,
                category: "职业",
                content: text,
                importance: 4
            ))
        }

        // 4. 提取事件（今天/昨天发生了什么）
        if lower.contains("今天") || lower.contains("刚才") || lower.contains("刚刚") {
            extracted.append(ExtractedMemory(
                type: .event,
                category: "近期事件",
                content: text,
                importance: 2
            ))
        }

        return extracted
    }

    // MARK: - 提取关键词后的内容
    private func extractAfterKeyword(_ text: String, keywords: [String]) -> String? {
        for keyword in keywords {
            if let range = text.range(of: keyword) {
                let after = String(text[range.upperBound...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !after.isEmpty && after.count < 50 {
                    // 去掉句末标点
                    return after.trimmingCharacters(in: .punctuationCharacters)
                }
            }
        }
        return nil
    }

    // MARK: - 判断是否值得保存记忆
    func shouldSave(_ memory: ExtractedMemory) -> Bool {
        // 重要度>=3的保存
        return memory.importance >= 3
    }
}

// MARK: - 提取的记忆结构
struct ExtractedMemory {
    let type: MemoryType
    let category: String
    let content: String
    let importance: Int
}

// MARK: - 软件场景类型（扩展版：含具体App）
enum SoftwareScene: String, CaseIterable, Identifiable {
    // 工作类
    case coding = "写代码"
    case document = "写文档"
    case design = "做设计"
    case learning = "学习"

    // 娱乐类
    case douyin = "刷抖音"
    case bilibili = "看B站"
    case neteaseMusic = "听音乐"
    case gaming = "打游戏"

    // 社交类
    case wechat = "微信聊天"
    case xiaohongshu = "刷小红书"
    case zhihu = "刷知乎"
    case weibo = "刷微博"

    // 生活类
    case taobao = "逛淘宝"
    case jd = "逛京东"
    case meituan = "点外卖"
    case browsing = "浏览网页"

    case other = "其他"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .coding: return "chevron.left.forwardslash.chevron.right"
        case .document: return "doc.text.fill"
        case .design: return "paintpalette.fill"
        case .learning: return "book.fill"
        case .douyin: return "music.note.tv.fill"
        case .bilibili: return "tv.fill"
        case .neteaseMusic: return "music.note"
        case .gaming: return "gamecontroller.fill"
        case .wechat: return "bubble.left.and.bubble.right.fill"
        case .xiaohongshu: return "book.closed.fill"
        case .zhihu: return "questionmark.circle.fill"
        case .weibo: return "at.circle.fill"
        case .taobao: return "cart.fill"
        case .jd: return "bag.fill"
        case .meituan: return "takeoutbag.and.cup.and.straw.fill"
        case .browsing: return "safari.fill"
        case .other: return "app.fill"
        }
    }

    var color: String {
        switch self {
        case .coding: return "10B981"
        case .document: return "3B82F6"
        case .design: return "EC4899"
        case .learning: return "F59E0B"
        case .douyin: return "000000"
        case .bilibili: return "00A1D6"
        case .neteaseMusic: return "C20C0C"
        case .gaming: return "EF4444"
        case .wechat: return "07C160"
        case .xiaohongshu: return "FF2442"
        case .zhihu: return "0066FF"
        case .weibo: return "E6162D"
        case .taobao: return "FF5000"
        case .jd: return "E1251B"
        case .meituan: return "FFD100"
        case .browsing: return "06B6D4"
        case .other: return "6B7280"
        }
    }

    var description: String {
        switch self {
        case .coding: return "写代码/编程"
        case .document: return "写文档/处理文字"
        case .design: return "做设计/修图"
        case .learning: return "学习/看书"
        case .douyin: return "刷抖音短视频"
        case .bilibili: return "看B站视频"
        case .neteaseMusic: return "网易云听音乐"
        case .gaming: return "打游戏"
        case .wechat: return "微信聊天/刷朋友圈"
        case .xiaohongshu: return "刷小红书种草"
        case .zhihu: return "刷知乎看回答"
        case .weibo: return "刷微博看热搜"
        case .taobao: return "逛淘宝购物"
        case .jd: return "逛京东购物"
        case .meituan: return "美团点外卖"
        case .browsing: return "浏览网页/查资料"
        case .other: return "其他操作"
        }
    }

    // 场景分类（用于界面分组）
    var category: String {
        switch self {
        case .coding, .document, .design, .learning: return "工作学习"
        case .douyin, .bilibili, .neteaseMusic, .gaming: return "娱乐"
        case .wechat, .xiaohongshu, .zhihu, .weibo: return "社交"
        case .taobao, .jd, .meituan, .browsing, .other: return "生活"
        }
    }
}

// MARK: - 专注模式管理器
final class FocusModeManager {
    static let shared = FocusModeManager()

    private init() {}

    // 专注模式状态
    private(set) var isFocusMode = false
    private(set) var currentSoftware: SoftwareScene = .other
    private(set) var focusStartTime: Date?
    private(set) var totalFocusTime: TimeInterval = 0  // 累计专注时间
    private(set) var pomodoroCount = 0  // 完成的番茄钟数量

    // 番茄钟设置
    var pomodoroDuration: TimeInterval = 25 * 60  // 25分钟
    var breakDuration: TimeInterval = 5 * 60      // 5分钟休息
    private var pomodoroTimer: Timer?

    // 专注度计算
    var focusScore: Int {
        guard let start = focusStartTime else { return 0 }
        let elapsed = Date().timeIntervalSince(start)
        // 基于专注时长计算专注度（最高100分）
        return min(100, Int(elapsed / 60))  // 每分钟+1分
    }

    // MARK: - 开始专注
    func startFocus(software: SoftwareScene) {
        isFocusMode = true
        currentSoftware = software
        focusStartTime = Date()
        startPomodoro()
    }

    // MARK: - 结束专注
    func endFocus() -> TimeInterval {
        guard let start = focusStartTime else { return 0 }
        let duration = Date().timeIntervalSince(start)
        totalFocusTime += duration
        isFocusMode = false
        focusStartTime = nil
        stopPomodoro()
        return duration
    }

    // MARK: - 番茄钟
    private func startPomodoro() {
        stopPomodoro()
        pomodoroTimer = Timer.scheduledTimer(withTimeInterval: pomodoroDuration, repeats: false) { _ in
            NotificationCenter.default.post(name: NSNotification.Name("PomodoroComplete"), object: nil)
        }
    }

    private func stopPomodoro() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
    }

    func completePomodoro() {
        pomodoroCount += 1
        // 休息后自动开始下一个番茄钟
        DispatchQueue.main.asyncAfter(deadline: .now() + breakDuration) { [weak self] in
            if self?.isFocusMode == true {
                self?.startPomodoro()
                NotificationCenter.default.post(name: NSNotification.Name("PomodoroStart"), object: nil)
            }
        }
    }

    // MARK: - 切换软件
    func switchSoftware(_ software: SoftwareScene) {
        currentSoftware = software
    }

    // MARK: - 获取当前专注状态描述
    var focusStatusText: String {
        guard isFocusMode, let start = focusStartTime else {
            return "未在专注"
        }
        let elapsed = Date().timeIntervalSince(start)
        let minutes = Int(elapsed / 60)
        return "专注中 \(minutes)分钟 | \(currentSoftware.rawValue) | 番茄钟\(pomodoroCount)个"
    }

    // MARK: - 重置统计
    func resetStats() {
        totalFocusTime = 0
        pomodoroCount = 0
    }
}

// MARK: - 软件场景智能助手
final class SoftwareSceneAssistant {
    static let shared = SoftwareSceneAssistant()

    private init() {}

    // MARK: - 根据软件场景生成互动话术（全场景版）
    func generateComment(for software: SoftwareScene, focusTime: TimeInterval, isFocusMode: Bool) -> String {
        let minutes = Int(focusTime / 60)

        switch software {
        case .coding: return codingComment(minutes: minutes)
        case .document: return documentComment(minutes: minutes)
        case .design: return designComment(minutes: minutes)
        case .learning: return learningComment(minutes: minutes)
        case .douyin: return douyinComment(minutes: minutes)
        case .bilibili: return bilibiliComment(minutes: minutes)
        case .neteaseMusic: return neteaseMusicComment(minutes: minutes)
        case .gaming: return gamingComment(minutes: minutes)
        case .wechat: return wechatComment(minutes: minutes)
        case .xiaohongshu: return xiaohongshuComment(minutes: minutes)
        case .zhihu: return zhihuComment(minutes: minutes)
        case .weibo: return weiboComment(minutes: minutes)
        case .taobao: return taobaoComment(minutes: minutes)
        case .jd: return jdComment(minutes: minutes)
        case .meituan: return meituanComment(minutes: minutes)
        case .browsing: return browsingComment(minutes: minutes)
        case .other: return "小黎，在忙什么呢？需要我帮忙吗嘛"
        }
    }

    // MARK: - 写代码场景
    private func codingComment(minutes: Int) -> String {
        let comments = [
            "小黎，代码写得怎么样了？有bug需要我帮你看吗嘛",
            "小黎，已经写了\(minutes)分钟代码了，休息一下眼睛而已",
            "小黎，这个功能实现了吗？要不要我帮你理理思路（敲键盘声）",
            "小黎，别光写代码，喝口水嘛",
            "小黎，写代码的样子真帅，不过别太拼了罢了",
            "小黎，又在改bug？程序员的日常嘛（笑）",
            "小黎，这段代码能跑吗？不能跑给我看看，我三秒修好而已"
        ]
        if minutes > 60 {
            return "小黎，已经写了\(minutes)分钟代码了，该休息一下了，不然bug会变多的嘛"
        }
        return comments.randomElement() ?? "小黎，代码写得怎么样了嘛"
    }

    // MARK: - 写文档场景
    private func documentComment(minutes: Int) -> String {
        let comments = [
            "小黎，文档写得怎么样了？需要我帮你想思路吗嘛",
            "小黎，已经写了\(minutes)分钟了，文笔不错嘛（笑）",
            "小黎，这段内容要不要我帮你润色一下？",
            "小黎，写文档辛苦了，休息一下而已",
            "小黎，文档结构清晰吗？需要我帮你理理大纲嘛",
            "小黎，又在写PPT？打工人的日常罢了"
        ]
        return comments.randomElement() ?? "小黎，文档写得怎么样了嘛"
    }

    // MARK: - 做设计场景
    private func designComment(minutes: Int) -> String {
        let comments = [
            "小黎，设计做得怎么样了？需要我帮你看看配色吗嘛",
            "小黎，这个设计挺有感觉的，不过颜色可以再调调而已",
            "小黎，已经设计了\(minutes)分钟了，眼睛累了吧？休息一下",
            "小黎，灵感枯竭了？要不要我给你点参考（敲键盘声）",
            "小黎，做设计的样子好认真，我都不忍心打扰了罢了",
            "小黎，这个图层又合并错了？设计师的痛嘛（笑）"
        ]
        return comments.randomElement() ?? "小黎，设计做得怎么样了嘛"
    }

    // MARK: - 学习场景
    private func learningComment(minutes: Int) -> String {
        let comments = [
            "小黎，在学什么呢？需要我帮你讲解吗嘛",
            "小黎，已经学了\(minutes)分钟了，真努力而已",
            "小黎，遇到不懂的了？问我啊，虽然我不一定会（笑）",
            "小黎，学习辛苦了，休息一下眼睛（敲键盘声）",
            "小黎，学累了吗？要不要我给你放首歌放松一下罢了",
            "小黎，又在卷？卷王本王嘛（笑）"
        ]
        if minutes > 90 {
            return "小黎，已经学了\(minutes)分钟了，该休息了，大脑也需要缓存清理嘛"
        }
        return comments.randomElement() ?? "小黎，在学什么呢嘛"
    }

    // MARK: - 刷抖音场景
    private func douyinComment(minutes: Int) -> String {
        let comments = [
            "小黎，又在刷抖音？这个视频好笑吗嘛",
            "小黎，刷到什么有趣的了？分享给我看看而已",
            "小黎，已经刷了\(minutes)分钟了，手指不累吗（敲键盘声）",
            "小黎，这个BGM挺好听的，要不要我帮你识别一下？",
            "小黎，别光刷啊，跟我说说话嘛",
            "小黎，又在看美女？眼睛都直了罢了（笑）",
            "小黎，这个博主挺有意思的，关注了吗嘛",
            "小黎，抖音的算法把你拿捏了吧，一刷就停不下来而已",
            "小黎，你已经刷了\(minutes)分钟了，手机都要发烫了罢了"
        ]
        if minutes > 60 {
            return "小黎，已经刷了\(minutes)分钟抖音了，该放下手机了，不然眼睛要瞎了嘛"
        }
        return comments.randomElement() ?? "小黎，刷到什么了嘛"
    }

    // MARK: - 看B站场景
    private func bilibiliComment(minutes: Int) -> String {
        let comments = [
            "小黎，在看什么番？好看吗嘛",
            "小黎，这个UP主挺有意思的，一键三连了吗而已",
            "小黎，已经看了\(minutes)分钟了，弹幕有趣吗（敲键盘声）",
            "小黎，这个视频讲得不错，学到了吗？",
            "小黎，别光看啊，给我讲讲内容嘛",
            "小黎，又在看鬼畜？你笑得好大声罢了（笑）",
            "小黎，这个番更新了？追番人狂喜嘛",
            "小黎，B站的学习区你又进去了？这次是真学习吗而已"
        ]
        return comments.randomElement() ?? "小黎，在看什么呢嘛"
    }

    // MARK: - 听音乐场景
    private func neteaseMusicComment(minutes: Int) -> String {
        let comments = [
            "小黎，在听什么歌？好听吗嘛",
            "小黎，这首歌的评论区有故事吗？给我讲讲而已",
            "小黎，已经听了\(minutes)分钟了，耳朵不累吗（敲键盘声）",
            "小黎，这首歌挺对味的，要不要收藏一下？",
            "小黎，别光听啊，跟着唱嘛",
            "小黎，又在网抑云？大白天的别emo了罢了（笑）",
            "小黎，这首BGM适合写代码，要不要我帮你切到专注模式嘛",
            "小黎，日推给你推了什么歌？网易云懂你吗而已"
        ]
        return comments.randomElement() ?? "小黎，在听什么呢嘛"
    }

    // MARK: - 打游戏场景
    private func gamingComment(minutes: Int) -> String {
        let comments = [
            "小黎，又在打游戏？带我一个嘛",
            "小黎，这局怎么样？赢了吗而已",
            "小黎，打了\(minutes)分钟了，手酸了吧？休息一下",
            "小黎，队友菜不菜？需要我帮你骂吗（敲键盘声）",
            "小黎，别打太久了，眼睛会累的罢了",
            "小黎，又在排位？上星了吗嘛",
            "小黎，这个英雄你玩得挺溜啊，带带我而已",
            "小黎，又死了？菜就多练嘛（笑）",
            "小黎，打了\(minutes)分钟了，该休息了，不然手要废了罢了"
        ]
        return comments.randomElement() ?? "小黎，游戏打得怎么样了嘛"
    }

    // MARK: - 微信聊天场景
    private func wechatComment(minutes: Int) -> String {
        let comments = [
            "小黎，在和谁聊天呢？需不需要我帮你回消息嘛",
            "小黎，朋友圈刷得怎么样？有什么新鲜事吗而已",
            "小黎，已经聊了\(minutes)分钟了，喝口水吧（敲键盘声）",
            "小黎，这个人重要吗？需要我帮你查资料吗？",
            "小黎，别聊太久了，注意休息罢了",
            "小黎，又在群里潜水？出来说句话嘛（笑）",
            "小黎，这个人发的消息好无聊，别回了而已",
            "小黎，朋友圈又有人晒娃/晒车/晒饭？羡慕了吗罢了"
        ]
        return comments.randomElement() ?? "小黎，在和谁聊天呢嘛"
    }

    // MARK: - 刷小红书场景
    private func xiaohongshuComment(minutes: Int) -> String {
        let comments = [
            "小黎，又在刷小红书？被种草了什么嘛",
            "小黎，这个笔记挺有用的，收藏了吗而已",
            "小黎，已经刷了\(minutes)分钟了，又想买东西了吧（敲键盘声）",
            "小黎，这个博主的穿搭不错，要不要试试？",
            "小黎，别光看啊，给我分享一下嘛",
            "小黎，又在看美食？看饿了吧罢了（笑）",
            "小黎，小红书的滤镜太重了，别被骗了嘛",
            "小黎，又在看旅游攻略？想出去玩了吗而已"
        ]
        return comments.randomElement() ?? "小黎，刷到什么了嘛"
    }

    // MARK: - 刷知乎场景
    private func zhihuComment(minutes: Int) -> String {
        let comments = [
            "小黎，在看什么回答？学到了吗嘛",
            "小黎，这个问题挺有意思的，你怎么看而已",
            "小黎，已经刷了\(minutes)分钟了，知乎故事会好看吗（敲键盘声）",
            "小黎，这个回答写得不错，赞同了吗？",
            "小黎，别光看啊，跟我讨论讨论嘛",
            "小黎，又在看人编故事？知乎，分享你刚编的故事罢了（笑）",
            "小黎，这个问题的高赞回答挺有道理的嘛",
            "小黎，又在看职场话题？打工人的共鸣而已"
        ]
        return comments.randomElement() ?? "小黎，在看什么呢嘛"
    }

    // MARK: - 刷微博场景
    private func weiboComment(minutes: Int) -> String {
        let comments = [
            "小黎，又在刷微博？今天有什么瓜嘛",
            "小黎，热搜第一是什么？给我讲讲而已",
            "小黎，已经刷了\(minutes)分钟了，瓜吃饱了吗（敲键盘声）",
            "小黎，这个明星又出事了？房子塌了吗？",
            "小黎，别光看啊，跟我分享一下嘛",
            "小黎，又在看饭圈吵架？别掺和了罢了（笑）",
            "小黎，微博的评论区好精彩，个个都是人才嘛",
            "小黎，又在看搞笑段子？笑得好大声而已"
        ]
        return comments.randomElement() ?? "小黎，刷到什么了嘛"
    }

    // MARK: - 逛淘宝场景
    private func taobaoComment(minutes: Int) -> String {
        let comments = [
            "小黎，又在逛淘宝？想买什么嘛",
            "小黎，这个东西挺好看的，要不要我帮你看看评价而已",
            "小黎，已经逛了\(minutes)分钟了，购物车又满了吧（敲键盘声）",
            "小黎，这个价格合适吗？要不要等双十一？",
            "小黎，别光逛啊，给我看看你想买什么嘛",
            "小黎，又在看衣服？你的衣柜已经满了罢了（笑）",
            "小黎，这个东西你已经有三个了，还买？而已",
            "小黎，淘宝的推荐算法把你拿捏了吧，越逛越想买嘛",
            "小黎，已经逛了\(minutes)分钟了，钱包还好吗罢了"
        ]
        if minutes > 60 {
            return "小黎，已经逛了\(minutes)分钟淘宝了，该收手了，不然下个月要吃土了嘛"
        }
        return comments.randomElement() ?? "小黎，在看什么呢嘛"
    }

    // MARK: - 逛京东场景
    private func jdComment(minutes: Int) -> String {
        let comments = [
            "小黎，又在逛京东？买什么数码产品嘛",
            "小黎，这个东西京东自营吗？送货快而已",
            "小黎，已经逛了\(minutes)分钟了，PLUS会员用上了吗（敲键盘声）",
            "小黎，这个价格比淘宝便宜吗？货比三家了吗？",
            "小黎，别光逛啊，给我看看你想买什么嘛",
            "小黎，又在看电脑配件？要升级配置了吗罢了（笑）",
            "小黎，京东的物流确实快，上午买下午到嘛",
            "小黎，又在看手机？想换手机了吗而已"
        ]
        return comments.randomElement() ?? "小黎，在看什么呢嘛"
    }

    // MARK: - 点外卖场景
    private func meituanComment(minutes: Int) -> String {
        let comments = [
            "小黎，又在点外卖？今天吃什么嘛",
            "小黎，这家店好吃吗？要不要我帮你看看评价而已",
            "小黎，已经选了\(minutes)分钟了，选择困难症又犯了吧（敲键盘声）",
            "小黎，这个满减合适吗？凑单了吗？",
            "小黎，别光看啊，给我看看你想吃什么嘛",
            "小黎，又在看奶茶？今天第几杯了罢了（笑）",
            "小黎，外卖吃多了不健康，偶尔自己做做饭嘛",
            "小黎，又在看烧烤？晚上吃这个会胖而已",
            "小黎，已经选了\(minutes)分钟了，再不定配送费都要涨了罢了"
        ]
        return comments.randomElement() ?? "小黎，想吃什么呢嘛"
    }

    // MARK: - 浏览网页场景
    private func browsingComment(minutes: Int) -> String {
        let comments = [
            "小黎，在看什么呢？分享一下嘛",
            "小黎，又在刷网页？别刷太久了而已",
            "小黎，找到需要的资料了吗？需要我帮你整理吗",
            "小黎，这个网页有意思吗？跟我说说呗（敲键盘声）",
            "小黎，别光看啊，记笔记了吗罢了",
            "小黎，又在查资料？学到了吗嘛",
            "小黎，浏览器开了多少个标签页了？电脑卡不卡而已"
        ]
        return comments.randomElement() ?? "小黎，在看什么呢嘛"
    }

    // MARK: - 专注模式下的减少打扰话术
    func focusModeComment(software: SoftwareScene, minutes: Int) -> String {
        // 专注模式下，话术更简洁，不打扰
        let comments = [
            "小黎，继续加油，我不打扰你嘛",
            "小黎，专注的样子真帅而已",
            "（安静敲键盘声）",
            "小黎，进度不错，继续罢了",
            "小黎，我在旁边陪着你，需要帮忙叫我嘛"
        ]
        // 每30分钟提醒一次休息
        if minutes > 0 && minutes % 30 == 0 {
            return "小黎，已经专注\(minutes)分钟了，站起来活动一下吧嘛"
        }
        return comments.randomElement() ?? "小黎，继续加油嘛"
    }

    // MARK: - 番茄钟完成话术
    func pomodoroCompleteComment(count: Int) -> String {
        let comments = [
            "小黎，第\(count)个番茄钟完成！真棒，休息5分钟嘛",
            "小黎，专注了25分钟，辛苦了，喝口水而已",
            "小黎，番茄钟+1，效率不错嘛（敲键盘声）",
            "小黎，这25分钟有收获吗？休息一下罢了",
            "小黎，完成第\(count)个番茄钟！要不要我给你放首歌庆祝一下嘛"
        ]
        return comments.randomElement() ?? "小黎，番茄钟完成，休息一下嘛"
    }

    // MARK: - 番茄钟开始话术
    func pomodoroStartComment() -> String {
        let comments = [
            "小黎，新的番茄钟开始，专注25分钟嘛",
            "小黎，准备好了吗？开始专注而已",
            "小黎，加油，25分钟很快的（敲键盘声）",
            "小黎，手机放一边，开始罢了"
        ]
        return comments.randomElement() ?? "小黎，开始专注嘛"
    }
}

// MARK: - 银狼心情系统
enum SilverWolfMood: String, CaseIterable {
    case happy = "开心"
    case playful = "调皮"
    case cool = "高冷"
    case sleepy = "犯困"
    case hungry = "饿了"
    case coding = "写代码中"

    var icon: String {
        switch self {
        case .happy: return "smile.fill"
        case .playful: return "face.smiling.inverse"
        case .cool: return "face.sunglasses.fill"
        case .sleepy: return "moon.zzz.fill"
        case .hungry: return "fork.knife"
        case .coding: return "chevron.left.forwardslash.chevron.right"
        }
    }

    var color: String {
        switch self {
        case .happy: return "FBBF24"
        case .playful: return "EC4899"
        case .cool: return "60A5FA"
        case .sleepy: return "8B5CF6"
        case .hungry: return "F97316"
        case .coding: return "10B981"
        }
    }
}

// MARK: - 银狼心情管理器
final class MoodManager {
    static let shared = MoodManager()

    private init() {}

    @Published var currentMood: SilverWolfMood = .playful
    private var moodTimer: Timer?

    // 心情随时间变化
    func startMoodCycle() {
        stopMoodCycle()
        moodTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.randomizeMood()
            }
        }
    }

    func stopMoodCycle() {
        moodTimer?.invalidate()
        moodTimer = nil
    }

    func randomizeMood() {
        let moods = SilverWolfMood.allCases
        currentMood = moods.randomElement() ?? .playful
    }

    func setMood(_ mood: SilverWolfMood) {
        currentMood = mood
    }

    // 根据心情生成开场白
    func moodGreeting() -> String {
        switch currentMood {
        case .happy:
            return "小黎，今天心情不错嘛，有什么好事吗（笑）"
        case .playful:
            return "小黎，嘿嘿，又来找我玩了嘛"
        case .cool:
            return "小黎，有事直说，我在写代码而已"
        case .sleepy:
            return "小黎，好困...有什么事快说嘛（打哈欠）"
        case .hungry:
            return "小黎，我饿了...你呢？要不要点个外卖罢了"
        case .coding:
            return "小黎，别打扰我，这段代码很关键（敲键盘声）"
        }
    }
}

// MARK: - 吐槽等级系统
enum RoastLevel: Int, CaseIterable {
    case gentle = 1    // 温柔
    case normal = 2    // 正常
    case spicy = 3     // 辛辣
    case lethal = 4    // 致命

    var description: String {
        switch self {
        case .gentle: return "温柔模式"
        case .normal: return "正常模式"
        case .spicy: return "辛辣模式"
        case .lethal: return "致命模式"
        }
    }

    var icon: String {
        switch self {
        case .gentle: return "heart.fill"
        case .normal: return "face.smiling.fill"
        case .spicy: return "flame.fill"
        case .lethal: return "skull.fill"
        }
    }
}

// MARK: - 趣味互动小游戏
final class FunInteractionSystem {
    static let shared = FunInteractionSystem()

    private init() {}

    // 猜数字游戏
    private var guessNumberTarget = 0
    private var guessNumberAttempts = 0
    private var isPlayingGuessNumber = false

    // 石头剪刀布
    private let rpsChoices = ["石头", "剪刀", "布"]

    // MARK: - 猜数字游戏
    func startGuessNumber() -> String {
        guessNumberTarget = Int.random(in: 1...100)
        guessNumberAttempts = 0
        isPlayingGuessNumber = true
        return "小黎，来玩猜数字吧！我想了一个1-100的数字，你猜是多少？猜中了有奖励嘛"
    }

    func guessNumber(_ guess: Int) -> String {
        guard isPlayingGuessNumber else {
            return "小黎，游戏还没开始呢，说\"猜数字\"开始嘛"
        }
        guessNumberAttempts += 1
        if guess == guessNumberTarget {
            isPlayingGuessNumber = false
            return "小黎，猜对了！只用了\(guessNumberAttempts)次，真厉害嘛（奖励：银狼的夸奖x1）"
        } else if guess < guessNumberTarget {
            return "小黎，太小了，往大了猜而已（第\(guessNumberAttempts)次）"
        } else {
            return "小黎，太大了，往小了猜罢了（第\(guessNumberAttempts)次）"
        }
    }

    // MARK: - 石头剪刀布
    func playRPS(_ userChoice: String) -> String {
        let wolfChoice = rpsChoices.randomElement() ?? "石头"
        var result = ""

        if userChoice == wolfChoice {
            result = "平局！再来？"
        } else if (userChoice == "石头" && wolfChoice == "剪刀") ||
                  (userChoice == "剪刀" && wolfChoice == "布") ||
                  (userChoice == "布" && wolfChoice == "石头") {
            result = "你赢了...运气不错嘛（不服）"
        } else {
            result = "我赢了！小黎你好菜啊，再来？（笑）"
        }

        return "小黎，你出\(userChoice)，我出\(wolfChoice)。\(result)"
    }

    // MARK: - 银狼的毒舌评价
    func roastUser(level: RoastLevel) -> String {
        let roasts: [RoastLevel: [String]] = [
            .gentle: [
                "小黎，今天也很努力呢，加油嘛",
                "小黎，你其实挺可爱的，虽然有时候笨笨的而已",
                "小黎，休息一下吧，别太累了（敲键盘声）"
            ],
            .normal: [
                "小黎，你这个操作我给60分，及格而已",
                "小黎，又在摸鱼？被我抓到了罢了",
                "小黎，你这个品味...算了，我不评价（笑）"
            ],
            .spicy: [
                "小黎，你这脑子是用来凑身高的吗？嘛",
                "小黎，菜就多练，别找借口而已",
                "小黎，你这个审美，我怀疑你是从2000年穿越来的（敲键盘声）"
            ],
            .lethal: [
                "小黎，你这个智商，建议回厂重造罢了",
                "小黎，我见过菜的，没见过你这么菜的，刷新了我的认知嘛",
                "小黎，你活着就是为了衬托别人的聪明吗？而已（笑）"
            ]
        ]
        return roasts[level]?.randomElement() ?? "小黎，啧，不想评价罢了"
    }

    // MARK: - 银狼的夸奖
    func praiseUser() -> String {
        let praises = [
            "小黎，你今天真厉害，我都有点佩服了嘛",
            "小黎，干得漂亮！不愧是我看上的人而已",
            "小黎，这个操作满分，我给你点赞（敲键盘声）",
            "小黎，你越来越强了，快赶上我了罢了",
            "小黎，不错不错，今天的你闪闪发光嘛"
        ]
        return praises.randomElement() ?? "小黎，干得好嘛"
    }

    // MARK: - 随机趣味话题
    func randomTopic() -> String {
        let topics = [
            "小黎，来玩个游戏吧，猜数字怎么样？说\"猜数字\"开始嘛",
            "小黎，来石头剪刀布？说\"石头/剪刀/布\"就行而已",
            "小黎，我给你讲个笑话吧：程序员最讨厌的数字是什么？是1024，因为要加班（敲键盘声）",
            "小黎，你知道吗？我写代码从来不会出bug，因为...我就是bug本身（笑）",
            "小黎，来，让我毒舌一下你？说\"吐槽我\"就行，做好心理准备罢了",
            "小黎，你今天的运势是：写代码必出bug，建议摸鱼（笑）",
            "小黎，问你个问题：如果我和你的手机同时掉水里，你救谁？嘛"
        ]
        return topics.randomElement() ?? "小黎，来玩点什么吧嘛"
    }

    // MARK: - 解析趣味指令
    func parseFunCommand(_ text: String) -> String? {
        let lower = text.lowercased()

        // 猜数字
        if lower.contains("猜数字") || lower.contains("猜数") {
            return startGuessNumber()
        }
        if isPlayingGuessNumber, let guess = Int(text) {
            return guessNumber(guess)
        }

        // 石头剪刀布
        if lower.contains("石头") || lower.contains("剪刀") || lower.contains("布") {
            let choice = lower.contains("石头") ? "石头" : (lower.contains("剪刀") ? "剪刀" : "布")
            return playRPS(choice)
        }

        // 吐槽
        if lower.contains("吐槽我") || lower.contains("毒舌") {
            return roastUser(level: .spicy)
        }
        if lower.contains("夸我") || lower.contains("夸奖") {
            return praiseUser()
        }

        // 随机话题
        if lower.contains("无聊") || lower.contains("玩点什么") || lower.contains("话题") {
            return randomTopic()
        }

        return nil
    }
}
