//
//  BKMatchTransactionView.swift
//  BeamKit
//
//  Created by ALEXANDRA SALVATORE on 1/27/20.
//  Copyright © 2020 Beam Impact. All rights reserved.
//

import UIKit

protocol BKMatchTransactionViewDelegate: class {
    func didToggleMatch(on: Bool)
}

class BKMatchTransactionView: UIView {
    weak var flow: BKChooseFlow?
    weak var delegate: BKMatchTransactionViewDelegate?
    
    var _isMatched: Bool = false
    
    private let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        label.numberOfLines = 1
        label.backgroundColor = .white
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.textColor = .beamGray3
        label.font = .beamSemiBold(size: 13)
        label.lineBreakMode = .byTruncatingTail
        label.text = "Unlocked: Make a Bigger Impact"
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.textColor = .beamGray3
        label.font = .beamRegular(size: 12)
        label.lineBreakMode = .byTruncatingTail
        label.text = "I’d like to match the donation to get closer to funding my goal"
        return label
    }()
    lazy var selectTap = UITapGestureRecognizer(target: self, action: #selector(didTap))

    let percentageView: GradientTextView = .init(with: [UIColor.beamGradientLightYellow.cgColor,
                                                         UIColor.beamGradientLightOrange.cgColor],
                                                  text: "+1%",
                                                  font: UIFont.beamBold(size: 24))
    
    let button: BKCheckButton = .init(frame: .zero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        backgroundColor = .white
        addSubview(titleLabel.usingConstraints())
        addSubview(descriptionLabel.usingConstraints())
        addSubview(percentageView.usingConstraints())
        addSubview(button.usingConstraints())
        setupConstraints()
        button.addGestureRecognizer(selectTap)
    }
    
    func setupConstraints() {
        let views: [String: UIView] = ["title": titleLabel,
                                       "desc": descriptionLabel,
                                       "per": percentageView,
                                       "button": button]
        let formats: [String] = ["V:|-2-[title]-4-[desc]-2-|",
                                 "V:|->=2-[per]->=2-|",
        "H:|-10-[desc]-[per]-8-[button(30)]-10-|",
        "H:|-10-[title]",
        "V:|->=2-[button(30)]->=2-|"]
        
        var constraints: [NSLayoutConstraint] =
            NSLayoutConstraint.constraints(withFormats: formats, views: views)
        constraints += [NSLayoutConstraint.centerOnY(button, in: self),
                        NSLayoutConstraint.centerOnY(percentageView, in: self),
                        NSLayoutConstraint.constrainWidth(percentageView, by: percentageView.intrinsicContentSize.width + 54)]
        NSLayoutConstraint.activate(constraints)
    }
    
    func configure(with store: BKStore?, nonprofit: String, total: CGFloat) {
        guard let store = store else { return }
        toggleMatch(on: _isMatched)

        descriptionLabel.text = "I’d like to match the donation to \(nonprofit) to get closer to funding my goal"
        
        if let title = store.matchTitle {
            titleLabel.text = title
        }
        if let desc = store.matchDescription {
            descriptionLabel.text = desc
        }
        let percent = store.matchPercent ?? 0.01
        var amtInt: Double = Double(percent * total)
        amtInt = amtInt.cutOffDecimalsAfter(2)
        let donationString = amtInt.dollarString
        percentageView.text = donationString
    }
    
    override var intrinsicContentSize: CGSize {
        let height = titleLabel.intrinsicContentSize.height + descriptionLabel.intrinsicContentSize.height + 8
        return CGSize(width: 0, height: height)
    }
    
    @objc
    func didTap() {
        _isMatched = !_isMatched
        toggleMatch(on: _isMatched)
    }
    
    func toggleMatch(on: Bool) {
        button.toggle(on: on)
        percentageView.toggleActive(on: on)
        delegate?.didToggleMatch(on: on)
    }
}

class BKCheckButton: UIView {
    let circleView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .white
        view.layer.borderColor = UIColor.beamGray3.cgColor
        view.layer.borderWidth = 2
        return view
    }()

    let check: UIImageView = {
        let view = UIImageView(frame: .zero)
        let bundle = BeamKitContext.shared.bundle
        var image = UIImage(named: "beam-check", in: bundle, compatibleWith: nil)
        image = image?.maskWithColor(color: .beamOrange4)
        view.image = image
        view.isUserInteractionEnabled = true
        view.backgroundColor = .clear
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circleView.layer.cornerRadius = circleView.bounds.height / 2
    }
    
    func setupViews() {
        backgroundColor = .white
      //  clipsToBounds = true
        addSubview(circleView.usingConstraints())
        addSubview(check.usingConstraints())
        setupConstraints()
    }
    
    func setupConstraints() {
        let views: [String: UIView] = ["circle": circleView,
                                       "check": check]
        let formats: [String] = ["V:|-6-[circle]-8-|"
        ]
        
        var constraints: [NSLayoutConstraint] =
            NSLayoutConstraint.constraints(withFormats: formats, views: views)
        constraints += [NSLayoutConstraint.square(circleView),
                        NSLayoutConstraint(item: check,
                                           attribute: .width,
                                           relatedBy: .equal,
                                           toItem: self,
                                           attribute: .width,
                                           multiplier: 1.0,
                                           constant: 0),
                        NSLayoutConstraint.centerOnX(circleView, in: self)]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    func toggle(on: Bool) {
        check.isHidden = !on
    }
    
}

extension Double {
    /// Rounds the double to decimal places value
    func roundToPlaces(_ places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    func cutOffDecimalsAfter(_ places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self*divisor).rounded(.towardZero) / divisor
    }
    
    var dollarString:String {
        return String(format: "+$%.2f", self)
    }
}
