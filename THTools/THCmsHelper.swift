
import UIKit

class THCmsHelper: NSObject {
    private static var languageDictionary: [String: [String: String]] = [:]
    
    private static let _shared = THCmsHelper()
    static var shared: THCmsHelper {
        return _shared
    }
    
    enum SupportLanguage: String {
        case en
        case cn
    }
    
    var nowType = SupportLanguage.en
    
    func getText(key: String?) -> String {
        guard let rKey = key else {
            return ""
        }
        
        guard let dicInfo = THCmsHelper.languageDictionary[nowType.rawValue] else {
            return rKey
        }
        
        return dicInfo[rKey] ?? rKey
    }
}

extension String {
    public var languageText: String {
        return THCmsHelper.shared.getText(key: self)
    }
}
