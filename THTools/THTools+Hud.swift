
import Foundation
import KRProgressHUD

extension THTools.Validate {
    static func txtIsEmpty(txt: UITextField, msg: String) -> Bool {
        if txt.text == nil || txt.text == "" {
            KRProgressHUD.showError(msg) {
                txt.becomeFirstResponder()
            }
            
            return true
        }

        return false
    }

    static func batchCheckTxtHasEmpty(_ checkList: [(txt: UITextField, msg: String)]) -> Bool {
        for item in checkList {
            if txtIsEmpty(txt: item.txt, msg: item.msg) {
                return true
            }
        }

        return false
    }
}

extension KRProgressHUD {
    static func showError(_ msg: String, completion: (() -> Void)?) {
        KRProgressHUD.showError(withMessage: msg)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            KRProgressHUD.dismiss {
                completion?()
            }
        }
    }

    static func showSuccess(_ msg: String?, completion: (() -> Void)?) {
        KRProgressHUD.showSuccess(withMessage: msg)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            KRProgressHUD.dismiss {
                completion?()
            }
        }
    }
}