//
//  BKImpactCell.swift
//  BeamKit
//
//  Created by ALEXANDRA SALVATORE on 10/29/19.
//  Copyright © 2020 Beam Impact. All rights reserved.
//

import UIKit

class BKImpactCell: UITableViewCell {
    //Image
    let titleImageView: TitleImageView = .init()
    let causeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.textColor = .white
        label.font = .beamRegular(size: 12)
        return label
    }()
    //percentage label
    let percentageView: GradientTextView = .init(with: [UIColor.beamGradientLightYellow.cgColor,
                                                        UIColor.beamGradientLightOrange.cgColor],
                                                 text: "%",
                                                 font: UIFont.beamBold(size: 40))
    // descriptionLabel
    private let descriptionLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.textColor = .gray //.beamOrange4
        label.font = .beamBold(size: 15)
        label.text = "funded towards total goal"
        return label
    }()
    // progress bar
    private let progressBar: GradientProgressBar = .init()
    let separatorLine: UIView = .init(with: .beamGray1)

    lazy var percWidth: NSLayoutConstraint =
        NSLayoutConstraint(item: self.percentageView,
                           attribute: .width,
                           relatedBy: .equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1.0,
                           constant: 0.0)
    
    
    func setup() {
        addSubview(titleImageView.usingConstraints())
        addSubview(causeLabel.usingConstraints())
        addSubview(percentageView.usingConstraints())
        addSubview(descriptionLabel.usingConstraints())
        addSubview(progressBar.usingConstraints())
        addSubview(separatorLine.usingConstraints())
        progressBar.isHidden = true
        percentageView.isHidden = true
        backgroundColor = .white
        titleImageView.clipsToBounds = true
        setupConstraints()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        percWidth.constant = percentageView.intrinsicContentSize.width
    }
    
    func setupConstraints() {
        let views: Views = ["title": titleImageView,
                            "cause": causeLabel,
                            "sep": separatorLine,
                            "desc": descriptionLabel,
                            "perc": percentageView,
                            "bar": progressBar]
        
        let formats: [String] = ["H:|[title]|",
                                 "H:|-30-[bar]-30-|",
                                 "H:|-30-[sep]-30-|",
                                 "H:|-30-[cause]-30-|",
                                 "H:|-30-[desc]-30-|",
                                 "V:|[title(180)]-14-[perc]-5-[bar(8)]-16-[sep(1)]-16-|",
                                 "V:[title]->=3-[desc]-[bar]",
                                 "V:|-8-[cause]"]
        var constraints: Constraints = NSLayoutConstraint.constraints(withFormats: formats, views: views)
        percWidth.constant = percentageView.intrinsicContentSize.width
        
        constraints += [NSLayoutConstraint.centerOnY(descriptionLabel, in: percentageView),
                        percWidth,
                        NSLayoutConstraint.centerOnX(causeLabel, in: self)]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    func configure(with impact: BKNonprofit) {
        let desc = impact.impactDescription
        descriptionLabel.text = "Your carbon was offset by \(desc)"
        titleImageView.title = impact.name
        setupProgress(with: impact)
        causeLabel.text = impact.cause?.uppercased()
        let image = impact.image
        if !image.isEmpty,
            let url = URL(string: image) {
            titleImageView.setImageWithUrl(url)
        }
        progressBar.setNeedsLayout()
        progressBar.layoutIfNeeded()
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func setupProgress(with impact: BKNonprofit) {

        let total = impact.totalDonations * 100
        let target = impact.targetDonations * 100
        let amtForGoal = total.truncatingRemainder(dividingBy: target)
        progressBar.numerator = amtForGoal == 0 ? target : amtForGoal
        progressBar.denominator = target

        let percent: Int = Int((CGFloat(progressBar.numerator) / CGFloat(progressBar.denominator)) * 100)
        percentageView.text = "\(percent)%"
    }
    
    override var intrinsicContentSize: CGSize {
        let height = 53 + 17 + 180 + descriptionLabel.intrinsicContentSize.height
        return CGSize(width: superview?.bounds.width ?? 0, height: height)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleImageView.prepareForReuse()
    }
}
