
import Foundation

public class THLogger {
    let showMillionSec: Bool
    let showFileLine: Bool
    let name: String
    public var showLog: Bool

    private var datStart = Date()
    private var datPrev = Date()

    public init(name: String, millionSec: Bool = false, fileLine: Bool = false, showLog: Bool = true) {
        self.showMillionSec = millionSec
        self.showFileLine = fileLine
        self.name = name
        self.showLog = showLog
    }

    public func startTime(_ msg: String = "", file: String = #file, line: Int = #line) {
        self.datStart = Date()
        self.datPrev = Date()
        self.log("\(msg) S: \(datStart.timeIntervalSince1970)", file: file, line: line)
    }

    public func logInterval(_ msg: String, file: String = #file, line: Int = #line) {
        let datTmp = Date()
        self.log("\(msg) I: \(datTmp.timeIntervalSince(self.datPrev))")
        self.datPrev = datTmp
    }

    public func logIntervalFromStart(_ msg: String = "", file: String = #file, line: Int = #line) {
        let datTmp = Date()
        self.log("\(msg) E:\(datTmp.timeIntervalSince1970) IS: \(datTmp.timeIntervalSince(self.datStart))")
    }

    public func log(_ msg: String, file: String = #file, line: Int = #line) {
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
        let str = "\(fmt.string(from: Date())) [\(self.name)] \(fileLine)\(msg)"
        print(str)
        FileLogger.shared.log(str)
    }
}

public class FileLogger {
    public static let shared = FileLogger()

    private init() {}

    public func log(_ message: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = dateFormatter.string(from: Date())

        let logMessage = "\(message)\n"

        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        let logFile = documentsPath.appendingPathComponent("\(currentDate).log")

        // 追加文本到日志文件
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = FileHandle(forWritingAtPath: logFile.path) {
                fileHandle.seekToEndOfFile()
                if let data = logMessage.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
        } else {
            // 文件不存在，创建文件并写入
            do {
                try logMessage.write(to: logFile, atomically: true, encoding: .utf8)
            } catch {
                print("Unable to write to log file: \(error)")
            }
        }
    }
}
