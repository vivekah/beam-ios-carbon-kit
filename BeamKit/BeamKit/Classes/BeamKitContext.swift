//
//  BeamKitContext.swift
//  BeamKit
//
//  Created by ALEXANDRA SALVATORE on 9/25/19.
//  Copyright © 2019 Beam Impact. All rights reserved.
//

import UIKit

public enum BKEnvironment {
    case production
    case staging
}

extension Notification.Name {
    static let _userRegistrationEvent = Notification.Name("bk_user_registration_event")
}


class BeamKitContext {
    static let shared = BeamKitContext()
    
    private(set) var userID: String? = nil 
    lazy var userAPI: BeamKitUserAPI = .init()
    lazy var nonprofits: [BKNonprofit] = .init() // todo figure ordering
    lazy var chooseContext: BKChooseNonprofitContext = .init()
    lazy var chooseFlow: BKChooseFlow = .init()
    lazy var impactContext: BKImpactContext = .init()
    let bundle = Bundle(for: BKManager.self)

    var token: String? = nil
    
    func getUserID() -> String? {
        if userID != nil {
            return userID
        } else if let id = UserDefaults.standard.string(forKey: "beam_user_id") {
            return id
        }
        return nil
    }
    
    func register(with key: String, environment: BKEnvironment) {
        self.token = key
        Network.shared.environment = environment
        impactContext.loadImpact()
    }
    
    func registerUser(id: String?,
                      info: JSON?,
                      _ completion: ((String?, BeamError) -> Void)? = nil) {
        if let id = id {
            //TODO: test if need to clear out user/ data
            userID = id
            self.save(id: id)
            BKLog.debug("Beam Registered User with id \(id)")
            completion?(userID, .none)
            return
        }
            
        userAPI.registerUser(options: info) { [weak self] newUserID, error in
            defer {
                completion?(newUserID, error)
            }
            guard let `self` = self else { return }
            self.userID = newUserID
            self.save(id: newUserID)
        }
    }
    
    func deregisterUser(_ completion: ((BeamError) -> Void)? = nil) {
        userID = nil
        clear()
        NotificationCenter.default.post(name: ._userRegistrationEvent,
                                        object: self,
                                        userInfo: nil)
        completion?(.none)
    }

    //Returns Transaction ID
    func complete(_ transaction: BKTransaction,
                  _ completion: ((Int?, BeamError) -> Void)? = nil) {
        chooseFlow.complete(transaction, completion)
    }
    
    func save(id: String?) {
        guard let id = id else { return }
        UserDefaults.standard.set(id, forKey: "beam_user_id")
    }
    
    func clear() {
        UserDefaults.standard.removeObject(forKey: "beam_user_id")
    }

}
