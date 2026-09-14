import Foundation

// MARK: - 操作意图类型
enum ActionIntent: String, CaseIterable {
    case orderFood = "点外卖"
    case shop = "购物"
    case playMusic = "听歌"
    case watchVideo = "看视频"
    case browseSocial = "刷社交"
    case navigate = "导航"
    case searchWeb = "搜索"
    case openApp = "打开App"
    case none = "无"

    var targetApp: TargetApp {
        switch self {
        case .orderFood: return .meituan
        case .shop: return .taobao
        case .playMusic: return .neteaseMusic
        case .watchVideo: return .bilibili
        case .browseSocial: return .weibo
        case .navigate: return .maps
        case .searchWeb: return .safari
        case .openApp: return .safari
        case .none: return .safari
        }
    }
}

// MARK: - 解析后的意图详情
struct ParsedIntent {
    let type: ActionIntent
    let keyword: String?          // 搜索关键词（食物名/商品名/歌曲名等）
    let targetApp: TargetApp?     // 指定的App
    let needsConfirmation: Bool   // 是否需要确认
    let confidence: Double        // 置信度 0-1

    var description: String {
        var desc = type.rawValue
        if let keyword = keyword {
            desc += "：\(keyword)"
        }
        if let app = targetApp {
            desc += "（\(app.rawValue)）"
        }
        return desc
    }
}

// MARK: - 意图识别器
final class IntentDetector {
    static let shared = IntentDetector()

    private init() {}

    // 从用户文本中识别意图
    func detectIntent(from text: String) -> ParsedIntent {
        let lower = text.lowercased()

        // 1. 点外卖意图
        if let food = detectFoodIntent(lower) {
            return food
        }

        // 2. 购物意图
        if let shop = detectShopIntent(lower) {
            return shop
        }

        // 3. 听歌意图
        if let music = detectMusicIntent(lower) {
            return music
        }

        // 4. 看视频意图
        if let video = detectVideoIntent(lower) {
            return video
        }

        // 5. 刷社交意图
        if let social = detectSocialIntent(lower) {
            return social
        }

        // 6. 导航意图
        if let nav = detectNavigationIntent(lower) {
            return nav
        }

        // 7. 搜索意图
        if let search = detectSearchIntent(lower) {
            return search
        }

        // 8. 打开App意图
        if let open = detectOpenAppIntent(lower) {
            return open
        }

        return ParsedIntent(type: .none, keyword: nil, targetApp: nil, needsConfirmation: false, confidence: 0)
    }

    // MARK: - 点外卖意图识别
    private func detectFoodIntent(_ text: String) -> ParsedIntent? {
        let foodKeywords = [
            "外卖", "点外卖", "吃饭", "吃什么", "饿了", "点餐",
            "奶茶", "咖啡", "汉堡", "披萨", "炸鸡", "烧烤", "火锅",
            "麻辣烫", "米线", "面条", "饺子", "炒饭", "盖饭", "寿司",
            "拉面", "黄焖鸡", "螺蛳粉", "小龙虾", "烤肉", "甜品"
        ]

        // 检测是否有外卖相关动词
        let actionWords = ["帮我点", "给我点", "我要点", "点个", "点一份", "想吃", "我想吃", "帮我买", "给我买"]
        let hasAction = actionWords.contains { text.contains($0) }

        // 检测食物关键词
        var matchedFood: String?
        for food in foodKeywords {
            if text.contains(food) {
                matchedFood = food
                break
            }
        }

        // 检测指定App
        var targetApp: TargetApp?
        if text.contains("美团") { targetApp = .meituan }
        if text.contains("饿了么") || text.contains("饿了吗") { targetApp = .eleme }

        // 高置信度：有动作词 + 有食物名
        if hasAction && matchedFood != nil {
            return ParsedIntent(
                type: .orderFood,
                keyword: matchedFood,
                targetApp: targetApp,
                needsConfirmation: true,
                confidence: 0.9
            )
        }

        // 中置信度：只有动作词 或 只有"饿了/吃什么"
        if hasAction || text.contains("饿了") || text.contains("吃什么") {
            return ParsedIntent(
                type: .orderFood,
                keyword: matchedFood,
                targetApp: targetApp,
                needsConfirmation: true,
                confidence: 0.7
            )
        }

        // 低置信度：只有食物名
        if matchedFood != nil && text.contains("吃") {
            return ParsedIntent(
                type: .orderFood,
                keyword: matchedFood,
                targetApp: targetApp,
                needsConfirmation: true,
                confidence: 0.5
            )
        }

        return nil
    }

    // MARK: - 购物意图识别
    private func detectShopIntent(_ text: String) -> ParsedIntent? {
        let actionWords = ["帮我买", "给我买", "我要买", "买个", "买一件", "想买", "我想买", "购物", "逛淘宝", "逛京东"]
        let hasAction = actionWords.contains { text.contains($0) }

        var targetApp: TargetApp?
        if text.contains("淘宝") { targetApp = .taobao }
        if text.contains("京东") { targetApp = .jd }

        // 提取商品名（简单提取：动作词后面的内容）
        var keyword: String?
        if hasAction {
            for action in actionWords {
                if let range = text.range(of: action) {
                    let after = String(text[range.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !after.isEmpty && after.count < 20 {
                        keyword = after
                    }
                    break
                }
            }
        }

        if hasAction || targetApp != nil {
            return ParsedIntent(
                type: .shop,
                keyword: keyword,
                targetApp: targetApp,
                needsConfirmation: true,
                confidence: hasAction ? 0.85 : 0.6
            )
        }

        return nil
    }

    // MARK: - 听歌意图识别
    private func detectMusicIntent(_ text: String) -> ParsedIntent? {
        let actionWords = ["放首歌", "放歌", "听歌", "听音乐", "播放", "唱首歌", "来点音乐", "放点歌"]
        let hasAction = actionWords.contains { text.contains($0) }

        var targetApp: TargetApp?
        if text.contains("网易云") { targetApp = .neteaseMusic }

        // 提取歌曲名
        var keyword: String?
        if hasAction {
            for action in actionWords {
                if let range = text.range(of: action) {
                    let after = String(text[range.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !after.isEmpty && after.count < 30 {
                        keyword = after
                    }
                    break
                }
            }
        }

        if hasAction {
            return ParsedIntent(
                type: .playMusic,
                keyword: keyword,
                targetApp: targetApp,
                needsConfirmation: keyword == nil,
                confidence: 0.9
            )
        }

        return nil
    }

    // MARK: - 看视频意图识别
    private func detectVideoIntent(_ text: String) -> ParsedIntent? {
        let actionWords = ["看视频", "看番", "看剧", "看电影", "看综艺", "打开视频", "刷视频"]
        let hasAction = actionWords.contains { text.contains($0) }

        var targetApp: TargetApp?
        if text.contains("b站") || text.contains("哔哩哔哩") { targetApp = .bilibili }
        if text.contains("抖音") { targetApp = .douyin }

        if hasAction || targetApp != nil {
            return ParsedIntent(
                type: .watchVideo,
                keyword: nil,
                targetApp: targetApp,
                needsConfirmation: false,
                confidence: hasAction ? 0.85 : 0.7
            )
        }

        return nil
    }

    // MARK: - 刷社交意图识别
    private func detectSocialIntent(_ text: String) -> ParsedIntent? {
        var targetApp: TargetApp?
        if text.contains("微博") || text.contains("热搜") { targetApp = .weibo }
        if text.contains("小红书") || text.contains("种草") { targetApp = .xiaohongshu }
        if text.contains("知乎") { targetApp = .zhihu }
        if text.contains("微信") || text.contains("朋友圈") { targetApp = .wechat }

        let actionWords = ["刷微博", "刷小红书", "刷知乎", "看朋友圈", "看看热搜"]
        let hasAction = actionWords.contains { text.contains($0) }

        if targetApp != nil || hasAction {
            return ParsedIntent(
                type: .browseSocial,
                keyword: nil,
                targetApp: targetApp,
                needsConfirmation: false,
                confidence: 0.8
            )
        }

        return nil
    }

    // MARK: - 导航意图识别
    private func detectNavigationIntent(_ text: String) -> ParsedIntent? {
        let actionWords = ["导航", "去", "怎么走", "路线", "带我去", "怎么去"]
        let hasAction = actionWords.contains { text.contains($0) }

        // 提取目的地
        var keyword: String?
        if hasAction {
            for action in actionWords {
                if let range = text.range(of: action) {
                    let after = String(text[range.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !after.isEmpty && after.count < 30 {
                        keyword = after
                    }
                    break
                }
            }
        }

        if hasAction && keyword != nil {
            return ParsedIntent(
                type: .navigate,
                keyword: keyword,
                targetApp: .maps,
                needsConfirmation: true,
                confidence: 0.85
            )
        }

        return nil
    }

    // MARK: - 搜索意图识别
    private func detectSearchIntent(_ text: String) -> ParsedIntent? {
        let actionWords = ["搜索", "搜一下", "查一下", "百度一下", "谷歌一下", "帮我查"]
        let hasAction = actionWords.contains { text.contains($0) }

        var keyword: String?
        if hasAction {
            for action in actionWords {
                if let range = text.range(of: action) {
                    let after = String(text[range.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !after.isEmpty && after.count < 50 {
                        keyword = after
                    }
                    break
                }
            }
        }

        if hasAction {
            return ParsedIntent(
                type: .searchWeb,
                keyword: keyword,
                targetApp: .safari,
                needsConfirmation: keyword == nil,
                confidence: 0.85
            )
        }

        return nil
    }

    // MARK: - 打开App意图识别
    private func detectOpenAppIntent(_ text: String) -> ParsedIntent? {
        let actionWords = ["打开", "启动", "点开"]
        let hasAction = actionWords.contains { text.contains($0) }

        // 匹配App名
        for app in TargetApp.allCases {
            if text.contains(app.rawValue) {
                return ParsedIntent(
                    type: .openApp,
                    keyword: nil,
                    targetApp: app,
                    needsConfirmation: false,
                    confidence: hasAction ? 0.95 : 0.7
                )
            }
        }

        return nil
    }
}

// MARK: - 食物偏好推荐器
final class FoodRecommender {
    static let shared = FoodRecommender()

    private init() {}

    // 基于时间推荐食物
    func recommendByTime() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 6..<10:
            return "小黎，早餐时间，推荐豆浆油条、包子粥、三明治，要我帮你点吗嘛"
        case 10..<14:
            return "小黎，午餐时间，推荐黄焖鸡、麻辣烫、盖浇饭、寿司，要我帮你点吗嘛"
        case 14..<17:
            return "小黎，下午茶时间，推荐奶茶、咖啡、小蛋糕，要我帮你点吗嘛"
        case 17..<21:
            return "小黎，晚餐时间，推荐火锅、烧烤、小龙虾、拉面，要我帮你点吗嘛"
        case 21..<24, 0..<6:
            return "小黎，深夜了，推荐烧烤、炸鸡、螺蛳粉，不过吃夜宵会胖哦罢了，要我帮你点吗嘛"
        default:
            return "小黎，想吃什么？我帮你点嘛"
        }
    }

    // 基于记忆偏好推荐
    func recommendByMemory(foodMemories: [String]) -> String {
        if foodMemories.isEmpty {
            return recommendByTime()
        }

        // 从记忆中提取喜欢的食物
        let likedFoods = foodMemories.filter { $0.contains("喜欢") || $0.contains("爱吃") }
        if let first = likedFoods.first {
            return "小黎，我记得你喜欢吃\(first)，要我帮你点吗嘛"
        }

        return recommendByTime()
    }

    // 随机推荐
    func randomRecommend() -> String {
        let foods = [
            "麻辣烫", "黄焖鸡", "螺蛳粉", "小龙虾", "烧烤",
            "火锅", "寿司", "拉面", "炸鸡", "披萨",
            "汉堡", "奶茶", "咖啡", "甜品", "炒饭"
        ]
        let food = foods.randomElement() ?? "麻辣烫"
        return "小黎，今天吃\(food)怎么样？我帮你点嘛"
    }
}
