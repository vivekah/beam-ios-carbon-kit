//
//  BKCommunityImpactVC.swift
//  BeamKit
//
//  Created by ALEXANDRA SALVATORE on 1/29/20.
//  Copyright © 2020 Beam Impact. All rights reserved.
//

import UIKit

class BKCommunityImpactVC: UIViewController {
    weak var context: BKImpactContext?
    weak var flow: BKImpactFlow?
    
    let impactIdentifier = "bk_community_impact_cell"
    
    let headerView: UIView = .init(with: .white)
    
    let descriptionLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .beamRegular(size: 15)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.textColor = .beamGray3
        label.text = "See the impact our community is making together with every carbon-neutral order."
        return label
    }()
    
    private let impactTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.rowHeight = BKCommunityImpactCell.intrinsicHeight
        table.estimatedRowHeight = BKCommunityImpactCell.intrinsicHeight
        table.separatorInset = .zero
        table.layoutMargins = .zero
        table.separatorStyle = .none
        return table
    }()
    
    init(context: BKImpactContext,
         flow: BKImpactFlow) {
        self.context = context
        self.flow = flow
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        view = impactTableView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        listen()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        configureHeader()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureHeader()
    }
    
    func setup() {
        headerView.addSubview(descriptionLabel)
        impactTableView.dataSource = self
        impactTableView.delegate = self
        impactTableView.tableHeaderView = headerView
        impactTableView.register(BKCommunityImpactCell.self,
                                 forCellReuseIdentifier: impactIdentifier)
    }
    
    func listen() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(impactDidLoad),
                                               name: ._bkDidUpdateCommunityImpact,
                                               object: nil)
    }
    
    func configureHeader() {
        headerView.frame = CGRect(x: 0,
                                  y: 0,
                                  width: view.bounds.width,
                                  height: 55)
        descriptionLabel.frame = CGRect(x: 10,
                                  y: 2,
                                  width: view.bounds.width - 20,
                                  height: 53)
    }
}

extension BKCommunityImpactVC {
    @objc
    func impactDidLoad() {
        DispatchQueue.main.async {
            self.impactTableView.reloadData()
        }
    }
}

extension BKCommunityImpactVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return context?.communityImpact?.nonprofits.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let context = context,
            let cell = impactTableView.dequeueReusableCell(withIdentifier: impactIdentifier,
                                                             for: indexPath) as? BKCommunityImpactCell else {
            return UITableViewCell()
        }
        if let impact = context.communityImpact?.nonprofits[indexPath.row] {
            cell.configure(with: impact)
        }
        return cell
    }
    
}

extension BKCommunityImpactVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}


class BKJustCommunityImpactVC: UIViewController {
    weak var flow: BKImpactFlow?
    weak var context: BKImpactContext?
    
    let navBar: BKNavBarView = .init(frame: .zero)

//    let navBar: UIView = .init(frame: .zero)
//
//    let beamLogoImageView: UIImageView = {
//        let view = UIImageView(frame: .zero)
//        view.backgroundColor = .clear
//        view.contentMode = .scaleAspectFit
//        view.clipsToBounds = true
//        let bundle = BeamKitContext.shared.bundle
//        let image = UIImage(named: "bkLogo", in: bundle, compatibleWith: nil)
//        view.image = image
//        return view
//    }()
//
//    let backArrow: BackArrowButton = .init(frame: .zero)
//
   let carousel: BKCommunityImpactVC
    
    init(context: BKImpactContext,
         flow: BKImpactFlow) {
        self.context = context
        self.flow = flow
        self.carousel = .init(context: context, flow: flow)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navBar.setNeedsLayout()
        navBar.layoutIfNeeded()
        if let logo = context?.impact?.logo,
            let url = URL(string: logo) {
            navBar.update(with: url)
        }
    }
        
    func setup() {
        view.isUserInteractionEnabled = true
        view.backgroundColor = .white
        view.addSubview(navBar.usingConstraints())
      //  navBar.addSubview(backArrow.usingConstraints())
       // backArrow.tint(.beamGray3)
        navBar.backButton.addTarget(self, action: #selector(navigateBack), for: .touchUpInside)
        //navBar.addSubview(beamLogoImageView.usingConstraints())
        addChild(carousel)
        view.addSubview(carousel.view.usingConstraints())
        carousel.didMove(toParent: self)
        setupConstraints()
    }
    
    func setupConstraints() {
        let views: Views = ["title": navBar,
                            "page": carousel.view
        ]
        
        let metrics: [String: Any] = ["topInset": 8,
                                      "headerHeight": UIView.beamDefaultNavBarHeight]
        
        let formats: [String] = ["V:|-topInset-[title(headerHeight)]-8-[page]|",
                                 "H:|[title]|",
                                 "H:|[page]|"
        ]
        let constraints: Constraints =
        NSLayoutConstraint.constraints(withFormats: formats,
                                       options: [],
                                       metrics: metrics,
                                       views: views)
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc
    func navigateBack() {
        dismiss(animated: true, completion: nil)
    }
}
