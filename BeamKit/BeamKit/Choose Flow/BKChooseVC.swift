//
//  BKChooseVC.swift
//  beam-ios-sdk
//
//  Created by ALEXANDRA SALVATORE on 7/15/19.
//  Copyright © 2019 Beam Impact. All rights reserved.
//

import UIKit

public protocol BKChooseViewDelegate: class {
    func didConfirmBeamFavorite()
    func didOpenBeamChooseVC()
    var baseViewController: UIViewController { get }
}

public class BKChooseVC: UIViewController {

    var transaction: BKTransaction? = nil
    var storeID: String? = nil
    var flow: BKChooseFlow {
        return BeamKitContext.shared.chooseFlow
    }

    var header: BKVisitHeaderView? = nil
    public weak var delegate: BKChooseViewDelegate?

    let first: NonprofitView = .init(frame: .zero)
    let second: NonprofitView = .init(frame: .zero)
    let third: NonprofitView = .init(frame: .zero)
    let fourth: NonprofitView = .init(frame: .zero)
    var showFourth: Bool = true

    
    init(with transaction: BKTransaction?, storeID: String? = nil) {
        if let t = transaction {
            self.transaction = t
            header = BKVisitHeaderView(with: t)
        }
        self.storeID = storeID
        super.init(nibName: nil, bundle: nil)
    }
    
    public class func new() -> BKChooseVC? {
        guard let trans = BeamKitContext.shared.chooseFlow.context.currentTransaction else { return nil }
        return BKChooseVC.init(with: trans)
    }
    
    public class func new(at storeID: String) -> BKChooseVC {
        return BKChooseVC.init(with: nil, storeID: storeID)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        view.backgroundColor = .white
        guard let _ = transaction,
              let header = header else {
            setupProxy()
            return
        }
        view.addSubview(header.usingConstraints())
        view.addSubview(first.usingConstraints())
        view.addSubview(second.usingConstraints())
        view.addSubview(third.usingConstraints())
        view.addSubview(fourth.usingConstraints())
        
        configureNonprofits()
        addTargets()
        setupConstraints()
    }
    
    func setupProxy() {
        guard let storeID = storeID else { return }
        BeamKitContext.shared.chooseFlow.context.beginProxyTransaction(at: storeID) { trans, error in
            DispatchQueue.main.async {
                self.transaction = trans
                guard let trans = trans else { return }
                self.header = BKVisitHeaderView(with: trans)
                self.setup()

            }
        }

    }
    
    func configureNonprofits() {
        guard let nonprofits = transaction?.storeNon.nonprofits else { return }
        let firstNon = nonprofits.count > 0 ? nonprofits[0] : nil
        first.configure(with: firstNon)
        let secondNon = nonprofits.count > 1 ? nonprofits[1] : nil
        second.configure(with: secondNon)
        let thirdNon = nonprofits.count > 2 ? nonprofits[2] : nil
        third.configure(with: thirdNon)
        let fourthNon = nonprofits.count > 3 ? nonprofits[3] : nil
        fourth.configure(with: fourthNon)
        showFourth = !fourth.isHidden
    }
    
    func setupConstraints() {
        guard let header = header else { return }
        let views: Views = ["header": header,
                            "first": first,
                            "second": second,
                            "third": third,
                            "fourth": fourth,
        ]
        
        var formats: [String] = ["H:|[header]|",
                                 "H:|-10-[first]-10-|",
                                 "H:|-10-[second]-10-|",
                                 "H:|-10-[third]-10-|",
                                 "H:|-10-[fourth]-10-|"
        ]
        var insets: CGFloat = 0
        
        if #available(iOS 11.0, *) {
            insets = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 8
        }
        let metrics = ["top": insets]
        
        if showFourth {
            formats.append("V:|-top-[header][first]-2-[second]-2-[third]-2-[fourth]|")
        } else {
            formats.append("V:|-top-[header][first]-10-[second]-10-[third]|")
        }
        
        var constraints: Constraints = NSLayoutConstraint.constraints(withFormats: formats,
                                                                      metrics: metrics,
                                                                      views: views)
        
        constraints += [NSLayoutConstraint(item: first,
                                           attribute: .height,
                                           relatedBy: .equal,
                                           toItem: second,
                                           attribute: .height,
                                           multiplier: 1.0,
                                           constant: 0.0),
                        NSLayoutConstraint(item: second,
                                           attribute: .height,
                                           relatedBy: .equal,
                                           toItem: third,
                                           attribute: .height,
                                           multiplier: 1.0,
                                           constant: 0.0)]
        
        if showFourth {
            constraints += [NSLayoutConstraint(item: third,
                                               attribute: .height,
                                               relatedBy: .equal,
                                               toItem: fourth,
                                               attribute: .height,
                                               multiplier: 1.0,
                                               constant: 0.0)]
        }
        
        NSLayoutConstraint.activate(constraints)
    }
}

extension BKChooseVC {
    
    func addTargets() {
         header?.backButton.addTarget(self,
                                    action: #selector(didTapBackButton),
                                    for: .touchUpInside)
        first.delegate = self
        second.delegate = self
        third.delegate = self
        fourth.delegate = self
    }
    
    @objc
    func didTapBackButton() {
        flow.navigateBack(from: self)
    }
}

extension BKChooseVC: NonprofitViewDelegate {
    
    func didSelect(_ nonprofit: BKNonprofit?) {
        guard let nonprofit = nonprofit,
              let transaction = transaction else {
            flow.navigateBack(from: self)
            return
        }
        // turn off user interaction so doesn't call api twice
        view.isUserInteractionEnabled = false
        
        flow.redeem(transaction,
                    nonprofit: nonprofit,
                    from: self) {
                        self.delegate?.didConfirmBeamFavorite()
        }
    }
}

class BKVisitHeaderView: UIView {
    let transaction: BKTransaction
    fileprivate let backButton: BKBackButton = .init(frame: .zero)
    
    let navBarView: UIView = .init(with: .white)
    
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
    
    lazy var chainLogoImageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.backgroundColor = .clear
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    let plusLabel: GradientTextView = .init(with: [UIColor.beamGradientLightYellow.cgColor,
                                                   UIColor.beamGradientLightOrange.cgColor],
                                            text: "+",
                                            font: UIFont.beamBold(size: 15))
    
    let descriptionLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .beamRegular(size: 12)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.textColor = .beamOrange4
        return label
    }()
    let logoView: UIView = UIView(with: .white)

    var heightConstraint: NSLayoutConstraint?
    var widthConstraint: NSLayoutConstraint?
    let separatorBar: UIView = UIView(with: UIColor.accent)
    
    init(with transaction: BKTransaction) {
        self.transaction = transaction
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        let widthOfChain = UIScreen.main.bounds.width / 2 - 35
        let heightOfChain = UIView.beamDefaultNavBarHeight - 7
        if #available(iOS 9.0, *) {
           heightConstraint = chainLogoImageView.heightAnchor.constraint(equalToConstant: heightOfChain)
            widthConstraint = NSLayoutConstraint.constrainWidth(self.chainLogoImageView, by: widthOfChain)
        }

        descriptionLabel.attributedText = customDescriptionString
        let store = transaction.storeNon.store
        if let rectLogo = store?.rectLogo,
            let url = URL(string: rectLogo) {
            chainLogoImageView.bkSetImageWithUrl(url, priority: .veryHigh) { image in
                guard let image = image else { return }
                let ratio = image.size.width / image.size.height
                let chainLogoSize = self.chainLogoImageView.sizeThatFits(CGSize(width: widthOfChain,
                                                                           height: heightOfChain))
                self.heightConstraint?.constant = chainLogoSize.height
                self.heightConstraint?.isActive = true
                
                //width greater than height
                if ratio > 1 {
                    let heightRatio = heightOfChain / image.size.height
                    let scaledWidth = heightRatio * image.size.width
                    self.widthConstraint?.constant = min(scaledWidth, widthOfChain)
                    self.widthConstraint?.isActive = true
                }
            }
        } else if let logo = store?.logo,
            let url = URL(string: logo) {
            chainLogoImageView.bkSetImageWithUrl(url, priority: .veryHigh) { image in
                guard let image = image else { return }
                let ratio = image.size.width / image.size.height
                let chainLogoSize = self.chainLogoImageView.sizeThatFits(CGSize(width: widthOfChain,
                                                                           height: heightOfChain))
                self.heightConstraint?.constant = chainLogoSize.height
                self.heightConstraint?.isActive = true
                
                //width greater than height
                if ratio > 1 {
                    let heightRatio = heightOfChain / image.size.height
                    let scaledWidth = heightRatio * image.size.width
                    self.widthConstraint?.constant = min(scaledWidth, widthOfChain)
                    self.widthConstraint?.isActive = true
                }
            }
        }
        
        addSubview(navBarView.usingConstraints())
        navBarView.addSubview(backButton.usingConstraints())
        navBarView.addSubview(logoView.usingConstraints())
        logoView.addSubview(beamLogoImageView.usingConstraints())
        logoView.addSubview(chainLogoImageView.usingConstraints())
        logoView.addSubview(plusLabel.usingConstraints())
        addSubview(descriptionLabel.usingConstraints())
        addSubview(separatorBar.usingConstraints())
        setupConstraints()
    }
    
    var donationString: NSAttributedString {
        let amount = transaction.amount
        var donationString = "$" + amount.description
        
        let percent = transaction.storeNon.store?.percent ?? 0.01
        let amtInt = Int(percent * 100)
        donationString = String(amtInt) + "%"
        
        if let name = transaction.storeNon.store?.donationName {
            donationString = name
        }
        
        let attributes: [NSAttributedString.Key : Any] = [.font: UIFont.beamBold(size: 12) as Any,
                                                          .foregroundColor: UIColor.beamOrange4]
        
        let attributedString = NSAttributedString(string: donationString,
                                                  attributes: attributes)
        return attributedString
    }
    
    lazy var descriptionString: NSAttributedString = {
        let name = transaction.storeNon.store?.name ?? "We"
        let beginText = "\(name) will donate "
        let endText = " to one nonprofit below. Swipe left to learn more, and tap to choose your donation."
        
        let attributes: [NSAttributedString.Key : Any] = [.font: UIFont.beamRegular(size: 12) as Any,
                                                          .foregroundColor: UIColor.beamGray3]
        
        let desc = NSMutableAttributedString(string: beginText,
                                             attributes: attributes)
        
        let attributedEnd = NSAttributedString(string: endText,
                                               attributes: attributes)
        desc.append(donationString)
        desc.append(attributedEnd)
        return desc
    }()
    
    lazy var customDescriptionString: NSAttributedString = {
        let customParts = transaction.storeNon.store?.donationDescription?.components(separatedBy: "<b>name</b>")
        let attributes: [NSAttributedString.Key : Any] = [.font: UIFont.beamRegular(size: 12) as Any,
                                                          .foregroundColor: UIColor.beamOrange4]
        if customParts?.count == 1,
           let text = customParts?.first {
            return NSAttributedString(string: text, attributes: attributes)
        }
        let beginText = "Thanks for your order!\n\n"
        let middleText = customParts?.first ?? "We will donate "
        let endText = customParts?[1].replacingOccurrences(of: "\\n", with: "\n")
 ?? " to a nonprofit every time you order with us! Don't worry, you can change this with any order.\n\n" + "Just tap below to select your nonprofit, or tap on the arrow to learn more."

        
        let boldAttributes: [NSAttributedString.Key : Any] = [.font: UIFont.beamBold(size: 12) as Any,
                                                          .foregroundColor: UIColor.beamOrange4]
        
        let attrBegin = NSMutableAttributedString(string: beginText,
                                                  attributes: boldAttributes)
        
        let desc = NSMutableAttributedString(string: middleText,
                                             attributes: attributes)
        
        let attributedEnd = NSAttributedString(string: endText,
                                               attributes: attributes)
        attrBegin.append(desc)
        attrBegin.append(donationString)
        attrBegin.append(attributedEnd)
        return attrBegin
    }()

    
    func setupConstraints() {
        let insets = UIEdgeInsets.zero
        let views: Views = ["back": backButton,
                            "beam": beamLogoImageView,
                            "chain": chainLogoImageView,
                            "plus": plusLabel,
                            "desc": descriptionLabel,
                            "sep": separatorBar,
                            "logo": logoView,
                            "nav": navBarView]
        
        let metrics: [String: Any] = ["navHeight": UIView.beamDefaultNavBarHeight,
                                      "descHeight": UIView.beamDefaultNavBarHeight + 50,
                                      "top": insets.top,
                                      "pad": 5]
        
        let formats: [String] = ["H:|-30-[back(25)]->=8-[logo]->=20-|",
                                 "H:|[nav]|",
                                 "H:|[beam(60)]-[plus(9)]-(7@800)-[chain]|",
                                 "V:|-top-[nav(navHeight)]-5-[desc(descHeight)][sep(2)]|",
                                 "H:|[sep]|",
                                 "H:|-14-[desc]-14-|",
                                 "V:|->=5-[chain]|",
                                 "V:|-5-[beam]|",
                                 "V:|[logo]-2-|"]

        var constraints: Constraints = NSLayoutConstraint.center(logoView, in: navBarView)
        
        constraints += NSLayoutConstraint.constraints(withFormats: formats,
                                                      options: [],
                                                      metrics: metrics,
                                                      views: views)
        constraints += [NSLayoutConstraint.centerOnY(backButton, in: navBarView),
                        NSLayoutConstraint.centerOnY(plusLabel, in: logoView)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    override var intrinsicContentSize: CGSize {
        let width = bounds.width
        let height = UIView.beamDefaultNavBarHeight * 2 + 5
        return CGSize(width: width, height: height)
    }
}
