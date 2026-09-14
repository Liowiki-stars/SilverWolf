import Foundation

struct Song: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: Int  // 秒
    let coverUrl: String?
    let playUrl: String?

    var durationText: String {
        let m = duration / 60
        let s = duration % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct Playlist: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let coverUrl: String?
    let songCount: Int
    let category: String  // 战斗链路/探索链路/休憩链路/叙事链路
}
