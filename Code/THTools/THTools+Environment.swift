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
