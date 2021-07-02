//
//  THSaveData.swift
//  THTools
//
//  Created by CHX 何 on 2021/7/2.
//

import Foundation

public class THSaveData<T> {
    private var defaultValue: T
    let saveKey: String

    init(key: String, defValue: T) {
        self.saveKey = key
        self.defaultValue = defValue
    }

    private var _value: T?
    public var value: T {
        get {
            if _value == nil {
                _value = (UserDefaults.app.value(forKey: self.saveKey) as? T) ?? self.defaultValue
            }

            return _value ?? self.defaultValue
        }
        set {
            _value = newValue
            UserDefaults.app.setValue(newValue, forKey: self.saveKey)
        }
    }
}
