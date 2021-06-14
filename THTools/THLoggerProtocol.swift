
import Foundation

protocol THLoggerProtocol {
    var showMillionSec: Bool { get }
    var showFileLine: Bool { get }
    var name: String { get }

    func log(_ msg: String, file: String, line: Int)
    func shouldShowLog() -> Bool
}

extension THLoggerProtocol {
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
