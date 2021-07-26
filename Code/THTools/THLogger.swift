
import Foundation

public class THLogger {
    let showMillionSec: Bool
    let showFileLine: Bool
    let name: String
    public var showLog: Bool

    public init(name: String, millionSec: Bool = false, fileLine: Bool = false, showLog: Bool = true) {
        self.showMillionSec = millionSec
        self.showFileLine = fileLine
        self.name = name
        self.showLog = showLog
    }

    public func log(_ msg: String, file: String = #file, line: Int = #line ) {
        if self.showLog == false {
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
}
