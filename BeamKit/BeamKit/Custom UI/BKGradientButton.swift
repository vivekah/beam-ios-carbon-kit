//
//  GradientButton.swift
//  Beam
//
//  Created by ALEXANDRA SALVATORE on 11/13/18.
//  Copyright © 2018 Beam Impact. All rights reserved.
//

import UIKit

class BKGradientButton: UIButton {

    var isInverted: Bool = false {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    let gradient: CAGradientLayer = {
        let gradient: CAGradientLayer = .init()
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.colors = [UIColor.beamGradientLightYellow.cgColor,
                           UIColor.beamGradientLightOrange.cgColor]
        return gradient
    }()
    
    lazy var tintView: UIView = {
        let view = UIView(with: .beamGray3)
        view.alpha = 0.3
        clipsToBounds = true
        return view
    }()
    
    var roundCorners: Bool = true
    
    override func layoutSubviews() {
        if roundCorners {
            layer.cornerRadius = bounds.height / 2
        }
        gradient.frame = bounds
        mask = isInverted ? titleLabel : nil
        adjustTint()
        super.layoutSubviews()
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        let width = size.width +
            titleEdgeInsets.left + titleEdgeInsets.right
        let height = size.height +
            titleEdgeInsets.top + titleEdgeInsets.bottom

        return CGSize(width: width, height: height)
    }
    
    func setupViews() {
        clipsToBounds = true
        titleEdgeInsets = UIEdgeInsets(top: 10, left: 30, bottom: 10, right: 30)
        layer.addSublayer(gradient)
        setTitleColor(.white, for: .normal)
    }
    
    func set(enabled: Bool) {
        isEnabled = enabled
        if enabled {
            removeTint()
        } else {
            addTint()
        }
    }
    
    func set(color: UIColor) {
        gradient.colors = [color.cgColor]
    }
    
    func addTint() {
        guard !subviews.contains(tintView) else { return }
        addSubview(tintView)
        adjustTint()
    }
    
    func removeTint() {
        guard subviews.contains(tintView) else { return }
        tintView.removeFromSuperview()
    }
    
    func adjustTint() {
        guard subviews.contains(tintView) else { return }
        tintView.frame = bounds
        tintView.layer.cornerRadius = bounds.height / 2
    }
}


class BKNavBarView: UIView {
    let backButton: BKBackButton = .init(frame: .zero)

    let beamLogoImageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.backgroundColor = .clear
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        let bundle = BeamKitContext.shared.bundle
        let image = UIImage(named: "bkLogo", in: bundle, compatibleWith: nil)
        view.image = image
        return view
    }()
    
    let chainLogoImageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.backgroundColor = .clear
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    
    var widthConstraint: NSLayoutConstraint?
    let logoView: UIView = UIView(with: .white)
    
    let plusLabel: GradientTextView = .init(with: [UIColor.beamGradientLightYellow.cgColor,
                                                   UIColor.beamGradientLightOrange.cgColor],
                                            text: "+",
                                            font: UIFont.beamBold(size: 15))

    let separatorBar: UIView = UIView(with: UIColor.accent)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        addSubview(backButton.usingConstraints())
        addSubview(logoView.usingConstraints())
        logoView.addSubview(beamLogoImageView.usingConstraints())
        logoView.addSubview(chainLogoImageView.usingConstraints())
        logoView.addSubview(plusLabel.usingConstraints())
        addSubview(separatorBar.usingConstraints())
        setupConstraints()
    }
    
    func setupConstraints() {
        let widthOfChain = UIScreen.main.bounds.width / 2 - 35
        if #available(iOS 9.0, *) {
            widthConstraint = NSLayoutConstraint.constrainWidth(self.chainLogoImageView, by: widthOfChain)
        }

        let insets = UIEdgeInsets.zero
        let views: Views = ["back": backButton,
                            "logo": logoView,
                            "beam": beamLogoImageView,
                            "chain": chainLogoImageView,
                            "sep": separatorBar,
                            "plus": plusLabel]
        
        let metrics: [String: Any] = ["navHeight": UIView.beamDefaultNavBarHeight,
                                      "top": insets.top]
        
        let formats: [String] = ["H:|-30-[back(25)]->=8-[logo]->=20-|",
                                 "H:|[sep]|",
                                 "H:|[beam(60)]-[plus]-[chain]|",
                                 "V:|->=5-[chain]|",
                                 "V:|[beam]|",
                                 "V:|-5-[logo]-2-[sep(2)]"]
        
        var constraints: Constraints = NSLayoutConstraint.center(logoView, in: self)

        constraints += NSLayoutConstraint.constraints(withFormats: formats,
                                                      options: [],
                                                      metrics: metrics,
                                                      views: views)
        constraints += [NSLayoutConstraint.centerOnY(backButton, in: self),
                        NSLayoutConstraint.centerOnY(plusLabel, in: logoView),
                        NSLayoutConstraint.constrainHeight(self, by: 65)]
        
        NSLayoutConstraint.activate(constraints)
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func update(with url: URL) {
        let widthOfChain = UIScreen.main.bounds.width / 2 - 35
        let heightOfChain = UIView.beamDefaultNavBarHeight - 7
        chainLogoImageView.bkSetImageWithUrl(url, priority: .veryHigh) { image in
            guard let image = image else { return }
            let ratio = image.size.width / image.size.height
            
            //width greater than height
            if ratio > 1 {
                let heightRatio = heightOfChain / image.size.height
                let scaledWidth = heightRatio * image.size.width
                self.widthConstraint?.constant = min(scaledWidth, widthOfChain)
                self.widthConstraint?.isActive = true
            }
        }
    }

}
