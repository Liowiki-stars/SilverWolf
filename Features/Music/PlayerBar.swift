import SwiftUI

struct PlayerBar: View {
    @EnvironmentObject var musicVM: MusicViewModel
    @State private var showFullPlayer = false

    var body: some View {
        VStack(spacing: 0) {
            // 进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "374151"))
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "9D4EDD"), Color(hex: "C084FC")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * progressRatio)
                }
            }
            .frame(height: 2)

            // 播放控制栏
            HStack(spacing: 12) {
                // 封面+歌曲信息
                Button {
                    showFullPlayer = true
                } label: {
                    HStack(spacing: 10) {
                        AsyncImage(url: URL(string: musicVM.currentSong?.coverUrl ?? "")) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Color(hex: "374151")
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .foregroundStyle(Color(hex: "6B7280"))
                                    )
                            }
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(musicVM.currentSong?.title ?? "未选择链路")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(musicVM.currentSong?.artist ?? "—")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "9CA3AF"))
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // 控制按钮
                HStack(spacing: 20) {
                    // 上一首
                    Button {
                        musicVM.prev()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                    }

                    // 播放/暂停
                    Button {
                        musicVM.togglePlayPause()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "9D4EDD"), Color(hex: "7B2CBF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 40, height: 40)
                            Image(systemName: musicVM.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                                .offset(x: musicVM.isPlaying ? 0 : 2)
                        }
                    }

                    // 下一首
                    Button {
                        musicVM.next()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(hex: "111827"))
        }
        .fullScreenCover(isPresented: $showFullPlayer) {
            FullPlayerView()
                .environmentObject(musicVM)
        }
    }

    private var progressRatio: Double {
        guard musicVM.duration > 0 else { return 0 }
        return min(1, max(0, musicVM.currentTime / musicVM.duration))
    }
}

// MARK: - 全屏播放器
struct FullPlayerView: View {
    @EnvironmentObject var musicVM: MusicViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color(hex: "1E1B4B"), Color(hex: "0A0E17")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部栏
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text("正在播放")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        // 更多操作
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)

                Spacer()

                // 专辑封面
                AsyncImage(url: URL(string: musicVM.currentSong?.coverUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color(hex: "374151")
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color(hex: "6B7280"))
                            )
                    }
                }
                .frame(width: 280, height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color(hex: "9D4EDD").opacity(0.4), radius: 40, x: 0, y: 20)
                .rotationEffect(.degrees(musicVM.isPlaying ? 360 : 0))
                .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: musicVM.isPlaying)

                Spacer()

                // 歌曲信息
                VStack(spacing: 8) {
                    Text(musicVM.currentSong?.title ?? "未选择链路")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(musicVM.currentSong?.artist ?? "—")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: "C084FC"))
                }
                .padding(.horizontal, 32)

                // 进度条
                VStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { musicVM.currentTime },
                            set: { musicVM.seek(to: $0) }
                        ),
                        in: 0...max(musicVM.duration, 1)
                    )
                    .tint(Color(hex: "9D4EDD"))

                    HStack {
                        Text(formatTime(musicVM.currentTime))
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                        Spacer()
                        Text(formatTime(musicVM.duration))
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)

                // 控制按钮
                HStack(spacing: 40) {
                    Button {
                        // 收藏
                        if let song = musicVM.currentSong {
                            musicVM.toggleCollect(song: song)
                        }
                    } label: {
                        Image(systemName: musicVM.currentSong.map { musicVM.isCollected(song: $0) } ?? false ? "star.fill" : "star")
                            .font(.system(size: 24))
                            .foregroundStyle(musicVM.currentSong.map { musicVM.isCollected(song: $0) } ?? false ? Color(hex: "FBBF24") : .white)
                    }

                    Button {
                        musicVM.prev()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }

                    Button {
                        musicVM.togglePlayPause()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "9D4EDD"), Color(hex: "7B2CBF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 72, height: 72)
                            Image(systemName: musicVM.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                                .offset(x: musicVM.isPlaying ? 0 : 3)
                        }
                    }

                    Button {
                        musicVM.next()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }

                    Button {
                        // 播放列表
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        return String(format: "%d:%02d", m, s)
    }
}
