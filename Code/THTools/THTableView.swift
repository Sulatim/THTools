//
//  THTableView.swift
//  HCParking
//
//  Created by Tim Ho on 2023/8/3.
//

import UIKit

// MARK: THCellVm
public struct THTableViewSetting {
    public struct Height {
        public static let autoHeight = UITableView.automaticDimension
        public static let calculateHeight: CGFloat = -1001
    }
}

public protocol THCellVmProtocol: AnyObject {
    var cellType: UITableViewCell.Type? { get }
    var cellHeight: CGFloat { get }
    var storyboardId: String? { get set }
    
    func generateCell(tableView: UITableView, additionInfo: (indexPath: IndexPath, id: String)?) -> UITableViewCell
}

public extension THCellVmProtocol {
    var storyboardId: String? {
        get { return nil }
        set { }
    }
    
    func generateCell(tableView: UITableView, additionInfo: (indexPath: IndexPath, id: String)? = nil) -> UITableViewCell {
        if let info = additionInfo {
            let cell = tableView.dequeueReusableCell(withIdentifier: info.id, for: info.indexPath)
            cell.selectionStyle = .none
            
            return cell
        } else if let tp = cellType, let cls = NSClassFromString(NSStringFromClass(tp)), let cell = tableView.dequeueReusableCell(Type: cls) {
            cell.selectionStyle = .none
            return cell
        }
        
        return .makeEmptyCell()
    }
}

public protocol THCellProtocol: UITableViewCell {
    func setup(cellVm: THCellVmProtocol)
    func reloadCellByVmChange()
    
    var cellVm: THCellVmProtocol? { get }
}

public extension THCellProtocol {
    var cellVm: THCellVmProtocol? {
        get { return nil }
        set { }
    }
    
    func reloadCellByVmChange() {
        guard let vm = self.cellVm else {
            return
        }
        
        THTools.runInMainThread { [weak self] in
            self?.setup(cellVm: vm)
        }
    }
}

public extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>(Type cellType: AnyClass) -> T? {
        
        let key = cellType.description()
        var cell = self.dequeueReusableCell(withIdentifier: key)
        
        if cell == nil {
            let nibName = String(key.split(separator: ".").last ?? "")
            
            if let nibPath = Bundle.init(for: cellType.self).path(forResource: nibName, ofType: "nib") {
                let nib = UINib.init(nibName: String(key.split(separator: ".").last ?? ""), bundle: Bundle.init(for: cellType.self))
                self.register(nib, forCellReuseIdentifier: key)
            } else {
                // 沒Nib
                self.register(cellType.self, forCellReuseIdentifier: key)
            }
            
            cell = self.dequeueReusableCell(withIdentifier: key)
        }
        cell?.selectionStyle = .none
        
        return cell as? T
    }
}

// MARK: Section
public protocol THSectionVmProtocol {
    var cellVmArray: [THCellVmProtocol] { get set }
    var displayCellVmArray: [THCellVmProtocol] { get set }
    
    var header: THSectionHeaderFooterVmProtocol? { get set }
    var footer: THSectionHeaderFooterVmProtocol? { get set }
    
    var headerHeight: CGFloat { get }
    var footerHeight: CGFloat { get }
}

public extension THSectionVmProtocol {
    var displayCellVmArray: [THCellVmProtocol] {
        get { cellVmArray }
        set { cellVmArray = newValue }
    }
    
    var header: THSectionHeaderFooterVmProtocol? {
        get { nil }
        set { }
    }
    
    var footer: THSectionHeaderFooterVmProtocol? {
        get { nil }
        set { }
    }
    
    var headerHeight: CGFloat {
        return self.header?.height ?? CGFloat.leastNormalMagnitude
    }
    
    var footerHeight: CGFloat {
        return self.footer?.height ?? CGFloat.leastNormalMagnitude
    }
}

// MARK: Section Header/Footer
public protocol THSectionHeaderFooterVmProtocol {
    var view: UIView? { get }
    var height: CGFloat { get }
}

public extension THSectionHeaderFooterVmProtocol {
    var height: CGFloat {
        return self.view?.frame.height ?? 0
    }
}

// MARK: Section owner
public protocol THSectionVmArrayOwner {
    var sectionVmArray: [THSectionVmProtocol] { get }
    
    func sectionVmArrayOwnerGetSectionsCount() -> Int
    func sectionVmArrayOwnerGetCellCount(inSection section: Int ) -> Int
    
    func sectionVmArrayOwnerGetSectionVm(at idx: Int) -> THSectionVmProtocol?
    func sectionVmArrayOwnerGetCellVm(at index: IndexPath) -> THCellVmProtocol?
    func sectionVmArrayOwnerGetCell(inTableview tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    
    func sectionVmArrayOwnerGetCellHeight(at indexPath: IndexPath) -> CGFloat
    func sectionVmArrayOwnerHandleUnknowCellHeight() -> CGFloat
    func sectionVmArrayOwnerCalculateCellHeight(at indexPath: IndexPath, cellVm: THCellVmProtocol) -> CGFloat
}

public extension THSectionVmArrayOwner {
    func sectionVmArrayOwnerHandleUnknowCellHeight() -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func sectionVmArrayOwnerCalculateCellHeight(at indexPath: IndexPath, cellVm: THCellVmProtocol) -> CGFloat {
        return THTableViewSetting.Height.autoHeight
    }
    
    func sectionVmArrayOwnerGetSectionVm(at idx: Int) -> THSectionVmProtocol? {
        return self.sectionVmArray[safe: idx]
    }
    
    func sectionVmArrayOwnerGetCellVm(at index: IndexPath) -> THCellVmProtocol? {
        guard let secInfo = sectionVmArrayOwnerGetSectionVm(at: index.section) else {
            return nil
        }
        
        return secInfo.displayCellVmArray[safe: index.row]
    }
    
    func sectionVmArrayOwnerGetSectionsCount() -> Int {
        return self.sectionVmArray.count
    }
    
    func sectionVmArrayOwnerGetCellCount(inSection section: Int ) -> Int {
        return sectionVmArrayOwnerGetSectionVm(at: section)?.displayCellVmArray.count ?? 0
    }
    
    func sectionVmArrayOwnerGetCell(inTableview tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellVm = sectionVmArrayOwnerGetCellVm(at: indexPath) else {
            return .makeEmptyCell()
        }
        
        var info: (IndexPath, String)?
        if let reuseId = cellVm.storyboardId {
            info = (indexPath, reuseId)
        }
        
        let cell = cellVm.generateCell(tableView: tableView, additionInfo: info)
        
        if let cell = cell as? THCellProtocol {
            cell.setup(cellVm: cellVm)
        }
        
        return cell
    }
    
    func sectionVmArrayOwnerGetCellHeight(at indexPath: IndexPath) -> CGFloat {
        guard let info = self.sectionVmArrayOwnerGetCellVm(at: indexPath) else {
            return self.sectionVmArrayOwnerHandleUnknowCellHeight()
        }
        
        let height = info.cellHeight
        if height == THTableViewSetting.Height.calculateHeight {
            return self.sectionVmArrayOwnerCalculateCellHeight(at: indexPath, cellVm: info)
        }
        
        return height
    }
}

public class THBasicSectionVm: THSectionVmProtocol {
    public var cellVmArray: [THCellVmProtocol] = []
    
    public init() {}
    
    public init(_ cellVm: THCellVmProtocol) {
        cellVmArray = [cellVm]
    }
    
    public init(_ cellVms: [THCellVmProtocol]) {
        cellVmArray = cellVms
    }
}

public class THSpaceCellVm: THCellVmProtocol {
    public var cellType: UITableViewCell.Type?
    
    public var cellHeight: CGFloat
    private var bgColor: UIColor?
    
    public init(height: CGFloat, bgColor: UIColor? = nil) {
        self.cellHeight = height
        self.bgColor = bgColor
    }
    
    func generateCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.makeEmptyCell()
        cell.backgroundColor = self.bgColor
        
        return cell
    }
    
    func release() { }
}
