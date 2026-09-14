import SwiftUI

// MARK: - 银狼悬浮形象（画中画风格）
struct SilverWolfAvatarView: View {
    let size: CGFloat
    let isActive: Bool
    let onTap: () -> Void

    @State private var bounceOffset: CGFloat = 0
    @State private var blink = false
    @State private var talkScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 外圈光晕
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "9D4EDD").opacity(0.4), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.8
                    )
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .opacity(isActive ? 1 : 0.3)

            // 主体圆形
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "9D4EDD"), Color(hex: "7B2CBF"), Color(hex: "5B21B6")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color(hex: "9D4EDD").opacity(0.5), radius: 12, x: 0, y: 4)

            // 银狼面部（简化Q版）
            VStack(spacing: size * 0.06) {
                // 头发（顶部三角）
                Triangle()
                    .fill(Color(hex: "4C1D95"))
                    .frame(width: size * 0.5, height: size * 0.2)
                    .offset(y: size * 0.02)

                // 眼睛
                HStack(spacing: size * 0.15) {
                    EyeShape(isBlinking: blink)
                        .frame(width: size * 0.12, height: size * 0.15)
                    EyeShape(isBlinking: blink)
                        .frame(width: size * 0.12, height: size * 0.15)
                }

                // 嘴巴（说话时变化）
                MouthShape(isTalking: talkScale > 1.02)
                    .frame(width: size * 0.15, height: size * 0.08)
            }
            .offset(y: -size * 0.02)

            // 耳机（侧边装饰）
            Circle()
                .fill(Color(hex: "1F2937"))
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: -size * 0.42, y: size * 0.05)
            Circle()
                .fill(Color(hex: "1F2937"))
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: size * 0.42, y: size * 0.05)
        }
        .scaleEffect(talkScale)
        .offset(y: bounceOffset)
        .onTapGesture(perform: onTap)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - 动画
    private func startAnimations() {
        // 呼吸浮动
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            bounceOffset = -4
        }

        // 眨眼（随机）
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                blink = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    blink = false
                }
            }
        }
    }

    // 说话时的缩放动画
    func setTalking(_ talking: Bool) {
        withAnimation(.easeInOut(duration: 0.15)) {
            talkScale = talking ? 1.08 : 1.0
        }
    }
}

// MARK: - 眼睛形状
struct EyeShape: View {
    let isBlinking: Bool

    var body: some View {
        if isBlinking {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "0F0A1E"))
                .frame(height: 2)
        } else {
            Ellipse()
                .fill(Color(hex: "0F0A1E"))
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 4, height: 4)
                        .offset(x: 2, y: -2)
                )
        }
    }
}

// MARK: - 嘴巴形状
struct MouthShape: View {
    let isTalking: Bool

    var body: some View {
        if isTalking {
            Ellipse()
                .fill(Color(hex: "0F0A1E"))
        } else {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "0F0A1E"))
                .frame(height: 2)
        }
    }
}

// MARK: - 三角形（头发）
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
