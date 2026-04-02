import Foundation
import Network
#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(Security)
import Security
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif

public struct NowCoreContext: @unchecked Sendable {
    public let bundle: Bundle
    public let fileManager: FileManager
    public let userDefaultsProvider: @Sendable (String?) -> UserDefaults

    public init(
        bundle: Bundle = .main,
        fileManager: FileManager = .default,
        userDefaultsProvider: @escaping @Sendable (String?) -> UserDefaults = { sharedName in
            if let sharedName, let defaults = UserDefaults(suiteName: sharedName) {
                return defaults
            }
            return .standard
        }
    ) {
        self.bundle = bundle
        self.fileManager = fileManager
        self.userDefaultsProvider = userDefaultsProvider
    }

    public static let live = NowCoreContext()
}

public protocol IPlatformSettingService: Sendable {
    @MainActor
    func gotoPermissionSettings() -> Bool

    @MainActor
    var isLocationEnabled: Bool { get }
}

public protocol IFileSystemService: Sendable {
    var cachePath: String { get }
    var appDataPath: String { get }
}

public enum NowCore {
    nonisolated(unsafe) private static var state = State(context: .live)
    private static let stateLock = NSLock()

    public static func initialize(context: NowCoreContext) {
        stateLock.lock()
        state = State(context: context)
        stateLock.unlock()
    }

    static var context: NowCoreContext {
        stateLock.lock()
        defer { stateLock.unlock() }
        return state.context
    }

    static var services: WilmarServiceLocator {
        stateLock.lock()
        defer { stateLock.unlock() }
        return state.serviceLocator
    }

    struct State {
        var context: NowCoreContext
        var serviceLocator: WilmarServiceLocator

        init(context: NowCoreContext) {
            self.context = context
            self.serviceLocator = WilmarServiceLocator()
            self.serviceLocator.register(IPlatformSettingService.self, service: PlatformSettingService())
            self.serviceLocator.register(IFileSystemService.self, service: FileSystemService(context: context))
        }
    }
}

public final class WilmarServiceLocator: @unchecked Sendable {
    private let lock = NSLock()
    private var services: [ObjectIdentifier: Any] = [:]

    public init() {}

    public func register<T>(_ type: T.Type, service: T) {
        lock.lock()
        services[ObjectIdentifier(type)] = service
        lock.unlock()
    }

    public func getService<T>(_ type: T.Type = T.self) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return services[ObjectIdentifier(type)] as? T
    }
}

public enum NowPreferences {
    public static func containsKey(_ key: String, sharedName: String? = nil) -> Bool {
        defaults(sharedName).object(forKey: key) != nil
    }

    public static func remove(_ key: String, sharedName: String? = nil) {
        defaults(sharedName).removeObject(forKey: key)
    }

    public static func clear(sharedName: String? = nil) {
        let defaults = defaults(sharedName)
        if let sharedName {
            defaults.removePersistentDomain(forName: sharedName)
        } else if let bundleIdentifier = NowCore.context.bundle.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleIdentifier)
        } else {
            defaults.dictionaryRepresentation().keys.forEach(defaults.removeObject(forKey:))
        }
        defaults.synchronize()
    }

    public static func set(_ key: String, value: String, sharedName: String? = nil) {
        defaults(sharedName).set(value, forKey: key)
    }

    public static func get(_ key: String, defaultValue: String = "", sharedName: String? = nil) -> String {
        defaults(sharedName).string(forKey: key) ?? defaultValue
    }

    public static func set(_ key: String, value: Bool, sharedName: String? = nil) {
        defaults(sharedName).set(value, forKey: key)
    }

    public static func get(_ key: String, defaultValue: Bool = false, sharedName: String? = nil) -> Bool {
        if defaults(sharedName).object(forKey: key) == nil {
            return defaultValue
        }
        return defaults(sharedName).bool(forKey: key)
    }

    public static func set(_ key: String, value: Int, sharedName: String? = nil) {
        defaults(sharedName).set(value, forKey: key)
    }

    public static func get(_ key: String, defaultValue: Int = 0, sharedName: String? = nil) -> Int {
        if defaults(sharedName).object(forKey: key) == nil {
            return defaultValue
        }
        return defaults(sharedName).integer(forKey: key)
    }

    public static func set(_ key: String, value: Int64, sharedName: String? = nil) {
        defaults(sharedName).set(value, forKey: key)
    }

    public static func get(_ key: String, defaultValue: Int64 = 0, sharedName: String? = nil) -> Int64 {
        guard let value = defaults(sharedName).object(forKey: key) as? NSNumber else {
            return defaultValue
        }
        return value.int64Value
    }

    public static func set(_ key: String, value: Double, sharedName: String? = nil) {
        defaults(sharedName).set(value, forKey: key)
    }

    public static func get(_ key: String, defaultValue: Double = 0, sharedName: String? = nil) -> Double {
        if defaults(sharedName).object(forKey: key) == nil {
            return defaultValue
        }
        return defaults(sharedName).double(forKey: key)
    }

    public static func set(_ key: String, value: Float, sharedName: String? = nil) {
        defaults(sharedName).set(value, forKey: key)
    }

    public static func get(_ key: String, defaultValue: Float = 0, sharedName: String? = nil) -> Float {
        if defaults(sharedName).object(forKey: key) == nil {
            return defaultValue
        }
        return defaults(sharedName).float(forKey: key)
    }

    public static func set(_ key: String, value: Date, sharedName: String? = nil) {
        defaults(sharedName).set(value, forKey: key)
    }

    public static func get(_ key: String, defaultValue: Date = .distantPast, sharedName: String? = nil) -> Date {
        defaults(sharedName).object(forKey: key) as? Date ?? defaultValue
    }

    private static func defaults(_ sharedName: String?) -> UserDefaults {
        NowCore.context.userDefaultsProvider(sharedName)
    }
}

public enum EncryptedPreferences {
    private static let defaultService = "NowCore.EncryptedPreferences"

    public static func containsKey(_ key: String, sharedName: String? = nil) -> Bool {
        let query = baseQuery(key: key, sharedName: sharedName)
        #if canImport(Security)
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
        #else
        return false
        #endif
    }

    public static func remove(_ key: String, sharedName: String? = nil) {
        #if canImport(Security)
        SecItemDelete(baseQuery(key: key, sharedName: sharedName) as CFDictionary)
        #endif
    }

    public static func clear(sharedName: String? = nil) {
        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName(sharedName),
        ]
        SecItemDelete(query as CFDictionary)
        #endif
    }

    public static func set(_ key: String, value: String, sharedName: String? = nil) {
        remove(key, sharedName: sharedName)
        #if canImport(Security)
        let encoded = Data(value.utf8)
        var query = baseQuery(key: key, sharedName: sharedName)
        query[kSecValueData as String] = encoded
        SecItemAdd(query as CFDictionary, nil)
        #endif
    }

    public static func get(_ key: String, defaultValue: String = "", sharedName: String? = nil) -> String {
        #if canImport(Security)
        var query = baseQuery(key: key, sharedName: sharedName)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return defaultValue
        }
        return string
        #else
        return defaultValue
        #endif
    }

    static func encodedKey(for key: String, sharedName: String?) -> String {
        let raw = "\(serviceName(sharedName))::\(key)"
        #if canImport(CryptoKit)
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
        #else
        return raw
        #endif
    }

    private static func baseQuery(key: String, sharedName: String?) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName(sharedName),
            kSecAttrAccount as String: encodedKey(for: key, sharedName: sharedName),
        ]
    }

    private static func serviceName(_ sharedName: String?) -> String {
        sharedName ?? defaultService
    }
}

public enum NowFileSystem {
    public static var cachePath: String {
        NowCore.services.getService(IFileSystemService.self)?.cachePath ?? FileSystemService(context: .live).cachePath
    }

    public static var appDataPath: String {
        NowCore.services.getService(IFileSystemService.self)?.appDataPath ?? FileSystemService(context: .live).appDataPath
    }
}

public enum WilmarMainThread {
    public static var isMainThread: Bool {
        Thread.isMainThread
    }

    public static func beginInvokeOnMainThread(_ action: @escaping @Sendable () -> Void) {
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }
}

public enum NowNetworkAccess: Equatable, Sendable {
    case unknown
    case none
    case local
    case constrainedInternet
    case internet
}

public enum NowConnectivity {
    nonisolated(unsafe) static var provider: any ConnectivityProvider = DefaultConnectivityProvider()

    public static var networkAccess: NowNetworkAccess {
        provider.currentAccess()
    }
}

protocol ConnectivityProvider {
    func currentAccess() -> NowNetworkAccess
}

final class DefaultConnectivityProvider: ConnectivityProvider, @unchecked Sendable {
    private let lock = NSLock()
    private let monitor: NWPathMonitor
    private var current: NowNetworkAccess = .unknown

    init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            self?.lock.lock()
            self?.current = Self.map(path)
            self?.lock.unlock()
        }
        let queue = DispatchQueue(label: "NowCore.NowConnectivity")
        monitor.start(queue: queue)
    }

    func currentAccess() -> NowNetworkAccess {
        lock.lock()
        defer { lock.unlock() }
        return current
    }

    private static func map(_ path: NWPath) -> NowNetworkAccess {
        switch path.status {
        case .satisfied:
            return path.isExpensive ? .constrainedInternet : .internet
        case .unsatisfied:
            return .none
        case .requiresConnection:
            return .local
        @unknown default:
            return .unknown
        }
    }
}

public enum NowEssential {
    @MainActor
    public static var isPhoneDialerSupported: Bool {
        #if canImport(UIKit)
        guard let url = URL(string: "tel://10086") else {
            return false
        }
        return UIApplication.shared.canOpenURL(url)
        #else
        return false
        #endif
    }

    @MainActor
    @discardableResult
    public static func openDialer(_ tel: String) -> Bool {
        #if canImport(UIKit)
        guard let url = URL(string: "tel://\(tel)"),
              UIApplication.shared.canOpenURL(url) else {
            return false
        }
        UIApplication.shared.open(url)
        return true
        #else
        return false
        #endif
    }
}

struct PlatformSettingService: IPlatformSettingService {
    @MainActor
    func gotoPermissionSettings() -> Bool {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
            return false
        }
        UIApplication.shared.open(url)
        return true
        #else
        return false
        #endif
    }

    @MainActor
    var isLocationEnabled: Bool {
        #if canImport(CoreLocation)
        CLLocationManager.locationServicesEnabled()
        #else
        false
        #endif
    }
}

struct FileSystemService: IFileSystemService {
    private let context: NowCoreContext

    init(context: NowCoreContext) {
        self.context = context
    }

    var cachePath: String {
        context.fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.path ?? NSTemporaryDirectory()
    }

    var appDataPath: String {
        let baseURL = context.fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? context.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let folder = context.bundle.bundleIdentifier ?? "NowCore"
        let appDirectory = baseURL.appendingPathComponent(folder, isDirectory: true)
        try? context.fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        return appDirectory.path
    }
}
