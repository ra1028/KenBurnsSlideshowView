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
    
    private var imageView: UIImageView!
    var image: UIImage? {
        set {
            let duration = self.imageView.image == nil ? 0.7 : 0
            self.imageView.image = newValue
            UIView.animateWithDuration(duration, delay: 0, options: .BeginFromCurrentState | .CurveEaseInOut, animations: { () -> Void in
                self.alpha = 0
                self.alpha = 1.0
                }, completion: nil)
            
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
        let current = CAShapeLayer()
        
        let transX = CABasicAnimation(keyPath: "transform.translation.x")
        transX.fromValue = self.startTransform.tx
        transX.toValue = self.endTransform.tx
        
        let transY = CABasicAnimation(keyPath: "transform.translation.y")
        transY.fromValue = self.startTransform.ty
        transY.toValue = self.endTransform.ty
        
        let scaleX = CABasicAnimation(keyPath: "transform.scale.x")
        scaleX.fromValue = self.startTransform.a
        scaleX.toValue = self.endTransform.a
        
        let scaleY = CABasicAnimation(keyPath: "transform.scale.y")
        scaleY.fromValue = self.startTransform.d
        scaleY.toValue = self.endTransform.d
        
        let group = CAAnimationGroup()
        group.repeatCount = Float.infinity
        group.autoreverses = true
        group.duration = CFTimeInterval(self.animationDuration)
        group.removedOnCompletion = false
        group.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        group.animations = [transX, transY, scaleX, scaleY]
        
        self.imageView.layer.addAnimation(group, forKey: "kenBurnsAnimation")
    }
    
    private func configureKenBurnsView() {
        self.configureView()
    }
    
    private func configureView() {
        self.clipsToBounds = true
        self.autoresizesSubviews = true
        self.backgroundColor = UIColor.blackColor()
        
        self.imageView = UIImageView(frame: self.bounds)
        self.imageView.contentMode = .ScaleAspectFill
        self.imageView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        self.insertSubview(self.imageView, atIndex: 0)
    }
    
    private func setUpImageViewRect(image: UIImage!) {
        let size = image.size
        var longSide: CGFloat = max(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))
        var imageLongSide: CGFloat = max(size.width, size.height)
        var ratio: CGFloat = longSide / imageLongSide
        var resizedSize = CGSizeMake(size.width * ratio, size.height * ratio)
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
        
        self.startTransform = self.translatesAndScaledTransform(startRect)
        self.endTransform = self.translatesAndScaledTransform(endRect)
    }
    
    private func translatesAndScaledTransform(rect: CGRect) -> CGAffineTransform {
        let imageViewSize = self.imageView.bounds.size
        
        let scale = CGAffineTransformMakeScale(CGRectGetWidth(rect) / imageViewSize.width, CGRectGetHeight(rect) / imageViewSize.height)
        let translation = CGAffineTransformMakeTranslation(CGRectGetMidX(rect) - CGRectGetMidX(self.imageView.bounds), CGRectGetMidY(rect) - CGRectGetMidY(self.imageView.bounds))
        return CGAffineTransformConcat(scale, translation)
    }
    
    private func computeZoomRect(zoomPoint: kenBurnsImageViewStartZoomPoint, zoomRate: CGFloat) -> CGRect {
        let imageViewSize = self.imageView.bounds.size
        let zoomSize = CGSizeMake(imageViewSize.width * zoomRate, imageViewSize.height * zoomRate)
        var point = CGPointZero
        
        var x = -fabs(zoomSize.width - CGRectGetWidth(self.bounds))
        var y = -fabs(zoomSize.height - CGRectGetHeight(self.bounds))
        
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