
import UIKit

// MARK: - Net Connector
public class THNetworkHelper<T: Decodable>: NSObject {

    private var hostDomain: String {
        return THTools.ToolConstants.netHelperDefaultDomain
    }

    public var showPostBody = false
    public var showResponse = false
    private var strUrl: String = ""
    private var postBody: Any?

    public var modifyRequest: ((URLRequest) -> URLRequest)?
    public var checkResultClosure: ((T?) -> (ok: Bool, err: String))?

    public init(suffix: String = "", body: Any? = nil) {
        super.init()
        self.strUrl = "\(hostDomain)\(suffix)"

        self.postBody = body
        afterInit()
    }

    public init(url: String) {
        super.init()

        self.strUrl = url
        self.afterInit()
    }

    private func afterInit() {
        self.showPostBody = THTools.Logger.nhPostBody
        self.showResponse = THTools.Logger.nhResponse
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
                    THTools.Logger.netHelper.log("post:\(String.init(data: body, encoding: String.Encoding.utf8) ?? "")")
                }
            }
        }

        if let modifyF = self.modifyRequest {
            request = modifyF(request)
        }

        return request
    }

    public func startRequest(complete: @escaping (Bool, String, T?) -> Void) {

        guard let request = makeRequest() else {
            complete(false, "Invalid url!", nil)
            return
        }

        THTools.Logger.netHelper.log("start: \(request.url?.absoluteString ?? "unknow")")
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
            THTools.Logger.netHelper.log("response of: \(self.strUrl)")
            if self.showResponse {
                THTools.Logger.netHelper.log("\(String.init(data: data, encoding: String.Encoding.utf8) ?? "")")
            } else {
                THTools.Logger.netHelper.log("data.count = \(data.count)")
            }

            let decoder = JSONDecoder()
            let result = try? decoder.decode(T.self, from: data)
            if result == nil {
                THTools.Logger.netHelper.log("unknow data type: \(String.init(data: data, encoding: .utf8) ?? "unknow")")
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
