
import UIKit

public struct THTools {
    public struct ToolConstants {
        public struct Logger {
            public static var on = false

            public static var nhPostBody = false
            public static var nhResponse = false

            public static var netHelper = true
            public static var scanner = true
            public static var notificaton = true
        }

        public static var netHelperDefaultDomain: String = ""
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

        private static func verifyRegex(str: String?, regex: String) -> Bool {
            guard let str = str else {
                return false
            }

            let pred = NSPredicate(format: "SELF MATCHES %@", regex)
            return pred.evaluate(with: str)
        }
    }
}

extension THTools {
    public struct Environment {
        public static var isSimulator: Bool {
            var result = false
            #if arch(i386) || arch(x86_64)
            result = true
            #endif

            return result
        }

        public static func getVersion() -> String {
            let bundle = Bundle.main
            let mainVer = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            let buildVer = bundle.infoDictionary?["CFBundleVersion"] as? String ?? ""

            var prefix = "V"
            #if DEBUG
            prefix = "D"
            #endif

            return "\(prefix)\(mainVer) (\(buildVer))"
        }

        public static func getDeviceID() -> String {
            if let deviceID = UserDefaults.app.string(forKey: "deviceID") {
                return deviceID
            }
            let strNew = UUID().uuidString
            UserDefaults.app.setValue(strNew, forKey: "deviceID")
            UserDefaults.app.synchronize()

            return strNew
        }

        public static func getOSVersion() -> String {
            return "\(UIDevice.current.systemVersion)"
        }
    }
}

extension THTools {
    public struct Notification {
        public static func registerRemoteNotification() {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { success, error in
                    print(success)
                    THLogger.notification.log("register result: \(success)")
                    if let err = error {
                        THLogger.notification.log("register error: \(err.localizedDescription)")
                    }
            })
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

extension THTools {
    public struct DateTime {
        public static var fmtFull: DateFormatter {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyyMMddHHmmss"
            return fmt
        }

        public static var fmtDate: DateFormatter {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyyMMdd"
            return fmt
        }

        public static func convertHHmmToMin(hhMM: String?) -> Int? {
            guard let start = hhMM else {
                return nil
            }

            let aryStart = start.split(separator: ":")

            guard aryStart.count == 2,
                  let nHS = Int(aryStart[0]), let nMS = Int(aryStart[1]) else {
                return nil
            }

            return nHS * 60 + nMS
        }

        public static func convertMinToHHmm(min: Int?) -> String? {
            guard let min = min else {
                return nil
            }

            if min >= 60 * 24 || min < 0 {
                return nil
            }

            return String.init(format: "%02d:%02d", min / 60, min % 60)
        }

        public static func convertFullDateStringToDate(_ str: String?) -> Date? {
            guard let str = str else {
                return nil
            }

            let fmt = self.fmtFull
            return fmt.date(from: str)
        }

        public static func convertDateToFullDateString(date: Date?) -> String? {
            guard let dat = date else {
                return nil
            }

            let fmt = self.fmtFull
            return fmt.string(from: dat)
        }

        public static func convertDateToMMddHHmm(date: Date?) -> String? {
            guard let dat = date else {
                return nil
            }

            let fmt = DateFormatter()
            fmt.dateFormat = "MM/dd HH:mm"
            return fmt.string(from: dat)
        }

        public static func getFirstDateOfMonth(dat: Date) -> Date {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyyMM"
            let strDate = fmt.string(from: dat) + "01"
            fmt.dateFormat = "yyyyMMdd"
            return fmt.date(from: strDate) ?? dat
        }

        public static func getLastTimeOfMonth(dat: Date) -> Date {
            let datNextMonth = addMonth(month: 1, from: dat)
            let datNextMonthFirst = getFirstDateOfMonth(dat: datNextMonth)
            return datNextMonthFirst.addingTimeInterval(-1)
        }

        public static func addMonth(month: Int, from: Date) -> Date {
            var datComponents = DateComponents()
            datComponents.setValue(month, for: Calendar.Component.month)
            let cal = Calendar.current
            let dat = cal.date(byAdding: datComponents, to: from) ?? from

            return dat
        }

        public static func getYearFirstDate(dat: Date = Date()) -> Date {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy"
            let str = fmt.string(from: dat) + "0101"
            fmt.dateFormat = "yyyyMMdd"
            return fmt.date(from: str) ?? dat
        }

        public static func getYearLastTime(dat: Date = Date()) -> Date {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy"
            let str = fmt.string(from: dat) + "1231235959"
            fmt.dateFormat = "yyyyMMddHHmmss"
            return fmt.date(from: str) ?? dat
        }

        public static func getDefaultBirthday(age: Int = 18) -> Date {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMdd"
            let strMMdd = fmt.string(from: Date())

            fmt.dateFormat = "yyyy"
            let strYear = fmt.string(from: Date())

            fmt.dateFormat = "yyyyMMdd"
            var datTarget = fmt.date(from: "\((Int.init(strYear) ?? 0) - age)\(strMMdd)")
            if datTarget == nil, strMMdd == "0229" {
                datTarget = fmt.date(from: "\((Int.init(strYear) ?? 0) - age)0228")
            }
            if datTarget == nil {
                datTarget = Date()
            }

            return datTarget ?? Date()
        }

        public static func getAgeFromBirthday(_ birthday: Date?) -> Int? {
            guard let birthday = birthday else {
                return nil
            }

            let ageComponents = Calendar.current.dateComponents([.year], from: birthday, to: Date())
            return ageComponents.year
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
        let vcs = self.viewControllers
        if vcs.count >= 3 {
            let vc = self.viewControllers[vcs.count - 3]
            self.popToViewController(vc, animated: true)
        }
    }
}
