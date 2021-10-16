//
//  THPopViewBase.swift
//  SunnyBank
//
//  Created by Tim Ho on 2021/10/16.
//

import UIKit

public class THPopViewBase: THNibViewBase {

    private let wdMain = UIWindow()

    init() {
        super.init(frame: UIScreen.main.bounds)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    final func displayPopViewWithAnimation(duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.wdMain.isHidden = false
            self.wdMain.backgroundColor = UIColor.clear

            self.wdMain.addSubview(self)
            self.alpha = 0
            self.wdMain.makeKeyAndVisible()

            if duration <= 0 {
                self.alpha = 1
                completion?()
                return
            }

            UIView.animate(withDuration: duration) {
                UIView.animate(withDuration: 0.3, animations: {
                    self.alpha = 1
                }, completion: { _ in
                    completion?()
                })
            }
        }
    }

    open func dismissed() {

    }

    final func dismiss(duration: TimeInterval = 0.3, complte: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            if duration <= 0 {
                self.alpha = 0
                self.wdMain.isHidden = true
                self.dismissed()
                return
            }

            UIView.animate(withDuration: 0.3) {
                self.alpha = 0
            } completion: { _ in
                self.wdMain.isHidden = true

                DispatchQueue.main.async {
                    complte?()
                    self.dismissed()
                }
            }
        }
    }
}
