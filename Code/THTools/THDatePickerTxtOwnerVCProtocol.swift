//
//  THDatePickerTxtOwnerVCProtocol.swift
//  THTools
//
//  Created by Tim Ho on 2022/1/16.
//

import Foundation

@objc public protocol THDatePickerTxtOwnerVCProtocol: UIViewController, UITextFieldDelegate {
    var aryPickerTxt: [UITextField?] { get set }
    var fmt: DateFormatter { get set }
    var datePicker: UIDatePicker { get set }
    
    func datePickerOwnerInitTxtArray()
    func datePickerOwnerInitPicker(sel: Selector)
    func datePickerOwnerHandleTxtShouldBeginEdit(txt: UITextField)
    func datePickerOwnerChangePicker()
}

public extension THDatePickerTxtOwnerVCProtocol {
    func datePickerOwnerInitPicker(sel: Selector) {
        self.datePickerOwnerInitTxtArray()
        self.fmt.dateFormat = "yyyy/MM/dd"
        
        self.datePicker.date = Date()
        self.datePicker.locale = Locale(identifier: "zh_TW")
        self.aryPickerTxt.forEach { txt in
            txt?.delegate = self
            txt?.inputView = self.datePicker
        }
        self.datePicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            self.datePicker.preferredDatePickerStyle = .wheels
        }
        self.datePicker.addTarget(self, action: sel, for: .valueChanged)
    }
    
    func datePickerOwnerChangePicker() {
        if let txt = self.aryPickerTxt.first(where: { $0?.isFirstResponder == true }) {
            txt?.text = self.fmt.string(from: self.datePicker.date)
        }
    }
    
    func datePickerOwnerHandleTxtShouldBeginEdit(txt: UITextField) {
        guard aryPickerTxt.contains(where: { $0 == txt }) else {
            return
        }
        
        if let datInput = self.fmt.date(from: txt.text ?? "") {
            self.datePicker.date = datInput
        } else {
            self.datePicker.date = Date()
            txt.text = self.fmt.string(from: self.datePicker.date)
        }
    }
}
