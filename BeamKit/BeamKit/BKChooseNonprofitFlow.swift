//
//  ChooseNonprofitFlow.swift
//  BeamKit
//
//  Created by ALEXANDRA SALVATORE on 9/26/19.
//  Copyright © 2019 Beam Impact. All rights reserved.
//

import Foundation
import UIKit

public enum BKChooseViewType {
    case fullScreen
    case widget
}

class BKChooseFlow {
    
    var context: BKChooseNonprofitContext {
        return BeamKitContext.shared.chooseContext
    }
    var chooseVC: BKChooseVC?
    
    func showChooseNonprofitVC(from presentingVC: UIViewController) {
        guard let trans = context.currentTransaction else {
            //todo something here
            return
        }
        chooseVC = BKChooseVC(with: trans)
        guard let vc = chooseVC else { return } // todo add error
       // vc.modalPresentationStyle = .fullScreen
        presentingVC.present(vc, animated: true)
    }
    
    func navigateBack(from vc: UIViewController, completion: (() -> Void)? = nil) {
        vc.dismiss(animated: true, completion: completion)
    }
    
    func redeem(_ transaction: BKTransaction,
                nonprofit: BKNonprofit,
                from vc: UIViewController,
                completion: (() -> Void)? = nil) {
        transaction.chosenNonprofit = nonprofit
        context.currentTransaction = transaction
        DispatchQueue.main.async {
            self.navigateBack(from: vc, completion: completion)
        }
    }
    
    func complete(_ transaction: BKTransaction, _ completion: ((Int?, BeamError) -> Void)? = nil) {
        context.redeem(transaction: transaction) { returnedTrans, error in
          //  guard let `self` = self else { return }

            completion?(returnedTrans.id, error)
        }
    }
    
    lazy var testTransaction: BKTransaction = {
        let non1 = BKNonprofit(cause: "Sustainability",
        id: 1,
        description: "test description",
        image: "https://beam-impact.s3.amazonaws.com/ngo_image/Grand_St_Settlement.jpg",
        impactDescription: "tst impact des",
        name: "grand street",
        targetDonations: 10,
        totalDonations: 8)
        let non2 = BKNonprofit(cause: "Culture",
        id: 2,
        description: "test description",
        image: "https://beam-impact.s3.amazonaws.com/ngo_image/Grand_St_Settlement.jpg",
        impactDescription: "tst impact des",
        name: "grand street",
        targetDonations: 10,
        totalDonations: 8)
        
        let non3 = BKNonprofit(cause: "Talent",
        id: 3,
        description: "test description",
        image: "https://beam-impact.s3.amazonaws.com/ngo_image/Grand_St_Settlement.jpg",
        impactDescription: "tst impact des",
        name: "grand street",
        targetDonations: 10,
        totalDonations: 8)
        
        let store = BKStore(id: "1",
        image: "https://beam-impact.s3.amazonaws.com/chains/img/logo_think.jpeg",
        name: "Think Test")
        store.percent = 0.01
        
        let storeNon = BKStoreNonprofitsModel()
        storeNon.nonprofits = [non1, non2, non3]
        storeNon.store = store
        
        let transaction = BKTransaction(storeNon: storeNon, amount: 10)
        
        return transaction
    }()
}
