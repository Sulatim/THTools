//
//  THTools+Environment.swift
//  THTools
//
//  Created by Tim Ho on 2021/8/23.
//

import UIKit
import LocalAuthentication

extension THTools {
    public struct Environment {
        public static var isSimulator: Bool {
            var result = false
            #if arch(i386) || arch(x86_64)
            result = true
            #endif

            return result
        }

        public static func getMainVersion() -> String {
            return (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        }

        public static func getVersion(prefix pf: String? = nil) -> String {
            let main = self.getMainVersion()
            let build = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? ""
            var prefix = "V"
            if let pfFromOutside = pf {
                prefix = pfFromOutside
            }

            return "\(prefix)\(main) (\(build))"
        }

        public static func getDeviceID() -> String {
            if let deviceID = UserDefaults.app.string(forKey: "deviceID") {
                return deviceID
            }
            let strNew = UUID().uuidString
            UserDefaults.app.setValue(strNew, forKey: "deviceID")
            UserDefaults.app.synchronize()

            return strNew
        }

        public static func getOSVersion() -> String {
            return "\(UIDevice.current.systemVersion)"
        }

        public static func getMachineName() -> String {
            var utsnameInstance = utsname()
            uname(&utsnameInstance)
            let optionalString: String? = withUnsafePointer(to: &utsnameInstance.machine) {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    ptr in String.init(validatingUTF8: ptr)
                }
            }
            return optionalString ?? "N/A"
        }

        public static func getSupportBiometricType() -> THBiometricType {
            let authenticationContext = LAContext()
            if authenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) == false {
                return .none
            }

            switch (authenticationContext.biometryType){
            case .faceID:
                return .face
            case .touchID:
                return .touch
            default:
                return .none
            }
        }

        public static func getSystemFirstLanguage() -> String {
            return NSLocale.preferredLanguages.first ?? "en_gb"
        }
    }
}

public enum THBiometricType{
    case touch
    case face
    case none
}

extension THTools.Environment {
    public struct Version {
        let prefix: String
        let major: Int
        let minor: Int
        let build: Int
        
        init?(_ versionString: String) {
//            let regex = #"(\D+)(\d+)\.(\d+)\s+\((\d+)\)"#
//            guard let match = versionString.range(of: regex, options: .regularExpression) else { return nil }
            guard versionString.isEmpty == false else { return nil }
            let prefix = "\(versionString.first!)".trimmingCharacters(in: .whitespaces)
            
            let ary1 = versionString.split(separator: "(")
            guard ary1.count == 2 else { return nil }
            
            let buildNoString = "\(ary1[1])".replacingOccurrences(of: ")", with: "").trimmingCharacters(in: .whitespaces)
            let ary2 = "\(ary1[0])".replacingOccurrences(of: prefix, with: "").split(separator: ".")
            guard ary2.count >= 2 else { return nil }
            
            let majorString = "\(ary2[0])".trimmingCharacters(in: .whitespaces)
            let minorString = "\(ary2[1])".trimmingCharacters(in: .whitespaces)
            
            let major = Int(majorString) ?? 0
            let minor = Int(minorString) ?? 0
            let build = Int(buildNoString) ?? 0
            self.prefix = prefix
            self.major = major
            self.minor = minor
            self.build = build
        }
    }
}

extension THTools.Environment.Version: Comparable {
    static public func < (lhs: THTools.Environment.Version, rhs: THTools.Environment.Version) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        } else if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        } else if lhs.build != rhs.build {
            return lhs.build < rhs.build
        } else if lhs.prefix != rhs.prefix {
            let lhsIdx = lhs.prefix == "D" ? 0 : 10
            let rhsIdx = rhs.prefix == "D" ? 0 : 10
            return lhsIdx < rhsIdx
        }
        
        return false
    }
}
