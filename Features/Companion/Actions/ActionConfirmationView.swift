import SwiftUI

// MARK: - 操作确认弹窗
struct ActionConfirmationView: View {
    let intent: ParsedIntent
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let onModify: (String) -> Void

    @State private var modifiedKeyword = ""

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                // 银狼头像 + 标题
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(hex: "9D4EDD"), Color(hex: "7B2CBF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)

                        Image(systemName: intent.targetApp?.icon ?? "sparkles")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("银狼想帮你")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                        Text(intent.type.rawValue)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // 操作详情卡片
                VStack(alignment: .leading, spacing: 12) {
                    if let keyword = intent.keyword {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundStyle(Color(hex: "9D4EDD"))
                            Text(keyword)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                    }

                    if let app = intent.targetApp {
                        HStack {
                            Image(systemName: app.icon)
                                .foregroundStyle(Color(hex: app.color))
                            Text("使用 \(app.rawValue)")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "9CA3AF"))
                            Spacer()

                            // App安装状态
                            if AppLauncher.shared.isAppInstalled(app) {
                                Text("已安装")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "10B981"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(hex: "10B981").opacity(0.15))
                                    )
                            } else {
                                Text("未安装")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "F59E0B"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(hex: "F59E0B").opacity(0.15))
                                    )
                            }
                        }
                    }

                    // 置信度
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(Color(hex: "10B981"))
                        Text("识别置信度 \(Int(intent.confidence * 100))%")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "6B7280"))
                        Spacer()
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: "1F2937"))
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // 修改关键词输入框
                if intent.keyword != nil {
                    HStack(spacing: 10) {
                        Image(systemName: "pencil")
                            .foregroundStyle(Color(hex: "6B7280"))
                        TextField("修改关键词", text: $modifiedKeyword)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .accentColor(Color(hex: "9D4EDD"))

                        if !modifiedKeyword.isEmpty {
                            Button {
                                onModify(modifiedKeyword)
                                modifiedKeyword = ""
                            } label: {
                                Text("修改")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(hex: "9D4EDD"))
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(hex: "111827"))
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }

                // 操作按钮
                HStack(spacing: 12) {
                    // 取消
                    Button {
                        onCancel()
                    } label: {
                        HStack {
                            Image(systemName: "xmark")
                            Text("取消")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(hex: "1F2937"))
                        )
                    }

                    // 确认执行
                    Button {
                        onConfirm()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("帮我执行")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [Color(hex: "9D4EDD"), Color(hex: "7B2CBF")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(hex: "111827"))
            .cornerRadius(24, corners: [.topLeft, .topRight])
        }
        .background(Color.black.opacity(0.5).ignoresSafeArea())
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - 快捷操作面板（银狼推荐的操作）
struct QuickActionsPanel: View {
    let onAction: (ActionIntent) -> Void

    private let quickActions: [(intent: ActionIntent, title: String, subtitle: String, icon: String, color: String)] = [
        (.orderFood, "点外卖", "帮你选好吃的", "takeoutbag.and.cup.and.straw.fill", "FFD100"),
        (.playMusic, "放首歌", "网易云音乐", "music.note", "C20C0C"),
        (.shop, "去购物", "淘宝/京东", "cart.fill", "FF5000"),
        (.watchVideo, "看视频", "B站/抖音", "tv.fill", "00A1D6"),
        (.browseSocial, "刷社交", "微博/小红书", "at.circle.fill", "E6162D"),
        (.searchWeb, "搜索", "浏览器搜索", "magnifyingglass", "06B6D4")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color(hex: "9D4EDD"))
                Text("银狼能帮你")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "9CA3AF"))
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(quickActions, id: \.intent) { action in
                    Button {
                        onAction(action.intent)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: action.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(Color(hex: action.color))
                            Text(action.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(action.subtitle)
                                .font(.system(size: 9))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(hex: "1F2937"))
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "111827").opacity(0.9))
        )
    }
}
