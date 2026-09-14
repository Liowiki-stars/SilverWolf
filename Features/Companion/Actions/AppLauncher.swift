import Foundation
import UIKit

// MARK: - 可跳转的App类型
enum TargetApp: String, CaseIterable, Identifiable {
    case meituan = "美团外卖"
    case eleme = "饿了么"
    case taobao = "淘宝"
    case jd = "京东"
    case douyin = "抖音"
    case bilibili = "B站"
    case neteaseMusic = "网易云音乐"
    case wechat = "微信"
    case xiaohongshu = "小红书"
    case zhihu = "知乎"
    case weibo = "微博"
    case alipay = "支付宝"
    case maps = "地图"
    case safari = "浏览器"
    case settings = "设置"

    var id: String { rawValue }

    // URL Scheme
    var urlScheme: String {
        switch self {
        case .meituan: return "imeituan://"
        case .eleme: return "eleme://"
        case .taobao: return "taobao://"
        case .jd: return "openapp.jdmobile://"
        case .douyin: return "snssdk1128://"
        case .bilibili: return "bilibili://"
        case .neteaseMusic: return "orpheuswidget://"
        case .wechat: return "weixin://"
        case .xiaohongshu: return "xhsdiscover://"
        case .zhihu: return "zhihu://"
        case .weibo: return "weibosdk://"
        case .alipay: return "alipay://"
        case .maps: return "maps://"
        case .safari: return "https://"
        case .settings: return "App-Prefs://"
        }
    }

    // App Store下载链接（未安装时跳转）
    var appStoreURL: String {
        switch self {
        case .meituan: return "https://apps.apple.com/cn/app/id416697117"
        case .eleme: return "https://apps.apple.com/cn/app/id916129251"
        case .taobao: return "https://apps.apple.com/cn/app/id387682726"
        case .jd: return "https://apps.apple.com/cn/app/id414245413"
        case .douyin: return "https://apps.apple.com/cn/app/id1142110895"
        case .bilibili: return "https://apps.apple.com/cn/app/id736536022"
        case .neteaseMusic: return "https://apps.apple.com/cn/app/id590338362"
        case .wechat: return "https://apps.apple.com/cn/app/id414478124"
        case .xiaohongshu: return "https://apps.apple.com/cn/app/id741292507"
        case .zhihu: return "https://apps.apple.com/cn/app/id432274380"
        case .weibo: return "https://apps.apple.com/cn/app/id350962117"
        case .alipay: return "https://apps.apple.com/cn/app/id333206289"
        case .maps: return ""
        case .safari: return ""
        case .settings: return ""
        }
    }

    var icon: String {
        switch self {
        case .meituan: return "takeoutbag.and.cup.and.straw.fill"
        case .eleme: return "cup.and.saucer.fill"
        case .taobao: return "cart.fill"
        case .jd: return "bag.fill"
        case .douyin: return "music.note.tv.fill"
        case .bilibili: return "tv.fill"
        case .neteaseMusic: return "music.note"
        case .wechat: return "bubble.left.and.bubble.right.fill"
        case .xiaohongshu: return "book.closed.fill"
        case .zhihu: return "questionmark.circle.fill"
        case .weibo: return "at.circle.fill"
        case .alipay: return "creditcard.fill"
        case .maps: return "map.fill"
        case .safari: return "safari.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var color: String {
        switch self {
        case .meituan: return "FFD100"
        case .eleme: return "0097FF"
        case .taobao: return "FF5000"
        case .jd: return "E1251B"
        case .douyin: return "000000"
        case .bilibili: return "00A1D6"
        case .neteaseMusic: return "C20C0C"
        case .wechat: return "07C160"
        case .xiaohongshu: return "FF2442"
        case .zhihu: return "0066FF"
        case .weibo: return "E6162D"
        case .alipay: return "1677FF"
        case .maps: return "34C759"
        case .safari: return "06B6D4"
        case .settings: return "8E8E93"
        }
    }
}

// MARK: - App跳转管理器
final class AppLauncher {
    static let shared = AppLauncher()

    private init() {}

    // 检查App是否已安装
    func isAppInstalled(_ app: TargetApp) -> Bool {
        guard let url = URL(string: app.urlScheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    // 打开App（带参数）
    @discardableResult
    func openApp(_ app: TargetApp, withPath path: String = "") -> Bool {
        let urlString = path.isEmpty ? app.urlScheme : app.urlScheme + path
        guard let url = URL(string: urlString) else { return false }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return true
        } else {
            // App未安装，跳转App Store
            if !app.appStoreURL.isEmpty, let storeURL = URL(string: app.appStoreURL) {
                UIApplication.shared.open(storeURL)
            }
            return false
        }
    }

    // 打开美团外卖（搜索关键词）
    func openMeituan(search keyword: String? = nil) -> Bool {
        if let keyword = keyword,
           let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return openApp(.meituan, withPath: "www.meituan.com/meishi/search?keyword=\(encoded)")
        }
        return openApp(.meituan)
    }

    // 打开饿了么
    func openEleme(search keyword: String? = nil) -> Bool {
        return openApp(.eleme)
    }

    // 打开淘宝（搜索关键词）
    func openTaobao(search keyword: String? = nil) -> Bool {
        if let keyword = keyword,
           let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return openApp(.taobao, withPath: "s.taobao.com/search?q=\(encoded)")
        }
        return openApp(.taobao)
    }

    // 打开京东（搜索关键词）
    func openJD(search keyword: String? = nil) -> Bool {
        if let keyword = keyword,
           let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return openApp(.jd, withPath: "virtual?params={\"category\":\"search\",\"keyword\":\"\(encoded)\"}")
        }
        return openApp(.jd)
    }

    // 打开抖音
    func openDouyin() -> Bool {
        return openApp(.douyin)
    }

    // 打开B站（搜索关键词）
    func openBilibili(search keyword: String? = nil) -> Bool {
        if let keyword = keyword,
           let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return openApp(.bilibili, withPath: "search?keyword=\(encoded)")
        }
        return openApp(.bilibili)
    }

    // 打开网易云音乐（搜索歌曲）
    func openNeteaseMusic(search keyword: String? = nil) -> Bool {
        if let keyword = keyword,
           let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return openApp(.neteaseMusic, withPath: "search?keyword=\(encoded)")
        }
        return openApp(.neteaseMusic)
    }

    // 打开微信
    func openWechat() -> Bool {
        return openApp(.wechat)
    }

    // 打开小红书（搜索关键词）
    func openXiaohongshu(search keyword: String? = nil) -> Bool {
        return openApp(.xiaohongshu)
    }

    // 打开知乎（搜索关键词）
    func openZhihu(search keyword: String? = nil) -> Bool {
        if let keyword = keyword,
           let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return openApp(.zhihu, withPath: "search?q=\(encoded)")
        }
        return openApp(.zhihu)
    }

    // 打开微博
    func openWeibo() -> Bool {
        return openApp(.weibo)
    }

    // 打开支付宝
    func openAlipay() -> Bool {
        return openApp(.alipay)
    }

    // 打开地图（导航到地址）
    func openMaps(to address: String? = nil) -> Bool {
        if let address = address,
           let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            let urlString = "maps://?daddr=\(encoded)"
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
                return true
            }
        }
        return openApp(.maps)
    }

    // 打开浏览器（访问URL）
    func openSafari(url: String) -> Bool {
        let urlString = url.hasPrefix("http") ? url : "https://\(url)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
            return true
        }
        return false
    }

    // 打开系统设置
    func openSettings() -> Bool {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
            return true
        }
        return false
    }
}
