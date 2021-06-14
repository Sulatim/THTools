
import UIKit
import AVFoundation

protocol THScannerViewDelegate: AnyObject {
    func scannerScan(barcode: String) -> Bool
    func needToRequestAuth()
}

class THScannerView: UIView {

    weak var delegate: THScannerViewDelegate?

    var bAnimationDown = false
    var fScanerWidth: CGFloat = 0

    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureMetadataOutput?
    var session: AVCaptureSession?
    var preview: AVCaptureVideoPreviewLayer?

    var vDetect = UIView.init()

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

        self.preview?.connection?.videoOrientation = .landscapeRight
        return
    }

    func start() {

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
                    self.delegate?.needToRequestAuth()
                }
            })
        }
    }

    func stop() {
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

        // 条码类型 AVMetadataObjectTypeQRCode
        self.output?.metadataObjectTypes = [.qr]

        self.preview = AVCaptureVideoPreviewLayer.init(session: self.session!)
        self.preview?.videoGravity = .resizeAspectFill
        preview?.transform = CATransform3DMakeRotation(CGFloat(Double.pi / 2), 0, 0, 1)
        preview?.connection?.videoOrientation = .landscapeRight
        preview?.frame = self.bounds

        self.layer.addSublayer(self.preview!)
        self.session?.startRunning()

        return true
    }

    var lastScanInfo: scanInfo?
}

typealias scanInfo = (Date, String)

extension THScannerView: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        var barCodeObj: AVMetadataMachineReadableCodeObject
        var detectionString = ""
        for metadata in metadataObjects {
            if metadata.type != .qr {
                continue
            }

            barCodeObj = preview?.transformedMetadataObject(for: metadata) as! AVMetadataMachineReadableCodeObject
            detectionString = barCodeObj.stringValue ?? ""

            if let info = self.lastScanInfo {
                let interval = Date().timeIntervalSince(info.0)

                if detectionString == info.1 && interval < 1 {
                    return
                }
                print(interval)
            }
            print(detectionString)

            self.lastScanInfo = (Date(), detectionString)

            if let dele = self.delegate {
                if dele.scannerScan(barcode: detectionString) == false {
                    self.stop()
                }
            }

            return
        }
    }

}
