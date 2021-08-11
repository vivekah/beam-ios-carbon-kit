//
//  BKTransactionView.swift
//  BeamKit
//
//  Created by ALEXANDRA SALVATORE on 10/29/19.
//  Copyright © 2020 Beam Impact. All rights reserved.
//

import UIKit

public protocol BKChooseDelegate: class {
    var baseViewController: UIViewController { get }
    func didToggleMatch(on: Bool, amount: CGFloat)
}

public enum BKBackgroundType {
    case solid(UIColor)
    case gradient(UIColor, UIColor)
    case beamGradient
    case image
    case leftImage
}

public class BKChooseButton: UIView {
    public weak var delegate: BKChooseDelegate?
    
    var flow: BKChooseFlow {
        return BeamKitContext.shared.chooseFlow
    }
    
    public var cornerRadius: CGFloat = 0.0 {
        didSet {
            contentView.layer.cornerRadius = cornerRadius
            match.layer.cornerRadius = cornerRadius
        }
    }
    
    public var borderColor: UIColor = .white {
        didSet {
            contentView.layer.borderColor = borderColor.cgColor
            match.layer.borderColor = borderColor.cgColor
        }
    }
    public var borderWidth: CGFloat = 0.0 {
        didSet {
            contentView.layer.borderWidth = borderWidth
            match.layer.borderWidth = borderWidth
        }
    }
    
    public var titleFont: UIFont? = .beamBold(size: 13) {
        didSet {
            labelView.font = titleFont
        }
    }
    
    public var buttonFont: UIFont? = .beamBold(size: 15.0) {
        didSet {
            changeButton.titleLabel?.font = buttonFont
        }
    }
    
    var canMatch: Bool {
        return self.flow.context.currentTransaction?.canMatch ?? false
    }
    
    let contentView: UIView = .init(with: .white)
    let backgroundView: BKBackgroundView
    
    let labelView: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.beamBold(size: 13)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.textColor = .white
        label.text = "1% of your purchase will be donated to the nonprofit of your choice!"
        return label
    }()
    
    lazy var separatorLine: UIView = .init(with: .gray)
    
    let changeButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.titleLabel?.font = .beamBold(size: 15.0)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.setTitle("Change", for: .normal)
        button.backgroundColor = .clear
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.clipsToBounds = true
        return button
    }()
    let match: BKMatchTransactionView = .init(frame: .zero)
    
    public init?(type: BKBackgroundType = .leftImage) {
        guard let _ = BeamKitContext.shared.chooseFlow.context.currentTransaction else { return nil }
        self.backgroundView = BKBackgroundView(with: type)
        let rect = CGRect(x: 0, y: 0, width: 300, height: 135)
        super.init(frame: rect)

        setup()
        listen()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.async {
            let radius = self.changeButton.bounds.height / 2.5
            self.changeButton.layer.cornerRadius = radius == 0 ? 10 : radius
            self.backgroundView.setupTint()
        }

    }
    
    func setup() {
        contentView.clipsToBounds = true
        addSubview(contentView.usingConstraints())
        contentView.addSubview(backgroundView.usingConstraints())
        contentView.addSubview(changeButton.usingConstraints())
        contentView.addSubview(labelView.usingConstraints())
        if canMatch {
            addSubview(match.usingConstraints())
            match.delegate = self
        }
        update(with: self.flow.context.currentTransaction)

        changeButton.addTarget(self, action: #selector(didTapChange), for: .touchUpInside)
        if case .leftImage = backgroundView.backgroundType {
            setupLeftConstraionts()
        } else {
            setupDefaultConstraints()
        }
    }
    
    func setupDefaultConstraints() {
        var views: Views = ["back": backgroundView,
                            "button": changeButton,
                            "label": labelView,
                            "content": contentView]
        if canMatch {
            views["match"] = match
        }
        
        var formats = ["H:|[back]|",
                       "V:|[back]|",
                       "H:|[content]|",
                       "H:|-15-[label]-10-[button]-15-|",
                       "V:|->=5-[label]->=5-|",
                       "V:|->=5-[button]->=5-|"]
        formats += canMatch ? ["V:|[content]-5-[match(80)]|","H:|[match]|"] : ["V:|[content]|"]
        var constraints: Constraints = NSLayoutConstraint.constraints(withFormats: formats, views: views)
        
        constraints += [NSLayoutConstraint.centerOnY(labelView, in: contentView),
                        NSLayoutConstraint.centerOnY(changeButton, in: contentView),
                        NSLayoutConstraint.constrainHeight(changeButton, by: changeButton.intrinsicContentSize.height + 16),
                        NSLayoutConstraint.constrainWidth(changeButton, by: changeButton.intrinsicContentSize.width + 24)]
        NSLayoutConstraint.activate(constraints)
    }
    
    func setupLeftConstraionts() {
        contentView.addSubview(separatorLine.usingConstraints())
        let titleColor: UIColor = UIColor.accent != .white ? UIColor.accent : .black
        labelView.textColor = .black
        changeButton.setTitleColor(titleColor, for: .normal)
        changeButton.setTitle("CHANGE", for: .normal)
        var views: Views = ["back": backgroundView,
                            "button": changeButton,
                            "label": labelView,
                            "sep": separatorLine,
                            "content": contentView]
        if canMatch {
            views["match"] = match
        }
        
        var formats = ["V:|[back]|",
                       "H:|[content]|",
                       "H:|[back]-7-[label]-7-|",
                       "H:[back]-[sep]-|",
                       "H:[back]-[button]-|",
                       "V:|-5-[label]-[sep(1)][button(<=40)]|"]
        formats += canMatch ? ["V:|[content]-5-[match(80)]|","H:|[match]|"] : ["V:|[content]|"]
        var constraints: Constraints = NSLayoutConstraint.constraints(withFormats: formats, views: views)
        
        constraints += [NSLayoutConstraint(item: backgroundView,
                                           attribute: .width,
                                           relatedBy: .equal,
                                           toItem: contentView,
                                           attribute: .height,
                                           multiplier: 1.0,
                                           constant: 0)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    public override var intrinsicContentSize: CGSize {
        var height: CGFloat = 135
        if canMatch {
            height += 5
            height += match.intrinsicContentSize.height
        }
        var width: CGFloat = 0
        if let sup = superview {
            width = sup.bounds.width - 20
        }
        return CGSize(width: width, height: height)
    }
    
    func update(with transaction: BKTransaction?) {
        guard let trans = transaction,
            let nonprofit = trans.chosenNonprofit ??
                            trans.storeNon.lastNonprofit else {
                                setupEmptyState(for: transaction)
                return
        }

        backgroundView.set(image:nonprofit.image)
        setupDescription(for: trans, nonprofit: nonprofit)
        if canMatch {
            match.configure(with: trans.storeNon.store,
                            nonprofit: nonprofit.name,
                            total: trans.amount)
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func setupDescription(for transaction: BKTransaction, nonprofit: BKNonprofit) {
        guard let store = transaction.storeNon.store else {
                setupEmptyState(for: transaction)
                return
        }
        var donationString = store.donationName ?? ""
        
        if donationString.isEmpty {
            let percent = store.percent ?? 0.01
            let amount = transaction.amount * percent
            donationString = "$" + amount.description

            if amount < 1 {
                let donationAmountInt = Int(amount * 100)
                donationString = String(donationAmountInt) + "¢"
            } else if amount > 0 {
                let isInt = floor(amount) == amount
                if isInt {
                    donationString = "$" + String(Int(amount))
                }
            }
        }
        labelView.text = "Your carbon offset is funding \(nonprofit.impactDescription)"
    }
    
    func setupEmptyState(for transaction: BKTransaction?) {
        guard let transaction = transaction,
            let store = transaction.storeNon.store,
            let brand = store.name else {
            return
        }
        
        let percentString = store.donationName ?? "a portion"
        labelView.text = "\(brand) will donate \(percentString) of your purchase to the nonprofit you choose!"
        setNeedsLayout()
        layoutIfNeeded()
    }
}

extension BKChooseButton {
    @objc
    func didTapChange() {
        guard let delegate = delegate else {
            //TODO Log dev error
            return
        }
        listen()
        flow.showChooseNonprofitVC(from: delegate.baseViewController)
    }
    
    func listen() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didUpdateNonprofit),
                                               name: ._bkdidSelectNonprofit,
                                               object: nil)
    }
    
    @objc
    func didUpdateNonprofit(_ notification: Notification) {
        guard let info = notification.userInfo,
            let trans = info["transaction"] as? BKTransaction else { return }
        update(with: trans)
    }
}

extension BKChooseButton: BKMatchTransactionViewDelegate {
    
    func didToggleMatch(on: Bool) {
        guard let transaction = flow.context.currentTransaction else { return }
        transaction.userDidMatch = on
        delegate?.didToggleMatch(on: on, amount: transaction.amount)
    }
    
}

class BKBackgroundView: UIImageView {
    let backgroundType: BKBackgroundType
    let tintView: UIView = .init(with: .beamGray3)

    lazy var gradient: CAGradientLayer = .beamGradient
    
    init(with type: BKBackgroundType) {
        self.backgroundType = type
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        gradient.frame = bounds
        super.layoutSubviews()
    }
    
    func setup() {
        backgroundColor = .white
        contentMode = .scaleAspectFill
        clipsToBounds = true
        layer.masksToBounds = true
        switch backgroundType {
        case let .gradient(top, bottom):
            gradient.colors = [top.cgColor,
                               bottom.cgColor]
            addGradient()
            return
        case let .solid(color):
            backgroundColor = color
            return
        case .image, .leftImage:
            setupEmptyState()
            return
        case .beamGradient:
            addGradient()
            return
        }
    }
    
    func addGradient() {
        layer.addSublayer(gradient)
    }
    
    func removeGradient() {
        gradient.removeFromSuperlayer()
    }
    
    func setupEmptyState() {
        addGradient()
    }
    
    func setupTint() {
        tintView.removeFromSuperview()
        guard case .image = backgroundType else { return }
        addSubview(tintView)
        tintView.alpha = 0.35
        tintView.frame = bounds
    }
    
    func set(image: String?) {
        guard let image = image,
            let url = URL(string: image) else { return }
        if case .image = backgroundType {
            removeGradient()
            self.bkSetImageWithUrl(url)
            setupTint()
        }
        if case .leftImage = backgroundType {
            removeGradient()
            self.bkSetImageWithUrl(url)
        }
    }
}
