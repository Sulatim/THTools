
import UIKit

protocol THNibOwnerLoadable: AnyObject {
}

// MARK: - Default implmentation
extension THNibOwnerLoadable {
}

// MARK: - Supporting methods
extension THNibOwnerLoadable where Self: UIView {
    
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

class THNibViewBase: UIView, THNibOwnerLoadable {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.loadNibContent()
        
        self.customerInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.loadNibContent()
        
        self.customerInit()
    }
    
    func customerInit() {
        
    }
}