//
//  BKImpactFlow.swift
//  BeamKit
//
//  Created by ALEXANDRA SALVATORE on 11/14/19.
//  Copyright © 2019 Beam Impact. All rights reserved.
//

import UIKit


public class BKImpactFlow {
    
    var context: BKImpactContext {
        return BeamKitContext.shared.impactContext
    }
    
    fileprivate lazy var impactVC: BKImpactVC = .init(context: self.context,
                                                      flow: self)
    fileprivate lazy var communityVC: BKCommunityImpactVC = .init(context: self.context,
                                                                  flow: self)
    
    lazy var currentView: UIViewController = self.impactVC
    
    public func showFullImpact(from viewController: UIViewController) {
        context.loadCommunityImpact()
        let fullImpact = BKFullImpactVC(context: context, flow: self)
        viewController.present(fullImpact,
                               animated: true,
                               completion: nil)
    }
    
    func showJustCommunityImpact(from viewController: UIViewController) {
        context.loadCommunityImpact()

        let impact = BKJustCommunityImpactVC(context: context, flow: self)
        viewController.present(impact, animated: true, completion: nil)
    }
    
    func didDismissFullImpact() {
        currentView = impactVC
    }

    public init() {

    }
}

// Page Controls
extension BKImpactFlow {
    
    func vc(before: UIViewController) -> UIViewController? {
        return before == impactVC ? nil : impactVC
    }
    
    func vc(after: UIViewController) -> UIViewController? {
        return after == communityVC ? nil : communityVC
    }
    
    func selectImpact(from vc: UIPageViewController) {
        vc.setViewControllers([impactVC],
                              direction: .reverse,
                              animated: true) { [weak self] isFinished in
                                guard let `self` = self else { return }
                                self.currentView = self.impactVC
        }
    }
    
    func selectCommunity(from vc: UIPageViewController) {
        vc.setViewControllers([communityVC],
                              direction: .forward,
                              animated: true) { [weak self] isFinished in
                                guard let `self` = self else { return }
                                self.currentView = self.communityVC
        }
    }
}
