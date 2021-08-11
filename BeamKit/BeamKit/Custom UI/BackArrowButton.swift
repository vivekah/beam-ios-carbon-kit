//
//  BackArrowButton.swift
//  Beam
//
//  Created by ALEXANDRA SALVATORE on 11/29/18.
//  Copyright © 2018 Beam Impact. All rights reserved.
//

import UIKit

class BKBackButton: UIButton {
    
    static var arrowImage: UIImage? = {
        let bundle = BeamKitContext.shared.bundle
        var image = UIImage(named: "down-arrow", in: bundle, compatibleWith: nil)
        return image
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setup()
    }
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    init(tint: UIColor) {
        super.init(frame: .zero)
        setup()
        self.tint(tint)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func tint(_ color: UIColor) {
        setImage(BKBackButton._backImage?.maskWithColor(color: color), for: .normal)
    }

    func setup() {
        imageView?.image = BKBackButton._backImage
        imageView?.backgroundColor = .clear
        imageView?.contentMode = .scaleAspectFit
        imageView?.clipsToBounds = true
        contentEdgeInsets = UIEdgeInsets(top: 10, left: 8, bottom: 5, right: 8)
        tint(BKBackButton._tint)
    }
    
    static var _backImage: UIImage? = BKBackButton.arrowImage
    static var _tint: UIColor = .beamGray3

    internal class var backImage: UIImage? {
        return _backImage
    }
    
    public class func register(backImage: UIImage, tint: UIColor) {
        _backImage = backImage
        _tint = tint
    }
}

extension UIImage {
    
    func maskWithColor(color: UIColor) -> UIImage? {
        let maskImage = cgImage!
        
        let width = size.width
        let height = size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        
        context.clip(to: bounds, mask: maskImage)
        context.setFillColor(color.cgColor)
        context.fill(bounds)
        
        if let cgImage = context.makeImage() {
            let coloredImage = UIImage(cgImage: cgImage)
            return coloredImage
        } else {
            return nil
        }
    }
}
