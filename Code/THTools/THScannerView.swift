
import UIKit
import AVFoundation

public protocol THScannerViewDelegate: AnyObject {
    func scannerSouldKeepScanWhenDetectBarcode(_ barcode: String) -> Bool
    func scannerNeedToRequestAuth()
    func scannerCancelRequestAuth()
}

public extension THScannerViewDelegate {
    func scannerCancelRequestAuth() { }
}

public extension THScannerViewDelegate where Self: UIViewController {
    func scannerNeedToRequestAuth() {
        let alert = UIAlertController(
            title: nil,
            message: "需要相機權限來進行掃描",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "去設定開啟", style: .cancel, handler: { (alert) -> Void in
            THTools.openAppSettingPage()
        }))

        alert.addAction(UIAlertAction(title: "取消", style: .default, handler: { (alert) -> Void in
            self.scannerCancelRequestAuth()
        }))

        present(alert, animated: true, completion: nil)
    }
}

public class THScannerView: UIView {

    public weak var delegate: THScannerViewDelegate?

    var bAnimationDown = false
    var fScanerWidth: CGFloat = 0

    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureMetadataOutput?
    var session: AVCaptureSession?
    var preview: AVCaptureVideoPreviewLayer?

    var vDetect = UIView.init()
    private var lastErrorBarcode: String?

    public var detectBarcodeTypes: [AVMetadataObject.ObjectType] = [.qr]

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.afterInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.afterInit()
    }

    func afterInit() {
        bAnimationDown = true
        fScanerWidth = 4

        self.backgroundColor = UIColor.clear

//        var fWidth = self.frame.size.width * 0.9

        NotificationCenter.default.addObserver(self, selector: #selector(orientationChange(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)

        self.addSubview(self.vDetect)
        self.vDetect.backgroundColor = UIColor.clear
        self.vDetect.layer.borderColor = UIColor.blue.cgColor
        self.vDetect.layer.borderWidth = 1
    }

    @objc func orientationChange(notification: NSNotification) {

        self.preview?.connection?.videoOrientation = .portrait
        return
    }

    public func start() {
        self.vDetect.frame = CGRect.zero
        if THTools.Environment.isSimulator {
            self.backgroundColor = UIColor.black
            return
        }

        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            self.backgroundColor = UIColor.clear

            THTools.runInMainThread {
                let _ = self.setupCamera()
            }

        } else {
            self.backgroundColor = UIColor.black
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) -> Void in
                if granted == true {
                    THTools.runInMainThread {
                        let _ = self.setupCamera()
                    }
                } else {
                    self.delegate?.scannerNeedToRequestAuth()
                }
            })
        }
    }

    public func stop() {
        self.session?.stopRunning()
    }

    func clearPreview() {
        self.vDetect.isHidden = true
        self.preview?.removeFromSuperlayer()
    }

    func setupCamera() -> Bool {
        if self.session?.isRunning == true {
            return false
        }

        self.vDetect.isHidden = false
        self.device = AVCaptureDevice.default(for: AVMediaType.video)
        self.input = try! AVCaptureDeviceInput.init(device: self.device!)
        self.output = AVCaptureMetadataOutput.init()
        self.output?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

        session = AVCaptureSession.init()
        session?.sessionPreset = .high
        if session?.canAddInput(input!) ?? false {
            session?.addInput(input!)
        } else {
            return false
        }

        if session?.canAddOutput(output!) ?? false {
            session?.addOutput(output!)
        } else {
            return false
        }

        self.output?.metadataObjectTypes = self.detectBarcodeTypes

        self.preview = AVCaptureVideoPreviewLayer.init(session: self.session!)
        self.preview?.videoGravity = .resizeAspectFill
//        preview?.transform = CATransform3DMakeRotation(CGFloat(Double.pi / 2), 0, 0, 1)
        preview?.connection?.videoOrientation = .portrait
        preview?.frame = self.bounds

        self.layer.addSublayer(self.preview!)
        self.session?.startRunning()

        return true
    }

    var lastScanInfo: scanInfo?
}

typealias scanInfo = (Date, String)

extension THScannerView: AVCaptureMetadataOutputObjectsDelegate {

    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        var detectionString = ""
        for metadata in metadataObjects {
            if self.detectBarcodeTypes.contains(metadata.type) == false {
                continue
            }

            guard let barCodeObj = preview?.transformedMetadataObject(for: metadata) as? AVMetadataMachineReadableCodeObject else {
                continue
            }

            detectionString = barCodeObj.stringValue ?? ""

            if let info = self.lastScanInfo {
                let interval = Date().timeIntervalSince(info.0)

                if detectionString == info.1 && interval < 1 {
                    return
                }
            }

            if barCodeObj.bounds.maxY < 0 || barCodeObj.bounds.maxX < 0 || barCodeObj.bounds.minX > self.bounds.width || barCodeObj.bounds.minY > self.bounds.height {
                if let last = lastErrorBarcode, last == detectionString {
                    continue
                }
                lastErrorBarcode = detectionString
                THTools.Logger.scanner.log("skip scan, out of bounds \(barCodeObj.bounds)")
                continue
            }

            THTools.Logger.scanner.log("Detect: \(detectionString), Type: \(metadata.type)")
            lastErrorBarcode = nil

            self.lastScanInfo = (Date(), detectionString)
            self.vDetect.frame = barCodeObj.bounds
            self.bringSubviewToFront(self.vDetect)
            THTools.Logger.scanner.log("\(barCodeObj.bounds)")

            if self.delegate?.scannerSouldKeepScanWhenDetectBarcode(detectionString) == false {
                self.stop()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.vDetect.frame = CGRect.zero
                }
            }

            return
        }
    }

}
