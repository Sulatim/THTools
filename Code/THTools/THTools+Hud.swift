
import Foundation
import KRProgressHUD

extension THTools.Validate {
    public static func txtIsEmpty(txt: UITextField, msg: String) -> Bool {
        if txt.text == nil || txt.text == "" {
            KRProgressHUD.showMessage(msg, completion: {
                txt.becomeFirstResponder()
            })

            return true
        }

        return false
    }

    public static func txtIsEmpty(txt: UITextField) -> Bool {
        return txtIsEmpty(txt: txt, msg: txt.placeholder ?? "")
    }

    public static func batchCheckTxtHasEmpty(_ checkList: [(txt: UITextField, msg: String)]) -> Bool {
        for item in checkList {
            if txtIsEmpty(txt: item.txt, msg: item.msg) {
                return true
            }
        }

        return false
    }

    /// 錯誤訊息會以
    public static func batchCheckTxtHasEmpty(_ checkList: [UITextField]) -> Bool {
        for item in checkList {
            if txtIsEmpty(txt: item) {
                return true
            }
        }

        return false
    }
}

extension KRProgressHUD {
    public static func showError(_ msg: String, completion: (() -> Void)?) {
        KRProgressHUD.showError(withMessage: msg)
        DispatchQueue.main.asyncAfter(deadline: .now() + THHudPlusConfig.errorDisplayTime) {
            KRProgressHUD.dismiss {
                completion?()
            }
        }
    }

    public static func showSuccess(_ msg: String?, completion: (() -> Void)?) {
        KRProgressHUD.showSuccess(withMessage: msg)
        DispatchQueue.main.asyncAfter(deadline: .now() + THHudPlusConfig.successDisplayTime) {
            KRProgressHUD.dismiss {
                completion?()
            }
        }
    }

    public static func showSuccess(completion: (() -> Void)?) {
        KRProgressHUD.showSuccess()
        DispatchQueue.main.asyncAfter(deadline: .now() + THHudPlusConfig.successDisplayTime) {
            KRProgressHUD.dismiss {
                completion?()
            }
        }
    }

    public static func showMessage(_ message: String, completion: (() -> Void)?) {
        KRProgressHUD.showMessage(message)
        DispatchQueue.main.asyncAfter(deadline: .now() + THHudPlusConfig.msgDisplayTime) {
            KRProgressHUD.dismiss {
                completion?()
            }
        }
    }
}

public struct THHudPlusConfig {
    public static var msgDisplayTime: TimeInterval = 1
    public static var successDisplayTime: TimeInterval = 1
    public static var errorDisplayTime: TimeInterval = 2
}
