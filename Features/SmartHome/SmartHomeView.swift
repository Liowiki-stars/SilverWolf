import SwiftUI

struct SmartHomeView: View {
    @State private var devices: [SmartDevice] = [
        SmartDevice(name: "客厅灯", type: .light, isOn: false),
        SmartDevice(name: "空调", type: .aircon, isOn: true, temperature: 26),
        SmartDevice(name: "电视", type: .tv, isOn: false),
        SmartDevice(name: "风扇", type: .fan, isOn: false)
    ]

    var body: some View {
        List {
            Section("已连接设备") {
                ForEach($devices) { $device in
                    DeviceRow(device: $device)
                }
            }

            Section("场景模式") {
                Button {
                    // 一键全关
                    for i in devices.indices {
                        devices[i].isOn = false
                    }
                } label: {
                    Label("离家模式（全关）", systemImage: "figure.walk")
                }

                Button {
                    // 观影模式
                    for i in devices.indices {
                        if devices[i].type == .light { devices[i].isOn = false }
                        if devices[i].type == .tv { devices[i].isOn = true }
                        if devices[i].type == .aircon { devices[i].isOn = true }
                    }
                } label: {
                    Label("观影模式", systemImage: "film.fill")
                }

                Button {
                    // 睡眠模式
                    for i in devices.indices {
                        devices[i].isOn = false
                    }
                } label: {
                    Label("睡眠模式", systemImage: "moon.fill")
                }
            }

            Section {
                Button {
                    // 添加设备
                } label: {
                    Label("添加新设备", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("智能家居")
        .navigationBarTitleDisplayMode(.large)
        .scrollContentBackground(.hidden)
        .background(Color(hex: "0A0E17"))
    }
}

// MARK: - 设备行
struct DeviceRow: View {
    @Binding var device: SmartDevice

    var body: some View {
        HStack(spacing: 14) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(device.isOn ? Color(hex: "9D4EDD").opacity(0.2) : Color(hex: "1F2937"))
                    .frame(width: 44, height: 44)
                Image(systemName: device.type.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(device.isOn ? Color(hex: "9D4EDD") : Color(hex: "6B7280"))
            }

            // 名称+状态
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Text(device.isOn ? "运行中" : "已关闭")
                    .font(.system(size: 12))
                    .foregroundStyle(device.isOn ? Color(hex: "10B981") : Color(hex: "6B7280"))
            }

            Spacer()

            // 温度调节（空调）
            if device.type == .aircon && device.isOn {
                HStack(spacing: 8) {
                    Button {
                        device.temperature = max(16, device.temperature - 1)
                    } label: {
                        Image(systemName: "minus")
                            .foregroundStyle(Color(hex: "9CA3AF"))
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color(hex: "1F2937")))
                    }
                    Text("\(device.temperature)°")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40)
                    Button {
                        device.temperature = min(30, device.temperature + 1)
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color(hex: "9CA3AF"))
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color(hex: "1F2937")))
                    }
                }
            }

            // 开关
            Toggle("", isOn: $device.isOn)
                .labelsHidden()
                .tint(Color(hex: "9D4EDD"))
        }
        .padding(.vertical, 4)
        .listRowBackground(Color(hex: "111827"))
    }
}

// MARK: - 设备模型
struct SmartDevice: Identifiable {
    let id = UUID()
    var name: String
    var type: DeviceType
    var isOn: Bool
    var temperature: Int = 26

    enum DeviceType {
        case light, aircon, tv, fan, other

        var icon: String {
            switch self {
            case .light: return "lightbulb.fill"
            case .aircon: return "snowflake"
            case .tv: return "tv.fill"
            case .fan: return "fan.fill"
            case .other: return "plug.fill"
            }
        }
    }
}
