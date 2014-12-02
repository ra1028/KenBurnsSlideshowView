//
//  KenBurnsView.swift
//  KenBurnsSlideshowView-Demo
//
//  Created by Ryo Aoyama on 12/1/14.
//  Copyright (c) 2014 Ryo Aoyama. All rights reserved.
//

import UIKit

class KenBurnsView: UIView {
    
    enum kenBurnsImageViewZoomCourse: Int {
        case Random = 0
        case ToLowerLeft = 1
        case ToLowerRight = 2
        case ToUpperLeft = 3
        case ToUpperRight = 4
    }
    
    private enum kenBurnsImageViewStartZoomPoint {
        case LowerLeft
        case LowerRight
        case UpperLeft
        case UpperRight
    }
    
    private var imageView: KenBurnsImageView!
    var image: UIImage? {
        set {
            self.imageView.image = newValue
            if newValue != nil {
                self.setUpImageViewRect(newValue)
                self.setUpTransform()
                self.startMotion()
            }
        }
        get {
            return self.imageView.image
        }
    }
    var zoomCourse: kenBurnsImageViewZoomCourse = .Random
    var startZoomRate: CGFloat = 1.2
    var endZoomRate: CGFloat = 1.4
    var animationDuration: CGFloat = 15.0
    var padding: UIEdgeInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)
    var startTransform: CGAffineTransform = CGAffineTransformIdentity
    var endTransform: CGAffineTransform = CGAffineTransformIdentity
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureKenBurnsView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureKenBurnsView()
    }
    
    func startMotion() {
        let transX = CABasicAnimation(keyPath: "transform.translation.x")
        let transY = CABasicAnimation(keyPath: "transform.translation.y")
        transX.fromValue = self.startTransform.tx
        transX.toValue = self.endTransform.tx
        transY.fromValue = self.startTransform.ty
        transY.toValue = self.endTransform.ty
        
        let group = CAAnimationGroup()
        group.repeatCount = Float.infinity
        group.autoreverses = true
        group.duration = CFTimeInterval(self.animationDuration)
        group.removedOnCompletion = false
        group.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        group.animations = [transX, transY]
        
        self.imageView.layer.addAnimation(group, forKey: "kenBurnsAnimation")
    }
    
    private func configureKenBurnsView() {
        self.configureView()
    }
    
    private func configureView() {
        self.clipsToBounds = true
        self.autoresizesSubviews = true
        self.backgroundColor = UIColor.blackColor()
        
        self.imageView = KenBurnsImageView(frame: self.bounds)
        self.insertSubview(self.imageView, atIndex: 0)
    }
    
    private func setUpImageViewRect(image: UIImage!) {
        let size = image.size
        var longSide: CGFloat = max(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))
        var imageShortSide: CGFloat = min(size.width, size.height)
        var ratio: CGFloat = longSide / imageShortSide
        var resizedSize = CGSizeMake(size.width * ratio, size.height * ratio)
        self.imageView.transform = CGAffineTransformIdentity
        self.imageView.frame.size = resizedSize
    }
    
    private func setUpTransform() {
        if self.zoomCourse == .Random {
            let randomNum = Int(arc4random_uniform(4) + 1)
            self.zoomCourse = kenBurnsImageViewZoomCourse(rawValue: randomNum)!
        }
        self.setUpZoomRect(self.zoomCourse)
    }
    
    private func setUpZoomRect(course: kenBurnsImageViewZoomCourse) {
        var startRect = CGRectZero
        var endRect = CGRectZero
        
        switch course {
        case .ToLowerLeft:
            startRect = self.computeZoomRect(.UpperRight, zoomRate: self.startZoomRate)
            endRect = self.computeZoomRect(.LowerLeft, zoomRate: self.endZoomRate)
        case .ToLowerRight:
            startRect = self.computeZoomRect(.UpperLeft, zoomRate: self.startZoomRate)
            endRect = self.computeZoomRect(.LowerRight, zoomRate: self.endZoomRate)
        case .ToUpperLeft:
            startRect = self.computeZoomRect(.LowerRight, zoomRate: self.startZoomRate)
            endRect = self.computeZoomRect(.UpperLeft, zoomRate: self.endZoomRate)
        case .ToUpperRight:
            startRect = self.computeZoomRect(.LowerLeft, zoomRate: self.startZoomRate)
            endRect = self.computeZoomRect(.UpperRight, zoomRate: self.endZoomRate)
        default:
            break
        }
        
        self.startTransform = self.translatesAndScaledTransform(startRect, originalRect: self.imageView.bounds)
        self.endTransform = self.translatesAndScaledTransform(endRect, originalRect: self.imageView.bounds)
    }
    
    private func translatesAndScaledTransform(rect: CGRect, originalRect: CGRect) -> CGAffineTransform {
        let scaleRate = CGSizeMake(CGRectGetWidth(rect) / CGRectGetWidth(originalRect), CGRectGetHeight(rect) / CGRectGetHeight(originalRect))
        let offset = CGPointMake(CGRectGetMidX(rect) - CGRectGetMidX(originalRect), CGRectGetMidY(rect) - CGRectGetMidY(originalRect))
        let scale = CGAffineTransformMakeScale(scaleRate.width, scaleRate.height)
        let translates = CGAffineTransformMakeTranslation(offset.x, offset.y)
        return CGAffineTransformConcat(scale, translates)
    }
    
    private func computeZoomRect(zoomPoint: kenBurnsImageViewStartZoomPoint, zoomRate: CGFloat) -> CGRect {
        let imageViewSize = self.imageView.bounds.size
        var zoomSize = CGSizeMake(imageViewSize.width * zoomRate, imageViewSize.height * zoomRate)
        var point = CGPointZero
        
        var x = -(fabs(zoomSize.width - CGRectGetWidth(self.bounds)))
        var y = -(fabs(zoomSize.height - CGRectGetHeight(self.bounds)))
        
        switch zoomPoint {
        case .LowerLeft:
            point = CGPointMake(0, y)
        case .LowerRight:
            point = CGPointMake(x, y)
        case .UpperLeft:
            point = CGPointMake(0, 0)
        case .UpperRight:
            point = CGPointMake(x, 0)
        }
        
        var zoomRect: CGRect = CGRectMake(point.x, point.y, zoomSize.width, zoomSize.height)
        let pad = self.padding
        var insets = UIEdgeInsetsMake(-pad.top, -pad.left, -pad.bottom, -pad.right)
        
        return UIEdgeInsetsInsetRect(zoomRect, insets)
    }
}

class KenBurnsImageView: UIImageView {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        self.contentMode = .ScaleAspectFill
    }
    
    override var image: UIImage? {
        willSet {
            if self.image == nil {
                UIView.animateWithDuration(0.7, delay: 0, options: .BeginFromCurrentState | .CurveEaseInOut, animations: { () -> Void in
                    self.alpha = 0
                    self.alpha = 1.0
                }, completion: nil)
            }
        }
    }
}