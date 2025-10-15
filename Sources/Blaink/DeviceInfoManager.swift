//
//  DeviceInfoManager.swift
//  Blaink
//
//  Prompted by Raşid Ramazanov using Cursor on 15.10.2025.
//

#if canImport(UIKit)
import Foundation
import UIKit
import Network
import CoreTelephony
import SystemConfiguration
#else
import Foundation
#endif

@MainActor public final class DeviceInfoManager {
    #if canImport(UIKit)
    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var currentNetworkPath: NWPath?
    #endif
    
    public init() {
        #if canImport(UIKit)
        startNetworkMonitoring()
        #endif
    }
    
    #if canImport(UIKit)
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.currentNetworkPath = path
            }
        }
        networkMonitor.start(queue: queue)
    }
    #endif
    
    public func getDeviceInfo() -> String {
        #if canImport(UIKit)
        let deviceInfo = DeviceInfo(
            device: getDeviceInformation(),
            network: getNetworkInformation(),
            system: getSystemInformation(),
            timestamp: Date().timeIntervalSince1970
        )
        
        do {
            let jsonData = try JSONEncoder().encode(deviceInfo)
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            print("Failed to encode device info: \(error)")
            return "{}"
        }
        #else
        return "{\"error\": \"UIKit not available\"}"
        #endif
    }
    
    #if canImport(UIKit)
    private func getDeviceInformation() -> DeviceInformation {
        let device = UIDevice.current
        
        return DeviceInformation(
            model: device.model,
            name: device.name,
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            identifierForVendor: device.identifierForVendor?.uuidString,
            userInterfaceIdiom: device.userInterfaceIdiom.description,
            batteryLevel: device.batteryLevel >= 0 ? device.batteryLevel : nil,
            batteryState: device.batteryState.description,
            orientation: device.orientation.description,
            isMultitaskingSupported: device.isMultitaskingSupported,
            screenBounds: getScreenBounds(),
            screenScale: UIScreen.main.scale,
            preferredLanguages: Locale.preferredLanguages.prefix(3).map { String($0) },
            currentLocale: Locale.current.identifier,
            timeZone: TimeZone.current.identifier
        )
    }
    #endif
    
    private func getNetworkInformation() -> NetworkInformation {
        #if canImport(UIKit)
        var networkInfo = NetworkInformation(
            connectionType: getConnectionType(),
            isConnected: currentNetworkPath?.status == .satisfied,
            isExpensive: currentNetworkPath?.isExpensive ?? false,
            isConstrained: currentNetworkPath?.isConstrained ?? false,
            supportsIPv4: currentNetworkPath?.supportsIPv4 ?? false,
            supportsIPv6: currentNetworkPath?.supportsIPv6 ?? false,
            supportsDNS: currentNetworkPath?.supportsDNS ?? false,
            availableInterfaces: getAvailableInterfaces()
        )
        
        // Add cellular information if available
        if let cellularInfo = getCellularInformation() {
            networkInfo.cellular = cellularInfo
        }
        
        return networkInfo
        #else
        return NetworkInformation(
            connectionType: "unknown",
            isConnected: false,
            isExpensive: false,
            isConstrained: false,
            supportsIPv4: false,
            supportsIPv6: false,
            supportsDNS: false,
            availableInterfaces: [],
            cellular: nil
        )
        #endif
    }
    
    private func getSystemInformation() -> SystemInformation {
        return SystemInformation(
            processInfo: getProcessInformation(),
            memoryInfo: getMemoryInformation(),
            storageInfo: getStorageInformation()
        )
    }
    
    #if canImport(UIKit)
    private func getConnectionType() -> String {
        guard let path = currentNetworkPath else { return "unknown" }
        
        if path.usesInterfaceType(.wifi) {
            return "wifi"
        } else if path.usesInterfaceType(.cellular) {
            return "cellular"
        } else if path.usesInterfaceType(.wiredEthernet) {
            return "ethernet"
        } else if path.usesInterfaceType(.other) {
            return "other"
        } else {
            return "unknown"
        }
    }
    
    private func getAvailableInterfaces() -> [String] {
        guard let path = currentNetworkPath else { return [] }
        
        var interfaces: [String] = []
        
        if path.usesInterfaceType(.wifi) { interfaces.append("wifi") }
        if path.usesInterfaceType(.cellular) { interfaces.append("cellular") }
        if path.usesInterfaceType(.wiredEthernet) { interfaces.append("ethernet") }
        if path.usesInterfaceType(.other) { interfaces.append("other") }
        
        return interfaces
    }
    
    private func getCellularInformation() -> CellularInformation? {
        let networkInfo = CTTelephonyNetworkInfo()
        
        guard let carriers = networkInfo.serviceSubscriberCellularProviders,
              let radioTech = networkInfo.serviceCurrentRadioAccessTechnology else {
            return nil
        }
        
        var carrierNames: [String] = []
        var radioTechnologies: [String] = []
        
        for (_, carrier) in carriers {
            if let carrierName = carrier.carrierName {
                carrierNames.append(carrierName)
            }
        }
        
        for (_, tech) in radioTech {
            radioTechnologies.append(tech)
        }
        
        return CellularInformation(
            carrierNames: carrierNames,
            radioAccessTechnologies: radioTechnologies,
            allowsVOIP: networkInfo.serviceSubscriberCellularProviders?.values.first?.allowsVOIP
        )
    }
    
    private func getScreenBounds() -> ScreenBounds {
        let bounds = UIScreen.main.bounds
        return ScreenBounds(
            width: bounds.width,
            height: bounds.height
        )
    }
    #endif
    
    private func getProcessInformation() -> ProcessInformation {
        let processInfo = ProcessInfo.processInfo
        return ProcessInformation(
            processName: processInfo.processName,
            processIdentifier: processInfo.processIdentifier,
            globallyUniqueString: processInfo.globallyUniqueString,
            operatingSystemVersion: "\(processInfo.operatingSystemVersion.majorVersion).\(processInfo.operatingSystemVersion.minorVersion).\(processInfo.operatingSystemVersion.patchVersion)",
            processorCount: processInfo.processorCount,
            activeProcessorCount: processInfo.activeProcessorCount,
            physicalMemory: processInfo.physicalMemory,
            systemUptime: processInfo.systemUptime,
            thermalState: processInfo.thermalState.description,
            isLowPowerModeEnabled: processInfo.isLowPowerModeEnabled
        )
    }
    
    private func getMemoryInformation() -> MemoryInformation {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return MemoryInformation(
                residentSize: UInt64(info.resident_size),
                virtualSize: UInt64(info.virtual_size),
                suspendCount: UInt32(info.suspend_count)
            )
        } else {
            return MemoryInformation(
                residentSize: 0,
                virtualSize: 0,
                suspendCount: 0
            )
        }
    }
    
    private func getStorageInformation() -> StorageInformation? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        do {
            let resourceValues = try documentsPath.resourceValues(forKeys: [
                .volumeAvailableCapacityKey,
                .volumeTotalCapacityKey
            ])
            
            return StorageInformation(
                availableCapacity: resourceValues.volumeAvailableCapacity.map { Int64($0) },
                totalCapacity: resourceValues.volumeTotalCapacity.map { Int64($0) }
            )
        } catch {
            return nil
        }
    }
    
    deinit {
        #if canImport(UIKit)
        networkMonitor.cancel()
        #endif
    }
}

// MARK: - Data Models

struct DeviceInfo: Codable {
    let device: DeviceInformation
    let network: NetworkInformation
    let system: SystemInformation
    let timestamp: TimeInterval
}

struct DeviceInformation: Codable {
    let model: String
    let name: String
    let systemName: String
    let systemVersion: String
    let identifierForVendor: String?
    let userInterfaceIdiom: String
    let batteryLevel: Float?
    let batteryState: String
    let orientation: String
    let isMultitaskingSupported: Bool
    let screenBounds: ScreenBounds
    let screenScale: CGFloat
    let preferredLanguages: [String]
    let currentLocale: String
    let timeZone: String
}

struct NetworkInformation: Codable {
    let connectionType: String
    let isConnected: Bool
    let isExpensive: Bool
    let isConstrained: Bool
    let supportsIPv4: Bool
    let supportsIPv6: Bool
    let supportsDNS: Bool
    let availableInterfaces: [String]
    var cellular: CellularInformation?
}

struct CellularInformation: Codable {
    let carrierNames: [String]
    let radioAccessTechnologies: [String]
    let allowsVOIP: Bool?
}

struct SystemInformation: Codable {
    let processInfo: ProcessInformation
    let memoryInfo: MemoryInformation
    let storageInfo: StorageInformation?
}

struct ProcessInformation: Codable {
    let processName: String
    let processIdentifier: Int32
    let globallyUniqueString: String
    let operatingSystemVersion: String
    let processorCount: Int
    let activeProcessorCount: Int
    let physicalMemory: UInt64
    let systemUptime: TimeInterval
    let thermalState: String
    let isLowPowerModeEnabled: Bool
}

struct MemoryInformation: Codable {
    let residentSize: UInt64
    let virtualSize: UInt64
    let suspendCount: UInt32
}

struct StorageInformation: Codable {
    let availableCapacity: Int64?
    let totalCapacity: Int64?
}

struct ScreenBounds: Codable {
    let width: CGFloat
    let height: CGFloat
}

// MARK: - Extensions for String Descriptions

#if canImport(UIKit)
extension UIUserInterfaceIdiom {
    var description: String {
        switch self {
        case .unspecified: return "unspecified"
        case .phone: return "phone"
        case .pad: return "pad"
        case .tv: return "tv"
        case .carPlay: return "carPlay"
        case .mac: return "mac"
        case .vision: return "vision"
        @unknown default: return "unknown"
        }
    }
}

extension UIDevice.BatteryState {
    var description: String {
        switch self {
        case .unknown: return "unknown"
        case .unplugged: return "unplugged"
        case .charging: return "charging"
        case .full: return "full"
        @unknown default: return "unknown"
        }
    }
}

extension UIDeviceOrientation {
    var description: String {
        switch self {
        case .unknown: return "unknown"
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        case .faceUp: return "faceUp"
        case .faceDown: return "faceDown"
        @unknown default: return "unknown"
        }
    }
}
#endif

extension ProcessInfo.ThermalState {
    var description: String {
        switch self {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }
}
