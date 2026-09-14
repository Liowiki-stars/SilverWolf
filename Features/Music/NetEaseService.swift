import Foundation

// MARK: - 网易云音乐API服务
final class NetEaseService {
    static let shared = NetEaseService()

    private let baseURL = "https://music.163.com/api"
    private var accessToken: String?

    private init() {}

    // MARK: - 搜索歌曲
    func searchSongs(keyword: String, limit: Int = 20) async throws -> [Song] {
        let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
        let urlString = "\(baseURL)/cloudsearch/pc?s=\(encoded)&type=1&limit=\(limit)"

        guard let url = URL(string: urlString) else {
            throw NetEaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetEaseError.requestFailed
        }

        let result = try JSONDecoder().decode(SearchResponse.self, from: data)
        return result.result.songs.map { song in
            Song(
                id: String(song.id),
                title: song.name,
                artist: song.artists.first?.name ?? "未知",
                album: song.album.name,
                duration: song.duration / 1000,
                coverUrl: song.album.picUrl,
                playUrl: nil
            )
        }
    }

    // MARK: - 获取播放URL
    func getPlayURL(songId: String) async throws -> String? {
        let urlString = "\(baseURL)/song/enhance/player/url/v1?ids=[\(songId)]&level=standard"

        guard let url = URL(string: urlString) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode(PlayURLResponse.self, from: data)
        return result.data.first?.url
    }

    // MARK: - 获取推荐歌单
    func getRecommendPlaylists() async throws -> [Playlist] {
        // 简化：返回预设的分类歌单
        return [
            Playlist(id: "1", name: "战斗链路", coverUrl: nil, songCount: 50, category: "战斗链路"),
            Playlist(id: "2", name: "探索链路", coverUrl: nil, songCount: 80, category: "探索链路"),
            Playlist(id: "3", name: "休憩链路", coverUrl: nil, songCount: 60, category: "休憩链路"),
            Playlist(id: "4", name: "叙事链路", coverUrl: nil, songCount: 40, category: "叙事链路")
        ]
    }
}

// MARK: - API响应模型
struct SearchResponse: Codable {
    let result: SearchResult
}

struct SearchResult: Codable {
    let songs: [NeteaseSong]
}

struct NeteaseSong: Codable {
    let id: Int
    let name: String
    let artists: [NeteaseArtist]
    let album: NeteaseAlbum
    let duration: Int
}

struct NeteaseArtist: Codable {
    let name: String
}

struct NeteaseAlbum: Codable {
    let name: String
    let picUrl: String?

    enum CodingKeys: String, CodingKey {
        case name
        case picUrl = "picUrl"
    }
}

struct PlayURLResponse: Codable {
    let data: [PlayURLData]
}

struct PlayURLData: Codable {
    let url: String?
}

// MARK: - 错误类型
enum NetEaseError: LocalizedError {
    case invalidURL
    case requestFailed
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的URL"
        case .requestFailed: return "网络请求失败"
        case .noData: return "无数据返回"
        }
    }
}
