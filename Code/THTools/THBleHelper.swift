import UIKit
import CoreBluetooth

public protocol THBleHelperDelegate: AnyObject {
    func bleNeedToRequestAuth()
    func bleCancelRequestAuth()
    func bleStartScanWithError(state: CBManagerState)
    func bleInitialOK()
    func bleNeedOpenBle()
    func bleCloseOpenBleAlert()

    func bleUpdateScannedPeripherals(peripherals: [CBPeripheral])
    func bleConnectedPeripheralSearchServices(peripheral: CBPeripheral) -> [CBUUID]?
    func bleDisconnectPeripheralNeedReconnect(peripheral: CBPeripheral) -> Bool
    func bleDiscoverServicesFindCharacteristics(peripheral: CBPeripheral) -> [(service: CBService, characteristics: [CBUUID]?)]
    func bleFindCharInService(peripheral: CBPeripheral, service: CBService)
    func bleCharacterUpdateValue(peripheral: CBPeripheral, character: CBCharacteristic, data: Data?)

    func bleChangeToDisconnected()
}

public extension CBManagerState {
    var scanOpenFailMsg: String {
        switch self {
        case .unknown: return "不明的狀態"
        case .resetting: return "藍芽重置中，請稍候"
        case .unsupported: return "此裝置不支援藍芽"
        case .unauthorized: return "需要開始藍芽授權"
        case .poweredOff: return "請先開啟藍芽"
        case .poweredOn: return "開啟中"
        @unknown default: return "不明的錯誤"
        }
    }
}

public extension THBleHelperDelegate {
    func bleInitialOK() { }
    func bleCancelRequestAuth() { }
    func bleCloseOpenBleAlert() { }
}

public extension THBleHelperDelegate where Self: UIViewController {

    func bleNeedToRequestAuth() {
        let alert = UIAlertController(
            title: nil,
            message: "需要藍芽權限來進行偵測",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "去設定開啟", style: .cancel, handler: { (alert) -> Void in
            THTools.openAppSettingPage()
        }))

        alert.addAction(UIAlertAction(title: "取消", style: .default, handler: { _ in
            self.bleCancelRequestAuth()
        }))
        present(alert, animated: true, completion: nil)
    }

    func bleNeedOpenBle() {
        let alert = UIAlertController(
            title: nil,
            message: "藍芽已關閉，請先開啟藍芽",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: { _ in
            self.bleCloseOpenBleAlert()
        }))
        present(alert, animated: true, completion: nil)
    }
}

public class THBleHelper: NSObject {

    public readyToWork: Bool {
        return initialOK
    }
    var initialOK: Bool = false
    public var isScanning: Bool {
        return self.centralManager?.isScanning ?? false
    }

    var centralManager: CBCentralManager?
    var peripheralHeartRateMonitor: CBPeripheral?

    var peripherals: [CBPeripheral] = []
    public weak var delegate: THBleHelperDelegate?

    public var detectServices: [CBUUID]?
    let peripheralLocker = NSLock()

    public var targetPeripherals: [CBPeripheral] {
        return _targetPeripherals
    }
    var _targetPeripherals: [CBPeripheral] = []
    let targetPeripheralLocker = NSLock()

    var connectedPers: [CBPeripheral] = []
    let connectedLocker = NSLock()

    var initialAutoScan = false

    public init(withAutoScan autoScan: Bool = true, detectServices: [CBUUID]? = nil) {
        super.init()

        self.clear()
        self.initialAutoScan = autoScan
        self.detectServices = detectServices
        self.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
    }

    public func startInitBlueTooth() {
        guard let manager = self.centralManager else {
            self.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
            return
        }

        switch manager.state {
        case .unauthorized:
            self.delegate?.bleNeedToRequestAuth()
        case .poweredOff:
            self.delegate?.bleNeedOpenBle()
        case .unknown, .resetting, .unsupported:
            self.delegate?.bleStartScanWithError(state: manager.state)
        default:
            break
        }
    }

    public func startScan() {
        if self.initialOK == false {
            if self.centralManager?.state == .poweredOn {
                THTools.Logger.bleHelper.log("Auto change to initial OK")
                self.initialOK = true
            } else {
                THTools.Logger.bleHelper.log("Start scan fail, not initial")
                if self.centralManager != nil {
                    self.startInitBlueTooth()
                }
                return
            }
        }

        THTools.Logger.bleHelper.log("Call Start Scan")
        self.centralManager?.scanForPeripherals(withServices: self.detectServices, options: nil)
    }

    public func stopSacn() {
        if self.initialOK == false {
            THTools.Logger.bleHelper.log("Stop scan fail, not initial")
            return
        }

        THTools.Logger.bleHelper.log("Call Stop Scan")
        self.centralManager?.stopScan()
    }

    public func connectTo(peripheral: CBPeripheral) {
        if self.initialOK == false {
            THTools.Logger.bleHelper.log("Connect peripheral fail, not initial")
            return
        }

        targetPeripheralLocker.lock()
        if _targetPeripherals.contains(peripheral) == false {
            _targetPeripherals.append(peripheral)
        }
        targetPeripheralLocker.unlock()

        THTools.Logger.bleHelper.log("Connect to \(peripheral.logInfo)")
        centralManager?.connect(peripheral, options: nil)
    }

    public func disconnectTo(peripheral: CBPeripheral) {
        self.centralManager?.cancelPeripheralConnection(peripheral)
        peripheral.delegate = nil

        if self.initialOK == false {
            THTools.Logger.bleHelper.log("Disconnect peripheral fail, not initial")
            return
        }

        targetPeripheralLocker.lock()
        if let idx = self._targetPeripherals.firstIndex(of: peripheral) {
            self._targetPeripherals.remove(at: idx)
        }
        targetPeripheralLocker.unlock()
        THTools.Logger.bleHelper.log("Disconnect to \(peripheral.logInfo)")
    }

    func clear() {
        for item in self.peripherals {
            item.delegate = nil
        }

        self.peripheralLocker.lock()
        self.peripherals.removeAll()
        self.peripheralLocker.unlock()

        self.connectedLocker.lock()
        if let manager = self.centralManager {
            for item in self.connectedPers {
                item.delegate = nil
                manager.cancelPeripheralConnection(item)
            }
            manager.delegate = nil
        }
        self.connectedPers.removeAll()
        self.connectedLocker.unlock()

        self.targetPeripheralLocker.lock()
        self._targetPeripherals.removeAll()
        self.targetPeripheralLocker.unlock()
        self.centralManager = nil
        self.initialOK = false
    }

    public func disconnect() {
        self.clear()
        self.delegate?.bleChangeToDisconnected()
    }

    deinit {
        self.clear()
    }
}

extension CBPeripheral {
    var logInfo: String {
        return "\(self.name ?? "--") id:\(self.identifier.uuidString)"
    }
}

extension THBleHelper: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        THTools.Logger.bleHelper.log("Update Ble State: \(central.state)")

        switch central.state {
        case .unauthorized:
            self.delegate?.bleNeedToRequestAuth()
        case .poweredOff:
            self.delegate?.bleNeedOpenBle()
        case .unknown, .resetting, .unsupported:
            if self.initialOK == false {
                self.delegate?.bleStartScanWithError(state: central.state)
            } else {
                // TODO: 應該是切成斷線之類的
                self.delegate?.bleChangeToDisconnected()
            }
        case .poweredOn:
            if self.initialOK == false {
                self.delegate?.bleInitialOK()
                self.initialOK = true
                if self.initialAutoScan {
                    self.startScan()
                }
            } else { // 就幫他重連吧
                self.targetPeripheralLocker.lock()
                for per in self.targetPeripherals {
                    self.centralManager?.connect(per, options: nil)
                }
                self.targetPeripheralLocker.unlock()
            } //掃描中好像沒啥差別
        @unknown default:
            break
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        peripheralLocker.lock()
        if self.peripherals.contains(peripheral) {
            peripheralLocker.unlock()
            return
        }
        self.peripherals.append(peripheral)
        peripheralLocker.unlock()
        self.delegate?.bleUpdateScannedPeripherals(peripherals: self.peripherals)
        THTools.Logger.bleHelper.log("Scan New Device: \(peripheral.logInfo) rssi: \(RSSI)")
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {

        self.connectedLocker.lock()
        if self.connectedPers.contains(peripheral) == false {
            self.connectedPers.append(peripheral)
        }
        self.connectedLocker.unlock()

        THTools.Logger.bleHelper.log("Connected to \(peripheral.logInfo)")

        peripheral.delegate = self
        let targetServices = self.delegate?.bleConnectedPeripheralSearchServices(peripheral: peripheral)
        peripheral.discoverServices(targetServices)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {

        THTools.Logger.bleHelper.log("Disconnected to \(peripheral.logInfo)")

        peripheral.delegate = nil
        self.connectedLocker.lock()
        if let idx = self.connectedPers.firstIndex(of: peripheral) {
            self.connectedPers.remove(at: idx)
        }
        self.connectedLocker.unlock()

        if self.delegate?.bleDisconnectPeripheralNeedReconnect(peripheral: peripheral) ?? false {
            if self.initialOK {
                self.centralManager?.connect(peripheral, options: nil)
            }
        }
    }
}

extension THBleHelper: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let err = error {
            THTools.Logger.bleHelper.log("Discover \(peripheral.logInfo) services with error: \(err.localizedDescription)")
            return
        }
        THTools.Logger.bleHelper.log("== Discover \(peripheral.logInfo) services ==")
        if let aryServices = peripheral.services {
            for service in aryServices {
                THTools.Logger.bleHelper.log("\(service)")
            }
        }
        THTools.Logger.bleHelper.log("========= end \(peripheral.logInfo) =========")
        if let aryTarget = self.delegate?.bleDiscoverServicesFindCharacteristics(peripheral: peripheral) {
            for item in aryTarget {
                peripheral.discoverCharacteristics(item.characteristics, for: item.service)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        THTools.Logger.bleHelper.log("== Discover \(peripheral.logInfo) chars ==")
        if let aryChars = service.characteristics {
            for character in aryChars {
                THTools.Logger.bleHelper.log("\(character)")
            }
        }
        THTools.Logger.bleHelper.log("======= end \(peripheral.logInfo) ========")
        self.delegate?.bleFindCharInService(peripheral: peripheral, service: service)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            THTools.Logger.bleHelper.log("Character update value error: \(err.localizedDescription) \(peripheral.logInfo)")
            return
        }
        self.delegate?.bleCharacterUpdateValue(peripheral: peripheral, character: characteristic, data: characteristic.value)
    }
}

