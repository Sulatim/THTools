//
//  THTools+Notify.swift
//  THTools
//
//  Created by Tim Ho on 2021/10/16.
//

import UIKit

#if THNOTIFY
public struct THNotifyConfig {
    public static let notificationLog = THLogger.init(name: "THNotify", showLog: false)
    public static var registerOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
}

extension THTools {
    public struct Notification {
        public static func registerRemoteNotification() {
            let authOptions: UNAuthorizationOptions = THNotifyConfig.registerOptions
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { success, error in
                    print(success)
                    THNotifyConfig.notificationLog.log("register result: \(success)")
                    if let err = error {
                        THNotifyConfig.notificationLog.log("register error: \(err.localizedDescription)")
                    }
            })
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
#endif
