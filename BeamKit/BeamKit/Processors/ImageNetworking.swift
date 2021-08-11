//
//  ImageNetworking.swift
//  BeamKit
//
//  Created by ALEXANDRA SALVATORE on 9/25/19.
//  Copyright © 2019 Beam Impact. All rights reserved.
//

//import Alamofire
import UIKit

@objc public protocol AFImageCacheProtocol: class{
    func cachedImageForRequest(_ request:URLRequest) -> UIImage?
    func cacheImage(_ image:UIImage, forRequest request:URLRequest);
}

extension UIImageView {
    fileprivate struct AssociatedKeys {
        static var SharedImageCache = "SharedImageCache"
        static var RequestImageOperation = "RequestImageOperation"
        static var URLRequestImage = "UrlRequestImage"
    }
    
    public class func setSharedImageCache(_ cache:AFImageCacheProtocol?) {
        objc_setAssociatedObject(self, &AssociatedKeys.SharedImageCache, cache, .OBJC_ASSOCIATION_RETAIN)
    }
    
    public class func BKSharedImageCache() -> AFImageCacheProtocol {
        struct Static {
            static var BKdefaultImageCache: BKImageCache? = {
                //                NotificationCenter.default.addObserver(forName: .didReceiveMemor, object: nil, queue: OperationQueue.main) { (NSNotification) -> Void in
                //                    Static.defaultImageCache!.removeAllObjects()
                //                }
                return BKImageCache()
            }()
        }
        
        return objc_getAssociatedObject(self, &AssociatedKeys.SharedImageCache) as? AFImageCacheProtocol ?? Static.BKdefaultImageCache!
    }
    
    fileprivate class func af_sharedImageRequestOperationQueue() -> OperationQueue {
        struct Static {
            static var queue: OperationQueue? = {
                let queue = OperationQueue()
                queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
                return queue
            }()
        }
        
        return Static.queue!
    }
    
    fileprivate var af_requestImageOperation:(operation:Operation?, request: URLRequest?) {
        get {
            let operation:Operation? = objc_getAssociatedObject(self, &AssociatedKeys.RequestImageOperation) as? Operation
            let request:URLRequest? = objc_getAssociatedObject(self, &AssociatedKeys.URLRequestImage) as? URLRequest
            return (operation, request)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.RequestImageOperation, newValue.operation, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(self, &AssociatedKeys.URLRequestImage, newValue.request, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func bkSetImageWithUrl(_ url: URL, placeHolderImage: UIImage? = nil, priority: Operation.QueuePriority = .normal) {
        let request:NSMutableURLRequest = NSMutableURLRequest(url: url)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        self.bkSetImageWithUrlRequest(request as URLRequest, placeHolderImage: placeHolderImage, success: nil, failure: nil)
    }
    
    public func bkSetImageWithUrl(_ url:URL,
                                placeHolderImage:UIImage? = nil,
                                priority: Operation.QueuePriority = .normal,
                                completion: ((UIImage?) -> Void)? = nil) {
        let request: NSMutableURLRequest = NSMutableURLRequest(url: url)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        let onSuccess: (URLRequest?, URLResponse?, UIImage, Bool) -> Void = { _, _, image, _ in
            completion?(image)
        }
        let onFailure: (URLRequest?, URLResponse?, NSError) -> Void = { _, _, _ in
            completion?( nil)
        }
        self.bkSetImageWithUrlRequest(request as URLRequest,
                                    placeHolderImage: placeHolderImage,
                                    priority: priority,
                                    success: onSuccess,
                                    failure: onFailure)
    }
    
    public func bkSetImageWithUrlRequest(_ request:URLRequest,
                                       placeHolderImage:UIImage? = nil,
                                       priority: Operation.QueuePriority = .normal,
                                       success:((_ request:URLRequest?, _ response:URLResponse?, _ image:UIImage, _ fromCache:Bool) -> Void)?,
                                       failure:((_ request:URLRequest?, _ response:URLResponse?, _ error:NSError) -> Void)?)
    {
        self.bkcancelImageRequestOperation()
        
        if let cachedImage = UIImageView.BKSharedImageCache().cachedImageForRequest(request) {
            DispatchQueue.main.async {
                if success != nil {
                    self.image = cachedImage
                    success!(nil, nil, cachedImage, true)
                }
                else {
                    self.image = cachedImage
                }
            }
            return
        }
        
        if placeHolderImage != nil {
            self.image = placeHolderImage
        }
        
        self.af_requestImageOperation = (BlockOperation(block: { () -> Void in
            var response:URLResponse?
            do {
                let data = try NSURLConnection.sendSynchronousRequest(request, returning: &response)
                DispatchQueue.main.async(execute: { () -> Void in
                    if request.url! == self.af_requestImageOperation.request?.url {
                        let image: UIImage? = UIImage(data: data)
                        if image != nil {
                            if success != nil {
                                self.image = image
                                success!(request, response, image!, false)
                            }
                            else {
                                self.image = image
                            }
                            UIImageView.BKSharedImageCache().cacheImage(image!, forRequest: request)
                        }
                        
                        self.af_requestImageOperation = (nil, nil)
                    }
                })
            }
            catch {
                if failure != nil {
                    failure!(request, response, error as NSError)
                }
            }
        }), request: request)
        if priority != .normal {
            self.af_requestImageOperation.operation?.queuePriority = priority
        }
        UIImageView.af_sharedImageRequestOperationQueue().addOperation(self.af_requestImageOperation.operation!)
    }
    
    func bkcancelImageRequestOperation() {
        self.af_requestImageOperation.operation?.cancel()
        self.af_requestImageOperation = (nil, nil)
    }
}

func BKImageCacheKeyFromURLRequest(_ request:URLRequest) -> String {
    return request.url!.absoluteString
}

class BKImageCache: NSCache<AnyObject, AnyObject>, AFImageCacheProtocol {
    func cachedImageForRequest(_ request: URLRequest) -> UIImage? {
        switch request.cachePolicy {
        case NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData,
             NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData:
            return nil
        default:
            break
        }
        
        return self.object(forKey: BKImageCacheKeyFromURLRequest(request) as AnyObject) as? UIImage
    }
    
    func cacheImage(_ image: UIImage, forRequest request: URLRequest) {
        self.setObject(image, forKey: BKImageCacheKeyFromURLRequest(request) as AnyObject)
    }
}

