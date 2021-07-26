
import UIKit

@objc public protocol THNibOwnerLoadable: AnyObject {
}

// MARK: - Supporting methods
public extension THNibOwnerLoadable where Self: UIView {
    
    func loadNibContent() {
        let nib = UINib(nibName: type(of: self).description().components(separatedBy: ".").last!, bundle: nil)
        
        guard let views = nib.instantiate(withOwner: self, options: nil) as? [UIView],
            let contentView = views.first else {
                fatalError("Fail to load \(self) nib content")
        }
        self.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
}

open class THNibViewBase: UIView, THNibOwnerLoadable {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        self.loadNibContent()
        
        self.customerInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.loadNibContent()
        
        self.customerInit()
    }
    
    open func customerInit() {
        
    }
}
