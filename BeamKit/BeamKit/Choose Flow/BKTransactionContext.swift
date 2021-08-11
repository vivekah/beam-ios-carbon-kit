//
//  TransactionContext.swift
//  BeamKit
//
//  Created by ALEXANDRA SALVATORE on 9/27/19.
//  Copyright © 2019 Beam Impact. All rights reserved.
//

import UIKit

class BKChooseNonprofitContext: NSObject {
    var currentTransaction: BKTransaction?
    
    func beginTransaction(at storeID: String,
                          for spend: CGFloat,
                          forceMatchView: Bool = false,
                          email: String? = nil,
                                _ completion: ((BKChooseViewType?, BeamError) -> Void)? = nil) {
        if let email = email {
            BeamKitContext.shared.registerUser(id: nil, info: ["BeamUserEmailKey": email]) {_,_ in
                self._beginTransaction(at: storeID, for: spend, forceMatchView: forceMatchView, completion)
            }
        }
        _beginTransaction(at: storeID, for: spend, forceMatchView: forceMatchView, completion)
    }
    
    func _beginTransaction(at storeID: String,
                          for spend: CGFloat,
                          forceMatchView: Bool = false,
                          _ completion: ((BKChooseViewType?, BeamError) -> Void)? = nil) {
        guard let _ = BeamKitContext.shared.getUserID() else {
            completion?(nil, .invalidUser)
            return
        }

        NonprofitAPI.getNonprofits(at: storeID) { [weak self] storeNonprofits, canMatch, error in
            guard let `self` = self,
                let store = storeNonprofits else {
                completion?(nil, error)
                return
            }
            
            let transaction = BKTransaction(storeNon: store, amount: spend)
            transaction.canMatch = canMatch
            if Network.shared.isStaging && forceMatchView {
                transaction.canMatch  = true
            }
            self.currentTransaction = transaction
            var viewType: BKChooseViewType = .fullScreen
            if let _ = transaction.storeNon.lastNonprofit {
                viewType = .widget
            }
            completion?(viewType, .none)
        }
    }
    
    func redeem(transaction: BKTransaction,
                _ completion: ((BKTransaction, BeamError) -> Void)? = nil) {
        guard let nonprofit = transaction.chosenNonprofit ?? transaction.storeNon.lastNonprofit,
            let store = transaction.storeNon.store else {
                completion?(transaction, .invalidConfiguration)
                return
        }
        let amt = transaction.amount
        let didMatch = transaction.canMatch ? transaction.userDidMatch : false

        NonprofitAPI.selectNonprofit(id: nonprofit.id,
                                     store: store.id,
                                     cart: amt,
                                     match: didMatch,
                                     matchAmount: transaction.matchAmount,
                                     position: 1)
        { id, error in
            transaction.id = id
            if error == .none {
                transaction.isRedeemed = true
            }
            completion?(transaction, error)
        }
    }
    
    func cancelTransaction(id: Int,
                           _ completion: ((BeamError) -> Void)? = nil) {
        NonprofitAPI.cancelTransaction(id: id, completion)
    }
}
