
import UIKit

public struct THNetHelperConfig {
    public static var hostDomain: String = ""
    public static var hostDomainGetter: (() -> String)?

    public static func setAllLogSwitchTo(on: Bool) {
        self.showBasicLog = on
        self.showPostDataLog = on
        self.showResponseLog = on
    }
    public static var showPostDataLog = false
    public static var showResponseLog = false
    public static var showBasicLog = false
    static let logger = THLogger.init(name: "THNetHelper")

    public static var universalRequestRegulator: ((URLRequest) -> URLRequest)?
    public static var universalResultChecker: THNethelperCheckResultClosure?
    
    fileprivate static var shared = THNetworkDelegateBridge()
    public static var urlDelegate: URLSessionDelegate?
}

class THNetworkDelegateBridge: NSObject, URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let delegate = THNetHelperConfig.urlDelegate {
            delegate.urlSession?(session, didReceive: challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

public typealias THNethelperCheckResultClosure = ((Any?, Data) -> (ok: Bool, err: String?, shouldSkip: Bool))

public class THNetworkHelper<T: Decodable>: NSObject, URLSessionTaskDelegate {

    private var hostDomain: String {
        var result = THNetHelperConfig.hostDomain
        if let closure = THNetHelperConfig.hostDomainGetter {
            result = closure()
        }

        return result
    }

    public var showPostBody = false
    public var showResponse = false
    private var strUrl: String = ""
    private var postBody: Any?

    public var modifyRequest: ((URLRequest) -> URLRequest)?
    public var checkResultClosure: THNethelperCheckResultClosure?

    public init(suffix: String = "", body: Any? = nil) {
        super.init()
        self.strUrl = "\(hostDomain)\(suffix)"

        self.postBody = body
        afterInit()
    }

    public init(url: String, body: Any? = nil) {
        super.init()

        self.strUrl = url
        self.postBody = body
        self.afterInit()
    }

    private func afterInit() {
        self.showPostBody = THNetHelperConfig.showPostDataLog
        self.showResponse = THNetHelperConfig.showResponseLog
        self.modifyRequest = THNetHelperConfig.universalRequestRegulator
        self.checkResultClosure = THNetHelperConfig.universalResultChecker
    }

    private func makeRequest() -> URLRequest? {

        var urlString = strUrl
        if let url = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString = url
        }

        guard let url = URL(string: urlString) else {
            return nil
        }
        var request = URLRequest(url: url)

        request.httpMethod = "GET"

        if let post = postBody {
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            if let p2 = postBody as? Encodable {
                let encoder = JSONEncoder()
                request.httpBody = try? encoder.encode(p2)
            } else if let body = try? JSONSerialization.data(withJSONObject: post, options: .fragmentsAllowed) {
                request.httpBody = body
            }
        }

        if let modifyF = self.modifyRequest {
            request = modifyF(request)
        }

        return request
    }

    private var completion: ((THNetworkResponse<T>) -> Void)?
    public func startRequest(complete: @escaping (THNetworkResponse<T>) -> Void) {

        guard let request = makeRequest() else {
            complete(THNetworkResponse.init(success: false, errMsg: THNetworkError.invalidUrl.rawValue, data: nil, rawData: nil, urlResponse: nil, error: nil))
            return
        }
        
        if THNetHelperConfig.showBasicLog {
            var msg = "Req \(request.url?.absoluteString ?? "unknow") \(request.httpMethod ?? "")"
            
            if showPostBody, let post = request.httpBody, let bodyString = String.init(data: post, encoding: .utf8) {
                msg.append("\n")
                msg.append("Body: \(bodyString)")
            }
            THNetHelperConfig.logger.log(msg)
        }

        let session = URLSession(
                    configuration: URLSessionConfiguration.ephemeral,
                    delegate: THNetHelperConfig.shared,
                    delegateQueue: nil)
        session.configuration.timeoutIntervalForRequest = 20
        
        let task = session.dataTask(with: request, completionHandler: { (datSrc, response, error) in
            if let err = error {
                DispatchQueue.main.async {
                    complete(THNetworkResponse.init(success: false, errMsg: err.localizedDescription, data: nil, rawData: datSrc, urlResponse: response, error: error))
                }
                return
            }

            guard let data = datSrc else {
                DispatchQueue.main.async {
                    complete(THNetworkResponse.init(success: false, errMsg: THNetworkError.noData.rawValue, data: nil, rawData: datSrc, urlResponse: response, error: error))
                }
                return
            }

            let decoder = JSONDecoder()
            let result = try? decoder.decode(T.self, from: data)
            if THNetHelperConfig.showBasicLog {
                var strTmpLog = "Rsp \(self.strUrl)"
                
                if result == nil || self.showResponse {
                    strTmpLog += "\n"
                    if result == nil {
                        strTmpLog += "unknow type\n"
                    }
                    
//                    strTmpLog += "Body Count: \(data.count)\n"
                    strTmpLog += "Body: \(String.init(data: data, encoding: String.Encoding.utf8) ?? "")"
                }
                
                if strTmpLog != "" {
                    THNetHelperConfig.logger.log(strTmpLog)
                }
            }

            if let checker = self.checkResultClosure {
                let rTmp = checker(result, data)
                if rTmp.ok == false {
                    if rTmp.shouldSkip == true {
                        return
                    }
                    DispatchQueue.main.async {
                        complete(THNetworkResponse.init(success: false, errMsg: rTmp.err ?? THNetworkError.parseFail.rawValue, data: result, rawData: data, urlResponse: response, error: error))
                    }
                    return
                }
            } else {
                if result == nil {
                    DispatchQueue.main.async {
                        complete(THNetworkResponse.init(success: false, errMsg: THNetworkError.parseFail.rawValue, data: nil, rawData: data, urlResponse: response, error: error))
                    }
                    return
                }
            }

            DispatchQueue.main.async {
                complete(THNetworkResponse.init(success: true, errMsg: "", data: result, rawData: data, urlResponse: response, error: error))
            }
        })
        task.resume()
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as NSError?, error.code == NSURLErrorTimedOut {
            print("请求超时")
            // 在这里处理超时情况，例如发出通知或调用特定的回调函数
        }
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let delegate = THNetHelperConfig.urlDelegate {
            delegate.urlSession?(session, didReceive: challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - Network Response
public struct THNetworkResponse<T: Decodable> {
    public var success: Bool
    public var errMsg: String
    public var data: T?

    public var rawData: Data?
    public var urlResponse: URLResponse?
    public var error: Error?
}

public enum THNetworkError: String {
    case invalidUrl = "Invalid url"
    case noData = "no data"
    case parseFail = "parse fail"
}

extension THTools {
    public static func generateFormDataBody(rawData: Data) {
        
    }
}

