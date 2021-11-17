//
//  THTools+Notify.swift
//  THTools
//
//  Created by Tim Ho on 2021/10/16.
//

import UIKit

#if THNOTIFY
public protocol THNotifyDelegate: AnyObject {
    func receiveNotify(fromLaunch: Bool, notification: [AnyHashable: Any])
}

public struct THNotifyConfig {
    public static let notificationLog = THLogger.init(name: "THNotify", showLog: false)
    public static var registerOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    public static weak var delegate: THNotifyDelegate?
}

extension THTools {
    public struct Notification {
        public static func registerRemoteNotification(delegate: UNUserNotificationCenterDelegate? = nil) {
            let authOptions: UNAuthorizationOptions = THNotifyConfig.registerOptions
            UNUserNotificationCenter.current().delegate = delegate
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

        private static func handleNotify(notification: [AnyHashable: Any]?, fromLaunch: Bool) {
            guard let info = notification else {
                return
            }

            if let data = try? JSONSerialization.data(withJSONObject: info, options: .fragmentsAllowed) {

                THNotifyConfig.notificationLog.log("receive notify\(fromLaunch ? " from launch": ""): \(String(data: data, encoding: .utf8) ?? "no data")")
            }

            THNotifyConfig.delegate?.receiveNotify(fromLaunch: true, notification: info)
        }

        public static func handleLaunchNotify(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
            self.handleNotify(notification: launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any], fromLaunch: true)
        }

        public static func handleReceiveNotificationResponse(center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) {

            self.handleNotify(notification: response.notification.request.content.userInfo, fromLaunch: false)
        }
    }
}
#endif
