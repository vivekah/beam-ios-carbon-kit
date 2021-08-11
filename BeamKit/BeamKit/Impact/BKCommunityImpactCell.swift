//
//  BKCommunityImpactCell.swift
//  BeamKit
//
//  Created by ALEXANDRA SALVATORE on 1/14/20.
//  Copyright © 2020 Beam Impact. All rights reserved.
//

import UIKit

class BKCommunityImpactCell: UITableViewCell {
    
    static let intrinsicHeight: CGFloat = 225
    static let sideInset: CGFloat = 15
    static let topInset: CGFloat = 5
    
    let mainImageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.backgroundColor = .white
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        return view
    }()
    
    private let tintView: UIView = {
        let view = UIView(with: .beamGray3)
        view.alpha = 0.3
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.textColor = .white
        label.font = .beamBold(size: 24)
        return label
    }()
    
    private let causeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.textColor = .white
        label.font = .beamBold(size: 11)
        return label
    }()
    
    let progressBar: GradientProgressBar = .init(tintType: .color(.beamGray2))

    let percentageView: GradientTextView = .init(with: [UIColor.beamGradientLightYellow.cgColor,
                                                        UIColor.beamGradientLightOrange.cgColor],
                                                 text: "%",
                                                 font: UIFont.beamBold(size: 28))
    
    private let gradient: CAGradientLayer = .beamGradient
    
    private let baseView: UIView = .init(with: .white)
    
    private let goalLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.textColor = .beamGray3
        label.font = .beamRegular(size: 14)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let gradientBounds = bounds.inset(by: UIEdgeInsets(top: BKCommunityImpactCell.topInset,
                                                           left: BKCommunityImpactCell.sideInset,
                                                           bottom: BKCommunityImpactCell.topInset,
                                                           right: BKCommunityImpactCell.sideInset))
        layer.cornerRadius = 17
        gradient.cornerRadius = 17
        gradient.frame = gradientBounds
        baseView.layer.cornerRadius = 15
    }
    
    func setup() {
        clipsToBounds = true
        layer.addSublayer(gradient)
        addSubview(baseView.usingConstraints())
        baseView.addSubview(mainImageView.usingConstraints())
        mainImageView.addSubview(tintView.usingConstraints())
        mainImageView.addSubview(causeLabel.usingConstraints())
        mainImageView.addSubview(titleLabel.usingConstraints())
        baseView.addSubview(goalLabel.usingConstraints())
        baseView.addSubview(progressBar.usingConstraints())
        baseView.addSubview(percentageView.usingConstraints())
        gradient.masksToBounds = true
        tintView.clipsToBounds = true
        baseView.clipsToBounds = true
        setupConstraints()
    }
    
    func setupConstraints() {
        let views: Views = ["img": mainImageView,
                            "tint": tintView,
                            "cause": causeLabel,
                            "title": titleLabel,
                            "perc": percentageView,
                            "desc": baseView,
                            "bar": progressBar,
                            "goal": goalLabel]
        
        let metrics: JSON = ["left": 15,
                             "top": 10,
                             "topInset": BKCommunityImpactCell.topInset + 7,
                             "sideInset": BKCommunityImpactCell.sideInset + 7,
                             "height": (BKCommunityImpactCell.intrinsicHeight * 0.53)]
        let formats: [String] =
            ["V:|-topInset-[desc]-topInset-|",
             "H:|-sideInset-[desc]-sideInset-|",
             "H:|[img]|",
             "H:|[tint]|",
             "V:|[tint]|",
             "H:|-left-[cause]",
             "H:|-left-[title]-left-|",
             "H:|-left-[bar]-left-|",
             "H:|-left-[goal]-[perc(60)]-left-|",
             "V:|[img(height)]-8-[bar(8)]-[goal]-|",
             "V:[perc]-|",
             "V:|->=top-[cause][title]-top-|"]
        
        var constraints: [NSLayoutConstraint] =
            NSLayoutConstraint.constraints(withFormats: formats,
                                           options: [],
                                           metrics: metrics,
                                           views: views)
        constraints += [NSLayoutConstraint.centerOnY(percentageView, in: goalLabel)]

        NSLayoutConstraint.activate(constraints)
    }
    
    func configure(with impact: BKNonprofit) {
        titleLabel.text = impact.name
        let desc = impact.impactDescription
        goalLabel.text = "Offset by \(desc)"
        causeLabel.text = impact.cause?.uppercased()
        
        setupProgress(with: impact)
        let URLString = impact.image
        if let imageURL = URL(string: URLString) {
            mainImageView.bkSetImageWithUrl(imageURL)
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func setupProgress(with impact: BKNonprofit) {
        
            let total = max(impact.totalDonations * 100, 1)
            let target = impact.targetDonations * 100
            let amtForGoal = total.truncatingRemainder(dividingBy: target)
            progressBar.numerator = amtForGoal == 0 ? target : amtForGoal
            progressBar.denominator = target
        
        let percent: Int = max(Int((CGFloat(progressBar.numerator) / CGFloat(progressBar.denominator)) * 100), 1)
        
        percentageView.text = "\(percent)%"
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width - 10, height: BKCommunityImpactCell.intrinsicHeight)
    }
}
