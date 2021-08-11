//
//  Network.swift
//  beam-ios-sdk
//
//  Created by ALEXANDRA SALVATORE on 9/25/19.
//  Copyright © 2019 Beam Impact. All rights reserved.
//

import UIKit
//import Alamofire

typealias JSON = [String: Any]
typealias ErrorMessage = String

extension HTTPMethod {
    var encoding: ParameterEncoding {
        if case .get = self {
            return URLEncoding.default
        }
        return JSONEncoding.default
    }
}

enum ErrorType {
    case invalidURL
    case failedToEncode
    case failWithStatus(Int, String?, JSON?)
    case noNetwork
    case requestCancelled
    
    var errorMessage: String {
        switch self {
        case .noNetwork:
            return "Network not available"
        case .failedToEncode, .invalidURL:
            return "Something went wrong"
        case .requestCancelled:
            return "Something went wrong. Please try again."
        case let .failWithStatus(_, msg, _):
            return msg ?? "Something went wrong"
        }
    }
}

enum ResponseType {
    case success
    case failure(ErrorType)
}

typealias ErrorHandler = (ErrorType) -> Void
typealias NetworkCompletionHandler = (Data?, URLResponse?, Error?) -> Void

class Network {
    static let shared: Network = .init()
    var environment: BKEnvironment = .staging
    
    var isStaging: Bool {
        return environment == .staging
    }
    
    lazy var baseURL: String = {
        switch self.environment {
        case .staging:
            return "https://staging.sdk.beamimpact.com/api/v1/"
        case .production:
            return "https://prod.sdk.beamimpact.com/api/v1/"
        }
    }()
    
    fileprivate func isSuccessCode(_ statusCode: Int) -> Bool {
        return statusCode >= 200 && statusCode < 300
    }
    
//    var isReachable: Bool {
//        if let manager = reachabilityManager {
//            return manager.isReachable
//        }
//        return false
//    }
    
    var headers: [String: String] {
        
        var headers:[String: String] = ["Content-Type": "application/json"]
        
        if let token = BeamKitContext.shared.token {
            headers["Authorization"] = "Api-Key " + token
        }
        return headers
    }
}

extension Network {
    
    @discardableResult
    func get(urlPath: String,
             successJSONHandler: @escaping (JSON?) -> Void,
             errorHandler: @escaping ErrorHandler) -> URLSessionDataTask? {
        
        return startTask(method: .get,
                         urlPath: urlPath,
                         successHandler: successJSONHandler,
                         errorHandler: errorHandler)
    }
    
    @discardableResult
    func post(urlPath: String,
              body: JSON? = nil,
              successJSONHandler: @escaping (JSON?) -> Void,
              errorHandler: @escaping ErrorHandler) -> URLSessionDataTask? {
        
        return startTask(method: .post,
                         urlPath: urlPath,
                         body: body,
                         successHandler: successJSONHandler,
                         errorHandler: errorHandler)
    }
    
    @discardableResult
    func delete(urlPath: String,
                body: JSON? = nil,
                successJSONHandler: @escaping (JSON?) -> Void,
                errorHandler: @escaping ErrorHandler) -> URLSessionDataTask? {
        
        return startTask(method: .delete,
                         urlPath: urlPath,
                         body: body,
                         successHandler: successJSONHandler,
                         errorHandler: errorHandler)
    }
    
    @discardableResult
    func patch(urlPath: String,
                body: JSON? = nil,
                successJSONHandler: @escaping (JSON?) -> Void,
                errorHandler: @escaping ErrorHandler) -> URLSessionDataTask? {
        
        return startTask(method: .patch,
                         urlPath: urlPath,
                         successHandler: successJSONHandler,
                         errorHandler: errorHandler)
    }
    
    
    func startTask(method: HTTPMethod,
                   urlPath: String,
                   body: JSON? = [:],
                   successHandler: @escaping (JSON?) -> Void,
                   errorHandler: @escaping ErrorHandler) -> URLSessionDataTask? {
        let completionHandler: NetworkCompletionHandler = getHandler(successHandler: successHandler,
                                                                     errorHandler: errorHandler)
        
//        guard isReachable else {
//            errorHandler(.noNetwork)
//            return nil
//        }
        
        guard let url = URL(string: baseURL + urlPath) else {
            errorHandler(.invalidURL)
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        do {
            let encodedRequest = try method.encoding.encode(request, with: body)
            let task = URLSession.shared.dataTask(with: encodedRequest,
                                                  completionHandler: completionHandler)
            task.resume()
            return task
        } catch {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            BKLog.error("Failed To Encode Request")
            errorHandler(.failedToEncode)
        }
        
        return nil
    }
    
    func getHandler(successHandler: @escaping (JSON?) -> Void,
                    errorHandler: @escaping ErrorHandler) -> NetworkCompletionHandler {
        let completionHandler: NetworkCompletionHandler = { [weak self] (data, urlResponse, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            guard let `self` = self else { return }
            
            guard let response = urlResponse as? HTTPURLResponse else {
                BKLog.error("Failed to Encode URL Response")
                errorHandler(.failedToEncode)
                return
            }
            
            print(response)
            
            if let error = error {
                print(error.localizedDescription)
                if error.localizedDescription == "cancelled" {
                    BKLog.info("Request was cancelled")
                    errorHandler(.requestCancelled)
                } else {
                    BKLog.error("Failed with status \(response.statusCode)")
                    errorHandler(.failWithStatus(response.statusCode, error.localizedDescription, nil))
                }
                return
            }
            
            guard let data = data else {
                BKLog.error("Unable to parse the response")
                errorHandler(.failedToEncode)
                return
            }
            do {
                var responseData = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                if let data = responseData as? [Any] {
                    responseData = ["data": data]
                }
                let blah = responseData as? JSON
                if self.isSuccessCode(response.statusCode) {
                    successHandler(blah)
                } else {
                    BKLog.error("Failed with status \(response.statusCode)")
                    errorHandler(.failWithStatus(response.statusCode, nil, blah))
                }
                return
            }
            catch {
                if self.isSuccessCode(response.statusCode) {
                    successHandler(nil)
                } else {
                    errorHandler(.failedToEncode)
                }
                return
            }
        }
        return completionHandler
    }
}
