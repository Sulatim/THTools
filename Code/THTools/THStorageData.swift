import Foundation

public class THStorageData<T> {
    let saveKey: String

    public init(_ key: String) {
        self.saveKey = key
    }

    private var _value: T?
    public var value: T? {
        get {
            if _value == nil {
                _value = (UserDefaults.app.value(forKey: self.saveKey) as? T)
            }

            return _value
        }
        set {
            _value = newValue
            UserDefaults.app.setValue(newValue, forKey: self.saveKey)
        }
    }
}

public class THStorageNotNullData<T> {
    let saveKey: String
    let defaultValue: T

    public init(_ key: String, def: T) {
        self.saveKey = key
        self.defaultValue = def
    }

    private var _value: T?
    public var value: T {
        get {
            if _value == nil {
                _value = (UserDefaults.app.value(forKey: self.saveKey) as? T)
            }

            return _value ?? self.defaultValue
        }
        set {
            _value = newValue
            UserDefaults.app.setValue(newValue, forKey: self.saveKey)
        }
    }
}

public class THStorageParseData<T: Codable> {
    let saveKey: String

    public init(_ key: String) {
        self.saveKey = key
    }

    private var alreadyLoad = false
    private var _value: T?
    public var value: T? {
        get {
            if alreadyLoad {
                return _value
            }

            if let data = UserDefaults.app.data(forKey: self.saveKey) {
                let decoder = JSONDecoder()
                if let obj = try? decoder.decode(T.self, from: data) {
                    _value = obj
                }
            }
            self.alreadyLoad = true
            return _value
        }
        set {
            _value = newValue
            self.alreadyLoad = true

            var saveData: Data?
            if let tmp = newValue {
                let encoder = JSONEncoder()
                saveData = try? encoder.encode(tmp)
            }

            UserDefaults.app.setValue(saveData, forKey: self.saveKey)
        }
    }
}
