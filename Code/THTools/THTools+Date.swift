//
//  THTools+Date.swift
//  THTools
//
//  Created by CHX 何 on 2021/6/25.
//

import Foundation

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

        public static var fmtMonth: DateFormatter {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyyMM"
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
            let strDate = self.fmtMonth.string(from: dat) + "01"
            return self.fmtDate.date(from: strDate) ?? dat
        }

        public static func getLastTimeOfMonth(dat: Date) -> Date {
            let datNextMonth = addMonth(month: 1, from: dat)
            let datNextMonthFirst = getFirstDateOfMonth(dat: datNextMonth)
            return datNextMonthFirst.addingTimeInterval(-1)
        }

        public static func getCalendarFirst(dat: Date, firstWeekDay: Int = 1) -> Date? {
            let datMonthFirst = self.getFirstDateOfMonth(dat: dat)
            var weekDay = Calendar.current.component(.weekday, from: datMonthFirst)
            if weekDay == firstWeekDay {
                return datMonthFirst
            } else if weekDay < firstWeekDay {
                weekDay = weekDay + 7
            }

            return datMonthFirst.addingTimeInterval(TimeInterval(60 * 60 * 24 * (firstWeekDay - weekDay)))
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
            return self.fmtDate.date(from: str) ?? dat
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

extension Date {
    public func addMonth(_ month: Int) -> Date {
        var dateComponent = DateComponents()
        dateComponent.month = month
        return Calendar.current.date(byAdding: dateComponent, to: self) ?? Date()
    }

    public func addDay(_ day: Int) -> Date {
        var dateComponent = DateComponents()
        dateComponent.day = day
        return Calendar.current.date(byAdding: dateComponent, to: self) ?? Date()
    }

    public func isSameMonth(with dat: Date) -> Bool {
        let fmt = THTools.DateTime.fmtMonth
        return fmt.string(from: dat) == fmt.string(from: self)
    }

    public func isSameDate(with dat: Date) -> Bool {
        let fmt = THTools.DateTime.fmtDate
        return fmt.string(from: dat) == fmt.string(from: self)
    }

    public func getDate() -> Date {
        let fmt = THTools.DateTime.fmtDate
        return fmt.date(from: fmt.string(from: self)) ?? self
    }
}
