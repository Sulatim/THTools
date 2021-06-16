
import Foundation

public protocol THLoggerProtocol {
    var showMillionSec: Bool { get }
    var showFileLine: Bool { get }
    var name: String { get }

    func log(_ msg: String, file: String, line: Int)
    func shouldShowLog() -> Bool
}

public extension THLoggerProtocol {
    func log(_ msg: String, file: String = #file, line: Int = #line ) {
        if self.shouldShowLog() == false {
            return
        }
        
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        if showMillionSec {
            fmt.dateFormat = "HH:mm:ss.SSS"
        }
        var fileLine = ""
        if showFileLine {
            let fName = (file.split(separator: "/").last ?? "").replacingOccurrences(of: ".swift", with: "")
            fileLine = "{\(fName).\(line)} "
        }
        print("\(fmt.string(from: Date())) [\(self.name)] \(fileLine)\(msg)")
    }

    func shouldShowLog() -> Bool {
        return true
    }
}

enum THLogger: String, THLoggerProtocol {

    case netHelper
    case scanner
    case notification

    var showMillionSec: Bool { return false }
    var showFileLine: Bool { return false }
    var name: String { return self.rawValue}

    func shouldShowLog() -> Bool {
        if THTools.ToolConstants.Logger.on == false {
            return false
        }

        switch self {
        case .netHelper: return THTools.ToolConstants.Logger.netHelper
        case .scanner: return THTools.ToolConstants.Logger.scanner
        case .notification: return THTools.ToolConstants.Logger.notificaton
        }
    }
}
