//
//  KenBurnsView.swift
//  KenBurnsSlideshowView-Demo
//
//  Created by Ryo Aoyama on 12/1/14.
//  Copyright (c) 2014 Ryo Aoyama. All rights reserved.
//

import UIKit

class KenBurnsView: UIView {
    
    enum kenBurnsViewZoomCourse: Int {
        case Random = 0
        case ToLowerLeft = 1
        case ToLowerRight = 2
        case ToUpperLeft = 3
        case ToUpperRight = 4
    }
    
    enum kenBurnsViewState {
        case Animating
        case Invalid
        case Pausing
        case WholeImage
    }
    
    private enum kenBurnsViewStartZoomPoint {
        case LowerLeft
        case LowerRight
        case UpperLeft
        case UpperRight
    }
    
    /**
    *   properties
    **/
    
    private var imageView: UIImageView!
    private var wholeImageView: UIImageView!
    
    var image: UIImage? {
        set {
            self.imageView.transform = CGAffineTransformIdentity
            self.imageView.layer.removeAllAnimations()
            
            let oldImage = self.imageView.image
            self.imageView.image = newValue
            self.wholeImageView.image = newValue
            
            if oldImage == nil {
                let fade = { () -> Void in
                    self.imageView.alpha = 0
                    self.imageView.alpha = 1.0
                }
                UIView.animateWithDuration(0.5, delay: 0,
                    options: .CurveEaseInOut,
                    animations: fade, completion: nil)
            }
            
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
    
    override var bounds: CGRect {
        didSet {
            self.setUpImageViewRect(self.image)
            self.updateMotion()
        }
    }
    
    var zoomCourse: kenBurnsViewZoomCourse = .Random
    var startZoomRate: CGFloat = 1.2 {
        didSet {
            self.updateMotion()
        }
    }
    var endZoomRate: CGFloat = 1.4 {
        didSet {
            self.updateMotion()
        }
    }
    var animationDuration: CGFloat = 15.0 {
        didSet {
            self.updateMotion()
        }
    }
    var padding: UIEdgeInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0) {
        didSet {
            self.updateMotion()
        }
    }
    
    private (set) var state: kenBurnsViewState = .Invalid
    
    private var startTransform: CGAffineTransform = CGAffineTransformIdentity
    private var endTransform: CGAffineTransform = CGAffineTransformIdentity
    
    /**
    *   initialize methods
    **/
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    /**
    *   public methods
    **/
    
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
        
        self.imageView.layer.addAnimation(group, forKey: "kenBurnsEffects")
        self.state = .Animating
    }
    
    func updateMotion() {
        self.setUpTransform()
        self.startMotion()
    }
    
    func invalidateMotion() {
        self.imageView.layer.removeAllAnimations()
        self.imageView.transform = CGAffineTransformIdentity
        self.state = .Invalid
    }
    
    func pauseMotion() {
        if self.state == .Animating {
            let pausedTime: CFTimeInterval = self.imageView.layer .convertTime(CACurrentMediaTime(), fromLayer: nil)
            self.imageView.layer.speed = 0
            self.imageView.layer.timeOffset = pausedTime
            self.state = .Pausing
        }
    }
    
    func resumeMotion() {
        if self.state == .Pausing {
            let pausedTime: CFTimeInterval = self.imageView.layer.timeOffset
            self.imageView.layer.speed = 1.0
            self.imageView.layer.beginTime = 0
            self.imageView.layer.timeOffset = 0
            let intervalSincePaused: CFTimeInterval = self.imageView.layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
            self.imageView.layer.beginTime = intervalSincePaused
            self.state = .Animating
        }
    }
    
    func resumeMotionWithMomentDelay() {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.1)), dispatch_get_main_queue()) { () -> Void in
            self.resumeMotion()
        }
    }
    
    func showWholeImage() {
        let layer: CALayer? = self.imageView.layer.presentationLayer() as? CALayer
        if layer != nil {
            self.pauseMotion()
            
            self.wholeImageView.frame = layer!.frame
            self.wholeImageView.hidden = false
            self.imageView.hidden = true
            UIView.animateWithDuration(0, animations: { () -> Void in
                self.imageView.alpha = 0
                self.imageView.alpha = 1.0 // for kill fade animation
            })
            
            let size = self.bounds.size
            let imageSize = self.imageView.bounds.size
            let aspect = size.width / size.height
            let imageAspect = imageSize.width / imageSize.height
            let rate = imageAspect >= aspect ? size.width / imageSize.width : size.height / imageSize.height
            let resizedSize = CGSizeMake(imageSize.width * rate, imageSize.height * rate)
            
            let center = self.center
            let times = [0, 0.6, 0.8, 1]
            let timings = [CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear),
                CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut),
                CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)]
            
            var pos = CAKeyframeAnimation(keyPath: "position")
            pos.values = [NSValue(CGPoint: self.wholeImageView.center), NSValue(CGPoint: center), NSValue(CGPoint: center), NSValue(CGPoint: center)]
            pos.keyTimes = times
            pos.timingFunctions = timings
            
            var wholeSize = CAKeyframeAnimation(keyPath: "bounds.size")
            wholeSize.values = [NSValue(CGSize: self.wholeImageView.frame.size),
                NSValue(CGSize: resizedSize),
                NSValue(CGSize: CGSizeApplyAffineTransform(resizedSize, CGAffineTransformMakeScale(1.05, 1.05))),
                NSValue(CGSize: resizedSize)]
            wholeSize.keyTimes = times
            wholeSize.timingFunctions = timings
            
            let group = CAAnimationGroup()
            group.duration = 0.5
            group.removedOnCompletion = false
            group.fillMode = kCAFillModeForwards
            group.animations = [pos, wholeSize]
            
            self.wholeImageView.layer.addAnimation(group, forKey: "showWholeImage")
        }
    }
    
    func zoomImageAndRestartMotion() {
        let layer: CALayer? = self.imageView.layer.presentationLayer() as? CALayer
        
        if layer != nil {
            let pos = CABasicAnimation(keyPath: "position")
            pos.toValue = NSValue(CGPoint: CGPointMake(CGRectGetMinX(layer!.frame) + (CGRectGetWidth(layer!.frame) / 2), CGRectGetMinY(layer!.frame) + (CGRectGetHeight(layer!.frame) / 2)))
            
            let size = CABasicAnimation(keyPath: "bounds.size")
            size.toValue = NSValue(CGSize: layer!.frame.size)
            
            let group = CAAnimationGroup()
            group.duration = 0.25
            group.removedOnCompletion = false
            group.fillMode = kCAFillModeForwards
            group.animations = [pos, size]
            group.delegate = self
            
            self.wholeImageView.layer.addAnimation(group, forKey: "zoomImage")
        }
    }
    
    /**
    *   private methods
    **/
    
    private func configure() {
        self.configureView()
        self.configureNotification()
    }
    
    private func configureView() {
        self.clipsToBounds = true
        self.contentMode = .ScaleAspectFit
        self.backgroundColor = UIColor.blackColor()
        
        self.imageView = UIImageView()
        self.imageView.clipsToBounds = true
        self.imageView.contentMode = .ScaleAspectFill
        self.insertSubview(self.imageView, atIndex: 0)
        
        self.wholeImageView = UIImageView()
        self.wholeImageView.clipsToBounds = true
        self.wholeImageView.hidden = true
        self.insertSubview(self.wholeImageView, atIndex: 0)
    }
    
    private func configureNotification() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "pauseMotion",
            name: UIApplicationDidEnterBackgroundNotification,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "resumeMotionWithMomentDelay",
            name: UIApplicationDidBecomeActiveNotification,
            object: nil)
    }
    
    private func setUpImageViewRect(image: UIImage?) {
        if image != nil {
            let size = self.bounds.size
            let imageSize = image!.size
            if imageSize.width != 0 && imageSize.height != 0 {
                let aspect = size.width / size.height
                let imageAspect = imageSize.width / imageSize.height
                let rate = imageAspect >= aspect ? size.height / imageSize.height : size.width / imageSize.width
                var resizedSize = CGSizeMake(imageSize.width * rate, imageSize.height * rate)
                self.imageView.frame.size = resizedSize
            }
        }
    }
    
    private func setUpTransform() {
        if self.zoomCourse == .Random {
            let randomNum = Int(arc4random_uniform(4) + 1)
            self.zoomCourse = kenBurnsViewZoomCourse(rawValue: randomNum)!
        }
        self.setUpZoomRect(self.zoomCourse)
    }
    
    private func setUpZoomRect(course: kenBurnsViewZoomCourse) {
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
    
    private func computeZoomRect(zoomPoint: kenBurnsViewStartZoomPoint, zoomRate: CGFloat) -> CGRect {
        let size = self.bounds.size
        let imageViewSize = self.imageView.bounds.size
        let zoomSize = CGSizeMake(imageViewSize.width * zoomRate, imageViewSize.height * zoomRate)
        var point = CGPointZero
        
        var x = size.width - zoomSize.width
        var y = size.height - zoomSize.height
        
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
    
    /**
    *   delegate methods
    **/
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        if anim == self.wholeImageView?.layer.animationForKey("zoomImage") {
            self.imageView.hidden = false
            self.wholeImageView.hidden = true
            self.wholeImageView.frame = CGRectZero
            self.resumeMotion()
        }
    }
}