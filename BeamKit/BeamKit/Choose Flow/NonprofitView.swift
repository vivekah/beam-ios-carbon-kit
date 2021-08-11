//
//  NonprofitView.swift
//  beam-ios-sdk
//
//  Created by ALEXANDRA SALVATORE on 6/26/19.
//  Copyright © 2019 Beam Impact. All rights reserved.
//

import UIKit

protocol NonprofitViewDelegate {
    func didSelect(_ id: BKNonprofit?)
}

internal class NonprofitView: UIButton {
    var nonprofit: BKNonprofit?
    var delegate: NonprofitViewDelegate?
    
    lazy var selectTap = UITapGestureRecognizer(target: self, action: #selector(didTap))
    lazy var learnMoreTap = UITapGestureRecognizer(target: self, action: #selector(didTapArrow))
    
    lazy var swipe = UIPanGestureRecognizer(target: self, action: #selector(didTapArrow))
    
    let selectViewTapTarget: UIView = .init(with: .clear)
    let learnMoreViewTapTarget: UIView = .init(with: .clear)
    
    let backgroundImage: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.backgroundColor = .clear
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    let tintView: UIView = .init(with: .beamGray3)
    
    let nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIDevice.current.is5or4Phone ? UIFont.beamBold(size: 20) : UIFont.beamBold(size: 24)
        label.textAlignment = .left
        label.numberOfLines = 1
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.textColor = .white
        return label
    }()
    
    let progressBar: GradientProgressBar = .init(tintType: .blur)
    
    let arrowButton: UIButton = {
        let button = UIButton(frame: .zero)
        let bundle = BeamKitContext.shared.bundle
        let image = UIImage(named: "NonprofitArrow", in: bundle, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleToFill
        button.backgroundColor = .clear
        return button
    }()
    
    let infoView: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.beamRegular(size: 12)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.textColor = .white
        return label
    }()
    
    let infoTextLabelView: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.beamRegular(size: 16)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.textColor = .white
        return label
    }()
    
    
    let percentageTextLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.beamRegular(size: 12)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.textColor = .white
        return label
    }()
    
    let causeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIDevice.current.is5or4Phone ? UIFont.beamRegular(size: 11.0) : UIFont.beamRegular(size: 12.0)
        label.textAlignment = .left
        label.numberOfLines = 1
        label.textColor = .white
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()
    
    let beamGradientLayer: CAGradientLayer = .beamGradient
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
       // beamGradientLayer.frame = infoView.bounds
    }
    
    func configure(with nonprofit: BKNonprofit?) {
        guard let nonprofit = nonprofit else {
            self.isHidden = true
            return
        }
        self.nonprofit = nonprofit
        if let url = URL(string: nonprofit.image) {
            backgroundImage.bkSetImageWithUrl(url, priority: .veryHigh)
        }
        nameLabel.text = nonprofit.name
        
        progressBar.denominator = nonprofit.targetDonations
        progressBar.numerator = nonprofit.totalDonations.truncatingRemainder(dividingBy: nonprofit.targetDonations)
        let percent: Int = max(Int((CGFloat(progressBar.numerator) / CGFloat(progressBar.denominator)) * 100), 1)
        
        percentageTextLabel.text = "\(percent)%"
        infoView.text = nonprofit.missionDescription
        let desc = nonprofit.impactDescription
        infoTextLabelView.text = "Fund \(desc)"
        causeLabel.text = nonprofit.cause?.uppercased()
    }
    
    func setup() {
        tintView.alpha = 0.4
        
        infoView.layer.addSublayer(beamGradientLayer)
        //infoView.addSubview(infoTextLabelView.usingConstraints())
        infoView.isHidden = true
        addSubview(backgroundImage.usingConstraints())
        backgroundImage.addSubview(tintView.usingConstraints())
        backgroundImage.addSubview(nameLabel.usingConstraints())
        backgroundImage.addSubview(progressBar.usingConstraints())
        backgroundImage.addSubview(causeLabel.usingConstraints())
        backgroundImage.addSubview(infoTextLabelView.usingConstraints())
        backgroundImage.addSubview(percentageTextLabel.usingConstraints())
        addSubview(infoView.usingConstraints())
        addSubview(arrowButton.usingConstraints())
        
        addSubview(selectViewTapTarget.usingConstraints())
        addSubview(learnMoreViewTapTarget.usingConstraints())
        
        isUserInteractionEnabled = true
        selectViewTapTarget.addGestureRecognizer(selectTap)
        learnMoreViewTapTarget.addGestureRecognizer(learnMoreTap)
        swipe.delegate = self
        addGestureRecognizer(swipe)
        arrowButton.addTarget(self, action: #selector(didTapArrow), for: .touchUpInside)
        arrowButton.isHidden = true
        setupConstraints()
    }
    
    func setupConstraints() {
        let views: Views = ["back": backgroundImage,
                            "tint": tintView,
                            "name": nameLabel,
                            "bar": progressBar,
                            "arrow": arrowButton,
                            "info": infoView,
                            "desc": infoTextLabelView,
                            "cause": causeLabel,
                            "perc": percentageTextLabel,
                            "select": selectViewTapTarget,
                            "learn": learnMoreViewTapTarget]
        let formats: [String] = ["H:|-30-[name]-55-|",
                                 "H:|-30-[bar]-[perc]-10-|",
                                 "H:[arrow(30)]-20-|",
                                 "H:|[select][learn(50)]|",
                                 "V:|[select]|",
                                 "V:|[learn]|",
                                 "V:[arrow(30)]",
                                 "H:|[tint]|",
                                 "V:|[tint]|",
                                 "V:|[back]|",
                                 "V:|[info]|",
                                 "H:|[back]|",
                                 "H:|-30-[desc]-30-|",
                                 "H:[tint][info]",
                                 "H:|-30-[cause]->=10-|",
                                 "V:|-8-[cause]->=8-[name]-[desc]-8-[bar(9)]-15-|"]
        var constraints: Constraints =
            NSLayoutConstraint.constraints(withFormats: formats, views: views)
        
        constraints += [NSLayoutConstraint.centerOnY(arrowButton, in: self),
                        NSLayoutConstraint.centerOnY(percentageTextLabel, in: progressBar),
                        NSLayoutConstraint(item: infoView,
                                           attribute: .width,
                                           relatedBy: .equal,
                                           toItem: backgroundImage,
                                           attribute: .width,
                                           multiplier: 1.0,
                                           constant: 0.0)]
        
        NSLayoutConstraint.activate(constraints)
    }
}

extension NonprofitView {
    @objc
    func didTapArrow() {
        let isShowingInfoView = backgroundImage.transform != CGAffineTransform.identity
        if isShowingInfoView {
            animateHideInfo()
        } else {
            animateShowInfo()
        }
    }
    
    @objc
    func didTap() {
        self.delegate?.didSelect(nonprofit)
    }
    
    private func animateShowInfo() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let `self` = self else { return }
            
            let xTranslation = -self.backgroundImage.bounds.width
            let transform = CGAffineTransform(translationX: xTranslation, y: 0)
            self.infoView.transform = transform
            self.backgroundImage.transform = transform
            self.arrowButton.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        }
    }
    
    private func animateHideInfo() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let `self` = self else { return }
            self.infoView.transform = .identity
            self.backgroundImage.transform = .identity
            self.arrowButton.transform = .identity
        }
    }
}

extension NonprofitView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

