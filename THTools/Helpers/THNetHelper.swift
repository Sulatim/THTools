
import UIKit

struct THNetHelper {
    static var apiDomain: String = ""
}

private enum THLogger: String, THLoggerProtocol {

    case netHelper

    var showMillionSec: Bool { return true }
    var showFileLine: Bool { return false }
    var name: String { return self.rawValue}

    func shouldShowLog() -> Bool {
        return THTools.showToolLog
    }
}

// MARK: - Net Connector
class THNetConector<T: Decodable>: NSObject {

    private var hostDomain: String {
        return THNetHelper.apiDomain
    }

    var showPostBody = true
    var showResponse = false
    private var strUrl: String = ""
    private var postBody: Any?

    var modifyRequest: ((URLRequest) -> URLRequest)?
    var checkResultClosure: ((T?) -> (ok: Bool, err: String))?

    init(suffix: String = "", body: Any? = nil) {
        super.init()
        self.strUrl = "\(hostDomain)\(suffix)"

        self.postBody = body
    }

    init(url: String) {
        self.strUrl = url
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

            if let body = try? JSONSerialization.data(withJSONObject: post, options: .fragmentsAllowed) {
                request.httpBody = body
                if showPostBody {
                    THLogger.netHelper.log("post:\(String.init(data: body, encoding: String.Encoding.utf8) ?? "")")
                }
            }
        }

        if let modifyF = self.modifyRequest {
            request = modifyF(request)
        }

        return request
    }

    func startRequest(complete: @escaping (Bool, String, T?) -> Void) {

        guard let request = makeRequest() else {
            complete(false, "Invalid url!", nil)
            return
        }

        THLogger.netHelper.log("start: \(request.url?.absoluteString ?? "unknow")")
        URLSession.shared.dataTask(with: request, completionHandler: { (data, _, error) in
            if let err = error {
                DispatchQueue.main.async {
                    complete(false, err.localizedDescription, nil)
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    complete(false, "no data", nil)
                }
                return
            }
            THLogger.netHelper.log("response of: \(self.strUrl)")
            if self.showResponse {
                THLogger.netHelper.log("\(String.init(data: data, encoding: String.Encoding.utf8) ?? "")")
            } else {
                THLogger.netHelper.log("data.count = \(data.count)")
            }

            let decoder = JSONDecoder()
            let result = try? decoder.decode(T.self, from: data)
            if result == nil {
                THLogger.netHelper.log("unknow data type: \(String.init(data: data, encoding: .utf8) ?? "unknow")")
            }

            if let checker = self.checkResultClosure {
                let rTmp = checker(result)
                if rTmp.ok == false {
                    if result == nil {
                        DispatchQueue.main.async {
                            complete(false, "parse fail", nil)
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        complete(false, rTmp.err, nil)
                    }
                    return
                }
            } else {
                if result == nil {
                    DispatchQueue.main.async {
                        complete(false, "parse fail", nil)
                    }
                    return
                }
            }

            DispatchQueue.main.async {
                complete(true, "", result)
            }
        }).resume()
    }
}
