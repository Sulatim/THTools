import Foundation

@propertyWrapper
public struct THStorageData<T> {
    private let key: String
    private var storedValue: T?

    public init(key: String) {
        self.storedValue = UserDefaults.standard.value(forKey: key) as? T
        self.key = key
    }

    public var wrappedValue: T? {
        get {
            storedValue
        }
        set {
            storedValue = newValue
            UserDefaults.standard.setValue(newValue, forKey: key)
        }
    }
}

@propertyWrapper
public struct THNotNullStorageData<T> {
    private let key: String
    private let defaultValue: T
    private var storedValue: T

    public init(key: String, def: T) {
        self.key = key
        self.defaultValue = def
        
        self.storedValue = (UserDefaults.standard.value(forKey: key) as? T) ?? def
    }

    public var wrappedValue: T {
        get {
            storedValue
        }
        set {
            storedValue = newValue
            UserDefaults.standard.setValue(newValue, forKey: key)
        }
    }
}


@propertyWrapper
public struct THCodableStorageData<T: Codable> {
    private let key: String
    private var storedValue: T?

    public init(key: String) {
        self.key = key
        
        if let data = UserDefaults.standard.data(forKey: self.key) {
            let decoder = JSONDecoder()
            if let obj = try? decoder.decode(T.self, from: data) {
                storedValue = obj
            }
        }
    }

    public var wrappedValue: T? {
        get {
            storedValue
        }
        set {
            storedValue = newValue
            
            var saveData: Data?
            if let tmp = newValue {
                let encoder = JSONEncoder()
                saveData = try? encoder.encode(tmp)
                print(saveData?.count)
            }
            
            UserDefaults.standard.setData(saveData, key: key)
            UserDefaults.standard.synchronize()
        }
    }
}
