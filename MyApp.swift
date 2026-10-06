import SwiftUI
import Combine
import Darwin
import IOKit.ps
import ServiceManagement

// MARK: - Preferences Model
class Preferences: ObservableObject {
    @AppStorage("updateInterval") var updateInterval: Double = 2.0
    @AppStorage("showCPU") var showCPU: Bool = true
    @AppStorage("showMemory") var showMemory: Bool = true
    @AppStorage("showDisk") var showDisk: Bool = true
    @AppStorage("showNetwork") var showNetwork: Bool = true
    @AppStorage("showBattery") var showBattery: Bool = true
    @AppStorage("showUptime") var showUptime: Bool = true
    @AppStorage("compactMenuBar") var compactMenuBar: Bool = true
    @AppStorage("showMenuBarCPU") var showMenuBarCPU: Bool = true
    @AppStorage("showMenuBarMemory") var showMenuBarMemory: Bool = true
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
}

// MARK: - App Entry
@main
struct MyApp: App {
    @StateObject private var prefs = Preferences()

    var body: some Scene {
        MenuBarExtra {
            StatsView(prefs: prefs)
        } label: {
            MenuBarLabel(prefs: prefs)
        }
        .menuBarExtraStyle(.window)

        Settings {
            PreferencesView(prefs: prefs)
        }
    }
}

// MARK: - Menu Bar Label
struct MenuBarLabel: View {
    @ObservedObject var prefs: Preferences
    @State private var cpu: Double = 0
    @State private var mem: Double = 0
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform.path.ecg")
            if prefs.compactMenuBar {
                if prefs.showMenuBarCPU {
                    Text(String(format: "%.0f%%", cpu)).monospacedDigit()
                }
                if prefs.showMenuBarMemory {
                    Text(String(format: "%.0f%%", mem)).monospacedDigit()
                }
            }
        }
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
        .onChange(of: prefs.updateInterval) { _, _ in startTimer() }
    }

    private func startTimer() {
        timer?.invalidate()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: prefs.updateInterval, repeats: true) { _ in
            refresh()
        }
    }

    private func refresh() {
        cpu = SystemStats.cpuUsagePercent()
        mem = SystemStats.memoryUsagePercent()
    }
}

// MARK: - Stats View (dropdown)
struct StatsView: View {
    @ObservedObject var prefs: Preferences
    @State private var cpu: String = "…"
    @State private var mem: String = "…"
    @State private var disk: String = "…"
    @State private var netDown: String = "…"
    @State private var netUp: String = "…"
    @State private var battery: String = "…"
    @State private var uptime: String = "…"
    @State private var timer: Timer?
    @State private var lastNetSample: SystemStats.NetSample?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("System Monitor").font(.headline)
                Spacer()
                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help("Preferences")
            }
            Divider()

            if prefs.showCPU {
                statRow("CPU", cpu, icon: "cpu")
            }
            if prefs.showMemory {
                statRow("Memory", mem, icon: "memorychip")
            }
            if prefs.showDisk {
                statRow("Disk", disk, icon: "internaldrive")
            }
            if prefs.showNetwork {
                statRow("Net ↓", netDown, icon: "arrow.down.circle")
                statRow("Net ↑", netUp, icon: "arrow.up.circle")
            }
            if prefs.showBattery {
                statRow("Battery", battery, icon: "battery.100")
            }
            if prefs.showUptime {
                statRow("Uptime", uptime, icon: "clock")
            }

            Divider()
            HStack {
                Button("Copy") { copyStats() }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(12)
        .frame(width: 260)
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
        .onChange(of: prefs.updateInterval) { _, _ in startTimer() }
    }

    @ViewBuilder
    private func statRow(_ label: String, _ value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon).frame(width: 18)
            Text(label)
            Spacer()
            Text(value).monospacedDigit()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: prefs.updateInterval, repeats: true) { _ in
            refresh()
        }
    }

    private func refresh() {
        cpu = String(format: "%.1f%%", SystemStats.cpuUsagePercent())
        mem = SystemStats.memoryUsageString()
        disk = SystemStats.diskUsageString()
        if let (down, up) = SystemStats.networkRates(previous: lastNetSample) {
            netDown = down
            netUp = up
        }
        lastNetSample = SystemStats.currentNetworkSample()
        battery = SystemStats.batteryString()
        uptime = SystemStats.uptimeString()
    }

    private func copyStats() {
        let text = """
        CPU: \(cpu)
        Memory: \(mem)
        Disk: \(disk)
        Net ↓: \(netDown)
        Net ↑: \(netUp)
        Battery: \(battery)
        Uptime: \(uptime)
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Preferences Window
struct PreferencesView: View {
    @ObservedObject var prefs: Preferences

    var body: some View {
        Form {
            Section("Update") {
                Picker("Refresh interval", selection: $prefs.updateInterval) {
                    Text("1 second").tag(1.0)
                    Text("2 seconds").tag(2.0)
                    Text("5 seconds").tag(5.0)
                    Text("10 seconds").tag(10.0)
                }
                Toggle("Launch at login", isOn: $prefs.launchAtLogin)
                    .onChange(of: prefs.launchAtLogin) { _, newValue in
                        LaunchAtLogin.set(enabled: newValue)
                    }
            }

            Section("Menu Bar") {
                Toggle("Show values in menu bar", isOn: $prefs.compactMenuBar)
                Toggle("  Show CPU", isOn: $prefs.showMenuBarCPU)
                    .disabled(!prefs.compactMenuBar)
                Toggle("  Show Memory", isOn: $prefs.showMenuBarMemory)
                    .disabled(!prefs.compactMenuBar)
            }

            Section("Dropdown Stats") {
                Toggle("CPU", isOn: $prefs.showCPU)
                Toggle("Memory", isOn: $prefs.showMemory)
                Toggle("Disk", isOn: $prefs.showDisk)
                Toggle("Network", isOn: $prefs.showNetwork)
                Toggle("Battery", isOn: $prefs.showBattery)
                Toggle("Uptime", isOn: $prefs.showUptime)
            }
        }
        .padding(20)
        .frame(width: 340)
    }
}

// MARK: - Launch At Login helper
enum LaunchAtLogin {
    static func set(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("LaunchAtLogin error: \(error)")
            }
        }
    }
}

// MARK: - System Stats Engine
enum SystemStats {

    // MARK: CPU
    static func cpuUsagePercent() -> Double {
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0

        let result = host_processor_info(mach_host_self(),
                                         PROCESSOR_CPU_LOAD_INFO,
                                         &numCPUs,
                                         &cpuInfo,
                                         &numCpuInfo)
        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else { return 0 }
        defer {
            let size = vm_size_t(numCpuInfo) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), size)
        }

        var totalUsage: Double = 0
        for i in 0..<Int(numCPUs) {
            let base = i * Int(CPU_STATE_MAX)
            let user = Double(cpuInfo[base + Int(CPU_STATE_USER)])
            let system = Double(cpuInfo[base + Int(CPU_STATE_SYSTEM)])
            let nice = Double(cpuInfo[base + Int(CPU_STATE_NICE)])
            let idle = Double(cpuInfo[base + Int(CPU_STATE_IDLE)])
            let total = user + system + nice + idle
            if total > 0 {
                totalUsage += (user + system + nice) / total
            }
        }
        return (totalUsage / Double(numCPUs)) * 100
    }

    // MARK: Memory
    static func memoryUsagePercent() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }

        let pageSize = Double(vm_kernel_page_size)
        let active = Double(stats.active_count) * pageSize
        let wired = Double(stats.wire_count) * pageSize
        let compressed = Double(stats.compressor_page_count) * pageSize
        let used = active + wired + compressed
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        return (used / total) * 100
    }

    static func memoryUsageString() -> String {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return "N/A" }

        let pageSize = Double(vm_kernel_page_size)
        let active = Double(stats.active_count) * pageSize
        let wired = Double(stats.wire_count) * pageSize
        let compressed = Double(stats.compressor_page_count) * pageSize
        let used = active + wired + compressed
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        let percent = (used / total) * 100
        let usedGB = used / 1_073_741_824
        let totalGB = total / 1_073_741_824
        return String(format: "%.1f%% (%.1f/%.0f GB)", percent, usedGB, totalGB)
    }

    // MARK: Disk
    static func diskUsageString() -> String {
        let url = URL(fileURLWithPath: "/")
        do {
            let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
            guard let total = values.volumeTotalCapacity,
                  let available = values.volumeAvailableCapacityForImportantUsage else {
                return "N/A"
            }
            let used = Double(total) - Double(available)
            let percent = (used / Double(total)) * 100
            let usedGB = used / 1_073_741_824
            let totalGB = Double(total) / 1_073_741_824
            return String(format: "%.1f%% (%.1f/%.0f GB)", percent, usedGB, totalGB)
        } catch {
            return "N/A"
        }
    }

    // MARK: Network
    struct NetSample {
        let rx: UInt64
        let tx: UInt64
        let time: Date
    }

    static func currentNetworkSample() -> NetSample? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var rx: UInt64 = 0
        var tx: UInt64 = 0
        var ptr = first
        while true {
            let ifa = ptr.pointee
            if ifa.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                let name = String(cString: ifa.ifa_name)
                if !name.hasPrefix("lo") {
                    if let data = ifa.ifa_data {
                        let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                        rx += UInt64(networkData.ifi_ibytes)
                        tx += UInt64(networkData.ifi_obytes)
                    }
                }
            }
            guard let next = ifa.ifa_next else { break }
            ptr = next
        }
        return NetSample(rx: rx, tx: tx, time: Date())
    }

    static func networkRates(previous: NetSample?) -> (down: String, up: String)? {
        guard let previous = previous, let current = currentNetworkSample() else { return nil }
        let elapsed = current.time.timeIntervalSince(previous.time)
        guard elapsed > 0 else { return nil }

        let rxBytes = current.rx >= previous.rx ? current.rx - previous.rx : 0
        let txBytes = current.tx >= previous.tx ? current.tx - previous.tx : 0

        let downRate = Double(rxBytes) / elapsed
        let upRate = Double(txBytes) / elapsed

        return (formatBytesPerSec(downRate), formatBytesPerSec(upRate))
    }

    static func formatBytesPerSec(_ bytesPerSec: Double) -> String {
        let kb = bytesPerSec / 1024
        let mb = kb / 1024
        if mb >= 1 {
            return String(format: "%.1f MB/s", mb)
        } else if kb >= 1 {
            return String(format: "%.1f KB/s", kb)
        } else {
            return String(format: "%.0f B/s", bytesPerSec)
        }
    }

    // MARK: Battery
    static func batteryString() -> String {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
            return "No battery"
        }

        let current = description[kIOPSCurrentCapacityKey as String] as? Int ?? 0
        let max = description[kIOPSMaxCapacityKey as String] as? Int ?? 100
        let isCharging = description[kIOPSIsChargingKey as String] as? Bool ?? false
        let isPlugged = (description[kIOPSPowerSourceStateKey as String] as? String) == (kIOPSACPowerValue as String)

        let percent = max > 0 ? (Double(current) / Double(max)) * 100 : 0
        let symbol = isCharging ? "⚡" : (isPlugged ? "🔌" : "")
        return String(format: "%.0f%% %@", percent, symbol)
    }

    // MARK: Uptime
    static func uptimeString() -> String {
        let uptime = ProcessInfo.processInfo.systemUptime
        let days = Int(uptime) / 86400
        let hours = (Int(uptime) % 86400) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
