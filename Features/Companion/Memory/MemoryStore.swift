import Foundation
import SwiftData

// MARK: - 记忆存储管理器
@MainActor
final class MemoryStore: ObservableObject {
    @Published var memories: [Memory] = []

    private let modelContext: ModelContext
    private let maxMemories = 200  // 最大记忆数量（超出后遗忘最不重要的）

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadMemories()
    }

    // MARK: - 加载记忆
    func loadMemories() {
        let descriptor = FetchDescriptor<Memory>(
            sortBy: [SortDescriptor(\.importance, order: .reverse),
                     SortDescriptor(\.lastAccessedAt, order: .reverse)]
        )
        do {
            memories = try modelContext.fetch(descriptor)
        } catch {
            print("加载记忆失败: \(error)")
        }
    }

    // MARK: - 添加记忆
    func addMemory(type: MemoryType, category: String, content: String, importance: Int = 3, source: String = "对话提取") {
        // 检查是否已存在相似记忆（避免重复）
        if let existing = memories.first(where: { $0.content == content && $0.type == type.rawValue }) {
            // 已存在则更新访问时间和重要度
            existing.lastAccessedAt = Date()
            existing.accessCount += 1
            existing.importance = max(existing.importance, importance)
            try? modelContext.save()
            loadMemories()
            return
        }

        let memory = Memory(type: type, category: category, content: content, importance: importance, source: source)
        modelContext.insert(memory)
        try? modelContext.save()

        // 检查是否超出上限，超出则遗忘最不重要且最久未访问的
        if memories.count >= maxMemories {
            forgetLeastImportant()
        }

        loadMemories()
    }

    // MARK: - 检索相关记忆（用于对话生成）
    func retrieveRelevantMemories(query: String, limit: Int = 5) -> [Memory] {
        let keywords = query.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }

        // 计算每条记忆的相关度分数
        let scored = memories.map { memory -> (Memory, Double) in
            var score = 0.0

            // 关键词匹配
            let content = memory.content.lowercased()
            let category = memory.category.lowercased()
            for keyword in keywords {
                if content.contains(keyword) { score += 3.0 }
                if category.contains(keyword) { score += 2.0 }
            }

            // 重要度加成
            score += Double(memory.importance) * 0.5

            // 近期访问加成（最近访问过的记忆更相关）
            let daysSinceAccess = Date().timeIntervalSince(memory.lastAccessedAt) / 86400
            score += max(0, 5 - daysSinceAccess) * 0.2

            // 访问频率加成
            score += Double(min(memory.accessCount, 10)) * 0.1

            return (memory, score)
        }

        // 按相关度排序，返回top N
        return scored
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }

    // MARK: - 按类型获取记忆
    func getMemories(byType type: MemoryType) -> [Memory] {
        memories.filter { $0.type == type.rawValue }
    }

    // MARK: - 获取特定分类的记忆
    func getMemories(byCategory category: String) -> [Memory] {
        memories.filter { $0.category == category }
    }

    // MARK: - 删除记忆
    func deleteMemory(_ memory: Memory) {
        modelContext.delete(memory)
        try? modelContext.save()
        loadMemories()
    }

    // MARK: - 置顶/取消置顶
    func togglePin(_ memory: Memory) {
        memory.isPinned.toggle()
        try? modelContext.save()
        loadMemories()
    }

    // MARK: - 遗忘机制（删除最不重要的记忆）
    private func forgetLeastImportant() {
        // 不删除置顶的记忆
        let unpinnd = memories.filter { !$0.isPinned }
        if let toForget = unpinnd.last {
            modelContext.delete(toForget)
            try? modelContext.save()
        }
    }

    // MARK: - 生成记忆摘要（用于注入prompt）
    func generateMemoryContext(query: String) -> String {
        let relevant = retrieveRelevantMemories(query: query, limit: 5)
        guard !relevant.isEmpty else { return "" }

        var context = "【关于小黎的记忆】\n"
        for memory in relevant {
            let typeName = MemoryType(rawValue: memory.type)?.rawValue ?? "记忆"
            context += "- [\(typeName)/\(memory.category)] \(memory.content)\n"
        }
        return context
    }

    // MARK: - 统计
    var stats: (total: Int, byType: [MemoryType: Int]) {
        var byType: [MemoryType: Int] = [:]
        for type in MemoryType.allCases {
            byType[type] = memories.filter { $0.type == type.rawValue }.count
        }
        return (memories.count, byType)
    }
}
