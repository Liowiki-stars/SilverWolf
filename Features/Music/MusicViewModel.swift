import Foundation
import AVFoundation
import SwiftData

@MainActor
final class MusicViewModel: ObservableObject {
    @Published var searchResults: [Song] = []
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.7
    @Published var searchKeyword = ""
    @Published var isSearching = false
    @Published var collectedSongs: [Song] = []  // 收藏列表

    private var player: AVPlayer?
    private var timeObserver: Any?
    private let netease = NetEaseService.shared
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupAudioSession()
        loadCollectedSongs()
    }

    // MARK: - 音频会话配置
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("音频会话配置失败: \(error)")
        }
    }

    // MARK: - 搜索
    func search() {
        let keyword = searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return }

        isSearching = true
        Task {
            do {
                let results = try await netease.searchSongs(keyword: keyword)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }

    // MARK: - 搜索并播放（语音指令用）
    func searchAndPlay(keyword: String) async {
        do {
            let results = try await netease.searchSongs(keyword: keyword, limit: 1)
            if let first = results.first {
                await MainActor.run {
                    searchResults = results
                    play(song: first)
                }
            }
        } catch {
            print("搜索播放失败: \(error)")
        }
    }

    // MARK: - 播放
    func play(song: Song) {
        currentSong = song

        Task {
            do {
                if let urlString = try await netease.getPlayURL(songId: song.id),
                   let url = URL(string: urlString) {
                    await MainActor.run {
                        startPlayback(url: url, song: song)
                    }
                }
            } catch {
                print("获取播放URL失败: \(error)")
            }
        }
    }

    private func startPlayback(url: URL, song: Song) {
        // 清理旧的播放器
        removeTimeObserver()
        player = AVPlayer(url: url)
        player?.volume = volume
        player?.play()
        isPlaying = true

        // 监听播放进度
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let duration = self.player?.currentItem?.duration.seconds {
                self.duration = duration
            }
        }

        // 监听播放结束
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.next()
        }
    }

    // MARK: - 暂停/继续
    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        player?.play()
        isPlaying = true
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    // MARK: - 上一首/下一首
    func next() {
        guard let current = currentSong,
              let index = searchResults.firstIndex(where: { $0.id == current.id }),
              index + 1 < searchResults.count else {
            return
        }
        play(song: searchResults[index + 1])
    }

    func prev() {
        guard let current = currentSong,
              let index = searchResults.firstIndex(where: { $0.id == current.id }),
              index > 0 else {
            return
        }
        play(song: searchResults[index - 1])
    }

    // MARK: - 进度跳转
    func seek(to time: TimeInterval) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }

    // MARK: - 音量
    func volumeUp() {
        volume = min(1.0, volume + 0.1)
        player?.volume = volume
    }

    func volumeDown() {
        volume = max(0.0, volume - 0.1)
        player?.volume = volume
    }

    // MARK: - 收藏
    func toggleCollect(song: Song) {
        if let index = collectedSongs.firstIndex(where: { $0.id == song.id }) {
            collectedSongs.remove(at: index)
            // 从SwiftData删除
            do {
                try modelContext.delete(model: CollectedSong.self, where: #Predicate { $0.songId == song.id })
            } catch {
                print("删除收藏失败: \(error)")
            }
        } else {
            collectedSongs.append(song)
            // 保存到SwiftData
            let collected = CollectedSong(songId: song.id, title: song.title, artist: song.artist, album: song.album, duration: song.duration, coverUrl: song.coverUrl)
            modelContext.insert(collected)
        }
    }

    func isCollected(song: Song) -> Bool {
        collectedSongs.contains { $0.id == song.id }
    }

    private func loadCollectedSongs() {
        do {
            let collected = try modelContext.fetch(FetchDescriptor<CollectedSong>())
            collectedSongs = collected.map {
                Song(id: $0.songId, title: $0.title, artist: $0.artist, album: $0.album, duration: $0.duration, coverUrl: $0.coverUrl, playUrl: nil)
            }
        } catch {
            print("加载收藏失败: \(error)")
        }
    }

    // MARK: - 清理
    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    deinit {
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - 收藏歌曲数据模型（SwiftData）
@Model
final class CollectedSong {
    var songId: String
    var title: String
    var artist: String
    var album: String
    var duration: Int
    var coverUrl: String?
    var addedAt: Date

    init(songId: String, title: String, artist: String, album: String, duration: Int, coverUrl: String?) {
        self.songId = songId
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.coverUrl = coverUrl
        self.addedAt = Date()
    }
}
