import SwiftUI

struct MusicView: View {
    @EnvironmentObject var musicVM: MusicViewModel
    @State private var selectedTab: MusicTab = .search

    enum MusicTab: String, CaseIterable {
        case search = "搜索"
        case collection = "收藏"
        case category = "分类"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部搜索栏
                searchHeader

                // Tab切换
                Picker("", selection: $selectedTab) {
                    ForEach(MusicTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: "111827"))

                // 内容区
                ScrollView {
                    switch selectedTab {
                    case .search:
                        searchContent
                    case .collection:
                        collectionContent
                    case .category:
                        categoryContent
                    }
                }
                .background(Color(hex: "0A0E17"))

                // 底部播放栏
                PlayerBar()
                    .environmentObject(musicVM)
            }
            .navigationTitle("音频链路")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "111827"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - 搜索栏
    private var searchHeader: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color(hex: "6B7280"))
                TextField("扫描音频链路...", text: $musicVM.searchKeyword)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                    .onSubmit {
                        musicVM.search()
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(hex: "1F2937"))
            )

            Button {
                musicVM.search()
            } label: {
                Text("搜索")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(hex: "9D4EDD"))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "111827"))
    }

    // MARK: - 搜索结果
    private var searchContent: some View {
        LazyVStack(spacing: 0) {
            if musicVM.isSearching {
                ProgressView()
                    .tint(Color(hex: "9D4EDD"))
                    .padding(.top, 40)
            } else if musicVM.searchResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundStyle(Color(hex: "4B5563"))
                    Text("输入关键词扫描音频链路")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "6B7280"))
                }
                .padding(.top, 60)
            } else {
                ForEach(musicVM.searchResults) { song in
                    SongRow(song: song)
                        .environmentObject(musicVM)
                }
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - 收藏列表
    private var collectionContent: some View {
        LazyVStack(spacing: 0) {
            if musicVM.collectedSongs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star")
                        .font(.system(size: 48))
                        .foregroundStyle(Color(hex: "4B5563"))
                    Text("收藏夹空空的")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "6B7280"))
                    Text("搜索并加密存储你喜欢的音频链路")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
                .padding(.top, 60)
            } else {
                ForEach(musicVM.collectedSongs) { song in
                    SongRow(song: song)
                        .environmentObject(musicVM)
                }
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - 分类列表
    private var categoryContent: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(["战斗链路", "探索链路", "休憩链路", "叙事链路"], id: \.self) { category in
                CategoryCard(category: category)
            }
        }
        .padding(16)
    }
}

// MARK: - 歌曲行
struct SongRow: View {
    let song: Song
    @EnvironmentObject var musicVM: MusicViewModel

    var isCurrent: Bool {
        musicVM.currentSong?.id == song.id
    }

    var body: some View {
        Button {
            musicVM.play(song: song)
        } label: {
            HStack(spacing: 12) {
                // 封面/序号
                ZStack {
                    if isCurrent && musicVM.isPlaying {
                        // 播放中动画
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { i in
                                Rectangle()
                                    .fill(Color(hex: "9D4EDD"))
                                    .frame(width: 3, height: CGFloat(8 + i * 4))
                            }
                        }
                    } else {
                        AsyncImage(url: URL(string: song.coverUrl ?? "")) { phase in
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
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .frame(width: 44, height: 44)

                // 歌曲信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
                        .foregroundStyle(isCurrent ? Color(hex: "9D4EDD") : .white)
                        .lineLimit(1)
                    Text(song.artist)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                        .lineLimit(1)
                }

                Spacer()

                // 时长
                Text(song.durationText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "6B7280"))

                // 收藏按钮
                Button {
                    musicVM.toggleCollect(song: song)
                } label: {
                    Image(systemName: musicVM.isCollected(song: song) ? "star.fill" : "star")
                        .foregroundStyle(musicVM.isCollected(song: song) ? Color(hex: "FBBF24") : Color(hex: "6B7280"))
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isCurrent ? Color(hex: "9D4EDD").opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 分类卡片
struct CategoryCard: View {
    let category: String

    var icon: String {
        switch category {
        case "战斗链路": return "flame.fill"
        case "探索链路": return "map.fill"
        case "休憩链路": return "moon.stars.fill"
        case "叙事链路": return "book.fill"
        default: return "music.note"
        }
    }

    var color: String {
        switch category {
        case "战斗链路": return "EF4444"
        case "探索链路": return "3B82F6"
        case "休憩链路": return "10B981"
        case "叙事链路": return "F59E0B"
        default: return "9D4EDD"
        }
    }

    var body: some View {
        Button {
            // 点击分类播放对应歌单
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                Text(category)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(hex: color), Color(hex: color).opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
        }
        .buttonStyle(.plain)
    }
}
