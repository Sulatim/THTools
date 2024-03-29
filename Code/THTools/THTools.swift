
import UIKit

public struct THTools {
    public struct ToolConstants {
        public static var netHelperDefaultDomain: String = ""
    }

    public struct Logger {
        public static var on = false {
            didSet {
                self.netHelper.showLog = on
                self.scanner.showLog = on
                self.notification.showLog = on
                self.bleHelper.showLog = on
            }
        }

        public static let netHelper = THLogger.init(name: "NetHelper", showLog: false)
        public static let scanner = THLogger.init(name: "Scanner", showLog: false)
        public static let notification = THLogger.init(name: "Notification", showLog: false)
        public static let bleHelper = THLogger.init(name: "BleHelper", showLog: false)

        public static var nhPostBody = false
        public static var nhResponse = false
    }

    public static func makeQRCodeImg(qrcode: String?, scale: CGFloat = 10) -> UIImage? {
        guard let qrcode = qrcode else {
            return nil
        }

        let data = qrcode.data(using: String.Encoding.isoLatin1)

        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("Q", forKey: "inputCorrectionLevel")

        let qrcodeImage = filter?.outputImage?.transformed(by: CGAffineTransform.init(scaleX: scale, y: scale))

        return UIImage.init(ciImage: qrcodeImage!)
    }

    public static func makeVC<T: UIViewController>(type: T.Type, inStoryBoard story: String = "Main") -> T? {
        return UIStoryboard.init(name: story, bundle: nil).instantiateViewController(withIdentifier: String.init(describing: type)) as? T
    }

    public static func runInMainThread(closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async {
                closure()
            }
        }
    }

    public static func openAppSettingPage() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
}

extension THTools {
    public struct Validate {
        public static func isEmail(_ email: String?) -> Bool {
            return verifyRegex(str: email, regex: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
        }

        public static func isInputingEmail(_ inputString: String?) -> Bool {
            return verifyRegex(str: inputString, regex: "^(([A-Z0-9a-z._%+-]*)|([A-Z0-9a-z._%+-]+@)|([A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]*)|([A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]*))$")
        }

        public static func isTwPhone(_ phone: String?) -> Bool {
            return verifyRegex(str: phone, regex: "^09\\d{8}$")
        }

        public static func isInputingTwPhone(_ inputString: String?) -> Bool {
            return verifyRegex(str: inputString, regex: "^0|09|09\\d*$")
        }

        public static func isInvoiceNo(_ invNo: String?) -> Bool {
            return verifyRegex(str: invNo, regex: "^[A-Za-z]{2}\\d{8}$")
        }

        public static func isInputingInvoiceNo(_ invNo: String?) -> Bool {
            return verifyRegex(str: invNo, regex: "^[A-Za-z]{0,2}|[A-Za-z]{2}\\d{0,8}$")
        }

        private static func verifyRegex(str: String?, regex: String) -> Bool {
            guard let str = str else {
                return false
            }

            let pred = NSPredicate(format: "SELF MATCHES %@", regex)
            return pred.evaluate(with: str)
        }
    }
}

extension UIView {
    public func changeToFillet(radius: CGFloat) {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = radius
    }

    public func changeToFillet() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = self.frame.height / 2
    }

    public func addBorder(color: UIColor, width: CGFloat) {
        self.layer.borderWidth = width
        self.layer.borderColor = color.cgColor
    }

    public func addShadow(radius: CGFloat, opacity: Float = 0.5, offset: CGSize = CGSize.zero) {
        self.clipsToBounds = false
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = radius
        self.layer.shadowOffset = offset
    }

    public func findSuperView<T: UIView>(type: T.Type) -> T? {
        guard let sView = self.superview else {
            return nil
        }
        if let result = sView as? T {
            return result
        }

        return sView.findSuperView(type: type)
    }
}

extension UITableViewCell {
    static public func makeEmptyCell() -> UITableViewCell {
        let cell = UITableViewCell.init()
        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.clear
        cell.selectionStyle = .none

        return cell
    }
}

extension UITableView {
    public func dequeueReusableCell<T: UITableViewCell>(cellType: T.Type, index: IndexPath) -> T? {
        if let cell = self.dequeueReusableCell(withIdentifier: String.init(describing: cellType), for: index) as? T {
            cell.selectionStyle = .none
            return cell
        }

        return nil
    }

    public func dequeueReusableCell<T: UITableViewCell>(cellType: T.Type) -> T? {
        if let cell = self.dequeueReusableCell(withIdentifier: String.init(describing: cellType)) as? T {
            cell.selectionStyle = .none
            return cell
        } else {
            self.register(UINib(nibName: String.init(describing: cellType), bundle: nil), forCellReuseIdentifier: String.init(describing: cellType))

            if let cell = self.dequeueReusableCell(withIdentifier: String.init(describing: cellType)) as? T {
                cell.selectionStyle = .none
                return cell
            }
        }
        return nil
    }

    public func addRefresher(target: Any, action: Selector) {
        let refresher = UIRefreshControl()
        refresher.addTarget(target, action: action, for: .valueChanged)
        self.addSubview(refresher)
        self.refreshControl = refresher
    }

    public func changeToAutoCellHeightMode() {
        self.estimatedRowHeight = 44
        self.rowHeight = UITableView.automaticDimension
    }

    public func changeToAutoHeaderHeightMode() {
        self.sectionHeaderHeight = UITableView.automaticDimension;
        self.estimatedSectionHeaderHeight = 25;
    }
}

extension String {
    public var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }

    public var isAlphabet: Bool {
        return !isEmpty && range(of: "[^a-zA-Z]", options: .regularExpression) == nil
    }

    public func substring(from: Int, to: Int) -> String {
        let start = index(startIndex, offsetBy: from)
        let end = index(start, offsetBy: to - from)
        return String(self[start ..< end])
    }
}

extension UIButton {
    public func setImgIcon(iconName: String, color: UIColor? = nil) {
        self.setImage(UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.tintColor = color
    }
}

extension UITextField {
    public func checkIsEmpty() -> Bool {
        if self.text?.isEmpty ?? true {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
                self.becomeFirstResponder()
            })
            return true
        } else {
            return false
        }
    }
}

extension UserDefaults {
    public static var app: UserDefaults {
        return UserDefaults.init(suiteName: Bundle.main.bundleIdentifier) ?? UserDefaults.standard
    }

    public func getData<T>(type: T.Type, key: String) -> T? {
        let value = self.object(forKey: key)
        return value as? T
    }

    public func setData(_ data: Any?, key: String) {
        self.setValue(data, forKey: key)
        self.synchronize()
    }

//    #keyPath(subscribeTopics)
}

extension UIImage {
    public func maskWithColor(color: UIColor?) -> UIImage? {
        guard let color = color else {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.setFill()

        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)

        let rect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
        context?.clip(to: rect, mask: self.cgImage!)
        context?.fill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let resultImage = newImage {
            return resultImage
        } else {
            return nil
        }
    }

    public func colored(_ color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            self.draw(at: .zero)
            context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height), blendMode: .sourceAtop)
        }
    }

    public func crop(withlimitWidth width: CGFloat) -> UIImage? {
        if width <= 0 {
            return nil
        }

        var newHeight: CGFloat = 0
        var newWidth: CGFloat = 0
        if self.size.width > self.size.height {
            newWidth = width
            newHeight = newWidth * self.size.height / self.size.width
        } else {
            newHeight = width
            newWidth = newHeight * self.size.width / self.size.height
        }

        UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 1)
        self.draw(in: CGRect.init(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

extension UIColor {
    /// hex: "#FFFFFF" or "000000"
    public static func initWithHexString(hex:String) -> UIColor? {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if (cString.count) != 6 {
            return nil
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    public static func initWithRgbValue(rgb rgbValue: UInt64, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

extension UINavigationController {
    public func pop2Page() {
        self.popPages(page: 2)
    }

    public func popPages(page: Int) {
        let vcs = self.viewControllers
        if vcs.count >= (page + 1) {
            let vc = self.viewControllers[vcs.count - page - 1]
            self.popToViewController(vc, animated: true)
        }
    }

    public func popToType<T: UIViewController>(type: T.Type) {
        if let vc = self.viewControllers.last(where: { $0 is T }) {
            self.popToViewController(vc, animated: true)
        }
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension DispatchQueue {
    static func runInMain(_ closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async {
                closure()
            }
        }
    }
}

extension Data {
    public var desc: String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
}

extension Decimal {
    public func toString(minDigits: Int = 0, maxDigits: Int = 2) -> String? {
        let formatter = NumberFormatter()
        formatter.generatesDecimalNumbers = true
        formatter.minimumFractionDigits = minDigits
        formatter.maximumFractionDigits = maxDigits
        return formatter.string(from: self as NSDecimalNumber)
    }
}
