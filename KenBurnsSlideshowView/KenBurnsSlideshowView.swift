//
//  KenBurnsSlideshowView.swift
//  KenBurnsSlideshowView-Demo
//
//  Created by Ryo Aoyama on 12/12/14.
//  Copyright (c) 2014 Ryo Aoyama. All rights reserved.
//

import UIKit

@objc protocol KenBurnsSlideshowViewDelegate: NSObjectProtocol {
    optional func kenBurnsSlideshowView(slideshowView: KenBurnsSlideshowView, downloadUrl url: NSURL, completion: (UIImage -> ()))
    optional func kenBurnsSlideshowView(slideshowView: KenBurnsSlideshowView, willShowKenBurnsView view: KenBurnsView)
}

class KenBurnsSlideshowView: UIView, UIGestureRecognizerDelegate, KenBurnsInfinitePageViewDelegate {
    override var bounds: CGRect {
        didSet {
            for kenburnsView in self.kenBurnsViews {
                kenburnsView.frame.size = self.bounds.size
            }
        }
    }
    
    private var kenBurnsViews: [KenBurnsView]! = []
    private var titleViews: [KenBurnsSlideshowTitleView]! = []
    private var scrollView: KenBurnsInfinitePageView!
    private var coverImageView: UIImageView! = UIImageView()
    private var darkCoverView: UIView = UIView()
    private var slideshowTimer: NSTimer?
    private var timerInterval: NSTimeInterval = 10.0
    private var timerFiredDate: NSDate = NSDate()
    private var currentIndex: Int = 0
    
    var slideshowDuration: CGFloat = 10.0 {
        didSet {
            self.timerInterval = NSTimeInterval(self.slideshowDuration)
            self.configureTimer()
        }
    }
    
    var kenBurnsEffectDuration: CGFloat! = 15.0 {
        didSet {
            for kenBurnsView in self.kenBurnsViews {
                kenBurnsView.kenBurnsEffectDuration = self.kenBurnsEffectDuration
            }
        }
    }
    
    var coverImage: UIImage? {
        didSet {
            self.coverImageView.image = self.coverImage
        }
    }
    
    private (set) var isShowingCoverImage: Bool = false
    
    var coverImageFadeDuration: CGFloat! = 0.5
    
    var titleViewClass: KenBurnsSlideshowTitleView.Type! = KenBurnsSlideshowTitleView.self {
        didSet {
            for titleView in self.titleViews {
                titleView.removeFromSuperview()
            }
            
            let titleViewClass = self.titleViewClass.self
            self.titleViews = []
            for i in 0..<3 {
                let page: KenBurnsSlideshowTitleView = titleViewClass(frame: self.scrollView.bounds)
                self.titleViews.append(page)
            }
            self.scrollView.pageItems = self.titleViews
        }
    }
    
    var slideshowEnabled: Bool = true {
        didSet {
            if self.slideshowEnabled {
                self.configureTimer()
            }else {
                self.invalidateSlideshowTimer()
            }
        }
    }
    
    var images: [KenBurnsSlideshowImageObject]! = [] {
        didSet {
            self.updateKenBurnsView()
            self.layoutKenburnsViews()
        }
    }
    
    private var appendImages: [KenBurnsSlideshowImageObject]! = []
    
    var allImages: [KenBurnsSlideshowImageObject]! {
        let allImage = self.images + self.appendImages
        return allImage
    }
    
    weak var delegate: KenBurnsSlideshowViewDelegate?
    
    var previousKenBurnsView: KenBurnsView {
        return self.kenBurnsViews[2]
    }
    var currentKenBurnsView: KenBurnsView {
        return self.kenBurnsViews[0]
    }
    var nextKenBurnsView: KenBurnsView {
        return self.kenBurnsViews[1]
    }
    
    var previousTitleView: KenBurnsSlideshowTitleView {
        return self.titleViews[2]
    }
    var currentTitleView: KenBurnsSlideshowTitleView {
        return self.titleViews[0]
    }
    var nextTitleView: KenBurnsSlideshowTitleView {
        return self.titleViews[1]
    }
    
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
        self.pauseSlideshowTimer()
    }
    
    private func configure() {
        self.configureViews()
        self.configureObserver()
        self.configureTimer()
    }
    
    private func configureObserver() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "pauseCurrentKenBurnsMotion",
            name: UIApplicationDidEnterBackgroundNotification,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "resumeCurrentKenBurnsMotion",
            name: UIApplicationDidBecomeActiveNotification,
            object: nil)
    }
    
    private func configureViews() {
        self.backgroundColor = UIColor.blackColor()
        self.clipsToBounds = true
        
        self.timerInterval = NSTimeInterval(self.slideshowDuration)
        
        self.coverImageView.frame = self.bounds
        self.coverImageView.backgroundColor = UIColor.blackColor()
        self.coverImageView.userInteractionEnabled = true
        self.coverImageView.contentMode = .ScaleAspectFill
        self.coverImageView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        self.coverImageView.alpha = 0
        self.insertSubview(self.coverImageView, atIndex: 0)
        
        self.darkCoverView.frame = self.bounds
        self.darkCoverView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        self.darkCoverView.alpha = 0
        self.darkCoverView.userInteractionEnabled = false
        self.darkCoverView.backgroundColor = UIColor.blackColor()
        self.insertSubview(self.darkCoverView, atIndex: 0)
        
        self.scrollView = KenBurnsInfinitePageView(frame: self.bounds)
        self.scrollView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        self.scrollView.pagingEnabled = true
        self.scrollView.pageViewDelegate = self
        self.insertSubview(self.scrollView, atIndex: 0)
        
        var longPress = UILongPressGestureRecognizer(target: self, action: "longPressHandler:")
        longPress.minimumPressDuration = 0.25
        longPress.delegate = self
        self.addGestureRecognizer(longPress)
        
        for i in 0..<3 {
            let titleViewClass = self.titleViewClass.self
            let titleView = titleViewClass(frame: self.scrollView.bounds)
            self.titleViews.append(titleView)
        }
        self.scrollView.pageItems = self.titleViews
        
        for i in 0..<3 {
            let kenBurns = KenBurnsView(frame: self.bounds)
            NSNotificationCenter.defaultCenter().removeObserver(kenBurns)
            kenBurns.kenBurnsEffectDuration = self.kenBurnsEffectDuration
            self.kenBurnsViews.append(kenBurns)
        }
        
        self.updateKenBurnsView()
        self.layoutKenburnsViews()
        dispatch_async(dispatch_get_main_queue(), { () -> Void in self.pauseBothSideKenBurnsView() })
    }
    
    private func configureTimer() {
        self.slideshowTimer?.invalidate()
        self.slideshowTimer = nil
        if self.slideshowEnabled {
            self.slideshowTimer = NSTimer.scheduledTimerWithTimeInterval(self.timerInterval, target: self, selector: "showNextKenBurnsView", userInfo: nil, repeats: true)
            
            self.timerFiredDate = NSDate()
        }
    }
    
    func showCoverImage(#animated: Bool) {
        let duration = NSTimeInterval(animated ? self.coverImageFadeDuration : 0)
        UIView.animateWithDuration(duration, delay: 0, options: .BeginFromCurrentState, animations: { () -> Void in
            self.coverImageView.alpha = 1.0
        }, { (finished) -> Void in
            self.isShowingCoverImage = true
            self.currentKenBurnsView.pauseMotion()
            self.invalidateSlideshowTimer()
        })
    }
    
    func hideCoverImage(#animated: Bool) {
        let duration = NSTimeInterval(animated ? self.coverImageFadeDuration : 0)
        self.currentKenBurnsView.resumeMotion()
        self.configureTimer()
        UIView.animateWithDuration(duration, delay: 0, options: .BeginFromCurrentState, animations: { () -> Void in
            self.coverImageView.alpha = 0
            }, { (finished) -> Void in
                self.isShowingCoverImage = false
        })
    }
    
    
    func addImage(#image: KenBurnsSlideshowImageObject) {
        self.appendImages.append(image)
        
        if self.currentIndex == self.getLastIndex() - 1 {
            if self.allImages.count >= 2 {
                self.asynchronousSetImage(kenBurnsView: self.nextKenBurnsView, image: self.allImages[self.getLastIndex()])
                self.nextTitleView.title = self.allImages[self.getNextIndex()].title
                self.nextTitleView.subTitle = self.allImages[self.getNextIndex()].subTitle
                
                if self.allImages.count == 2 {
                    self.asynchronousSetImage(kenBurnsView: self.previousKenBurnsView, image: self.allImages[self.getLastIndex()])
                    self.previousTitleView.title = self.allImages[self.getPreviousIndex()].title
                    self.previousTitleView.subTitle = self.allImages[self.getPreviousIndex()].subTitle
                }
                self.killKenBurnsViewFadeAnimation(kenBurnsView: self.previousKenBurnsView)
                self.killKenBurnsViewFadeAnimation(kenBurnsView: self.nextKenBurnsView)
            }
        }
        
        if self.allImages.count >= 2 {
            self.scrollView.scrollEnabled = true
        }else if self.allImages.count == 1 {
            self.updateKenBurnsView()
        }
    }
    
    func removeAllAddedImage() {
        self.appendImages = []
        self.updateKenBurnsView()
    }
    
    func showNextKenBurnsView() {
        self.previousKenBurnsView.alpha = 0
        
        self.scrollView.scrollToNextPage()
        
        self.timerInterval = NSTimeInterval(self.slideshowDuration)
        self.configureTimer()
    }
    
    
    func pauseCurrentKenBurnsMotion() {
        self.currentKenBurnsView.pauseMotion()
        self.pauseSlideshowTimer()
    }
    
    func resumeCurrentKenBurnsMotion() {
        self.currentKenBurnsView.resumeMotionWithMomentDelay()
        self.resumeSlideshowTimer()
    }
    
    private func pauseSlideshowTimer() {
        if self.slideshowTimer != nil {
            if self.slideshowTimer!.valid {
                self.slideshowTimer!.invalidate()
                self.slideshowTimer = nil
                self.timerInterval = NSTimeInterval(self.slideshowDuration) - NSDate().timeIntervalSinceDate(self.timerFiredDate)
                if self.timerInterval <= 0 {
                    self.timerInterval = NSTimeInterval(self.slideshowDuration)
                }
            }
        }
    }
    
    private func resumeSlideshowTimer() {
        self.configureTimer()
    }
    
    private func invalidateSlideshowTimer() {
        self.slideshowTimer?.invalidate()
        self.slideshowTimer = nil
        self.timerInterval = NSTimeInterval(self.slideshowDuration)
    }
    
    private func updateKenBurnsView() {
        self.currentIndex = 0
        self.updateKenBurnsViewImage()
        self.updateKenBurnsViewTitle()
    }
    
    private func asynchronousSetImage(kenBurnsView view: KenBurnsView, image: KenBurnsSlideshowImageObject) {
        if image.image != nil {
            view.image = image.image
        }else if image.imageUrl != nil {
            view.image = nil
            self.delegate?.kenBurnsSlideshowView?(self, downloadUrl: image.imageUrl!, completion: { (downloadedImage: UIImage) -> () in
                if view.image == nil {
                    view.image = downloadedImage
                }
            })
        }else {
            view.image = nil
        }
    }
    
    private func killKenBurnsViewFadeAnimation(kenBurnsView view: KenBurnsView) {
        view.resumeMotion()
        view.layer.removeAnimationForKey("fade")
        view.pauseMotion()
    }
    
    private func updateKenBurnsViewImage() {
        var slideEnabled = true
        
        if self.allImages.count >= 2 {
            self.delegate?.kenBurnsSlideshowView?(self, willShowKenBurnsView: self.currentKenBurnsView)
            self.delegate?.kenBurnsSlideshowView?(self, willShowKenBurnsView: self.previousKenBurnsView)
            self.delegate?.kenBurnsSlideshowView?(self, willShowKenBurnsView: self.nextKenBurnsView)
            self.asynchronousSetImage(kenBurnsView: self.currentKenBurnsView, image: self.allImages[0])
            self.asynchronousSetImage(kenBurnsView: self.nextKenBurnsView, image: self.allImages[1])
            self.asynchronousSetImage(kenBurnsView: self.previousKenBurnsView, image: self.allImages[self.getLastIndex()])
            slideEnabled = true
        }else if self.allImages.count == 1 {
            self.delegate?.kenBurnsSlideshowView?(self, willShowKenBurnsView: self.currentKenBurnsView)
            self.asynchronousSetImage(kenBurnsView: self.currentKenBurnsView, image: self.allImages[0])
            slideEnabled = false
        }else {
            slideEnabled = false
        }
        self.scrollView.scrollEnabled = slideEnabled
        self.slideshowEnabled = slideEnabled
    }
    
    private func updateKenBurnsViewTitle() {
        if self.allImages.count >= 2 {
            self.currentTitleView.title = self.allImages[0].title
            self.currentTitleView.subTitle = self.allImages[0].subTitle
            self.previousTitleView.title = self.allImages[self.getLastIndex()].title
            self.previousTitleView.subTitle = self.allImages[self.getLastIndex()].subTitle
            self.nextTitleView.title = self.allImages[1].title
            self.nextTitleView.subTitle = self.allImages[1].subTitle
        }else if self.allImages.count == 1 {
            self.titleViews[0].title = self.allImages[0].title
            self.titleViews[0].subTitle = self.allImages[0].subTitle
        }
    }
    
    private func layoutKenburnsViews() {
        for view in self.kenBurnsViews {
            self.insertSubview(view, atIndex: 0)
        }
        
        self.currentKenBurnsView.alpha = 1.0
        self.previousKenBurnsView.alpha = 0
        self.nextKenBurnsView.alpha = 0
    }
    
    private func pauseBothSideKenBurnsView() {
        self.nextKenBurnsView.pauseMotion()
        self.previousKenBurnsView.pauseMotion()
    }
    
    func longPressHandler(gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .Began:
            self.currentKenBurnsView.showWholeImage()
            self.pauseSlideshowTimer()
        case .Cancelled:
            fallthrough
        case .Ended:
            var delay:Double = self.currentKenBurnsView.wholeImageShowing ? 0.2 : 0
            self.currentKenBurnsView.zoomImageAndRestartMotion(delay: delay, completion: { Bool -> () in
                self.resumeSlideshowTimer()
            })
        default:
            break
        }
    }
    
    private func updateCurrentIndex(value: Int) {
        var updatedIndex = self.currentIndex + value
        if updatedIndex >= self.allImages.count {
            updatedIndex = 0
        }else if updatedIndex < 0 {
            updatedIndex = self.allImages.count + value
        }
        
        self.currentIndex = updatedIndex
    }
    
    private func getNextIndex() -> Int {
        var nextIndex = self.currentIndex + 1
        if nextIndex >= self.allImages.count {
            nextIndex = 0
        }
        return nextIndex
    }
    
    private func getPreviousIndex() -> Int {
        var previousIndex = self.currentIndex - 1
        if previousIndex < 0 {
            previousIndex = self.allImages.count - 1
        }
        return previousIndex
    }
    
    private func getLastIndex() -> Int {
        return self.allImages.count - 1
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let width = scrollView.bounds.width
        let offsetX = scrollView.contentOffset.x
        
        var alpha = cos((fabs((offsetX - width) / width)) * CGFloat(M_PI)) / 2 + 0.5
        var darkCoverAlpha = (sin((fabs((offsetX - width) / width)) *    CGFloat(M_PI))) * 0.6
        
        if (alpha > 0.999) {
            alpha = 1.0
        }
        
        self.darkCoverView.alpha = darkCoverAlpha
        
        if round(offsetX - width) <= 0 {
            self.currentKenBurnsView.alpha = alpha
            self.previousKenBurnsView.alpha = 1.0
            self.nextKenBurnsView.alpha = 0
            self.previousKenBurnsView.resumeMotion()
        }else {
            self.currentKenBurnsView.alpha = alpha
            self.previousKenBurnsView.alpha = 0
            self.nextKenBurnsView.alpha = 1.0
            self.nextKenBurnsView.resumeMotion()
        }
    }
    
    func infinitePageViewDidShowPreviousPage(#pageView: KenBurnsInfinitePageView) {
        let prevView = self.kenBurnsViews.removeLast()
        self.kenBurnsViews.insert(prevView, atIndex: 0)
        let prevTitle = self.titleViews.removeLast()
        self.titleViews.insert(prevTitle, atIndex: 0)
        
        self.delegate?.kenBurnsSlideshowView?(self, willShowKenBurnsView: self.currentKenBurnsView)
        
        self.updateCurrentIndex(-1)
        self.asynchronousSetImage(kenBurnsView: self.previousKenBurnsView, image: self.allImages[self.getPreviousIndex()])
        self.previousTitleView.title = self.allImages[self.getPreviousIndex()].title
        self.previousTitleView.subTitle = self.allImages[self.getPreviousIndex()].subTitle
        
        self.nextKenBurnsView.zoomImageAndRestartMotion()
        self.pauseBothSideKenBurnsView()
        
        self.layoutKenburnsViews()
        
        self.configureTimer()
    }
    
    func infinitePageViewDidShowNextPage(#pageView: KenBurnsInfinitePageView) {
        let nextView = self.kenBurnsViews.removeAtIndex(0)
        self.kenBurnsViews.append(nextView)
        let nextTitle = self.titleViews.removeAtIndex(0)
        self.titleViews.append(nextTitle)
        
        self.delegate?.kenBurnsSlideshowView?(self, willShowKenBurnsView: self.currentKenBurnsView)
        
        self.updateCurrentIndex(1)
        self.asynchronousSetImage(kenBurnsView: self.nextKenBurnsView, image: self.allImages[self.getNextIndex()])
        self.nextTitleView.title = self.allImages[self.getNextIndex()].title
        self.nextTitleView.subTitle = self.allImages[self.getNextIndex()].subTitle
        
        self.previousKenBurnsView.zoomImageAndRestartMotion()
        self.pauseBothSideKenBurnsView()
        
        self.layoutKenburnsViews()
        
        self.configureTimer()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !self.isShowingCoverImage
    }
}



class KenBurnsSlideshowImageObject: NSObject {
    var image: UIImage?
    var imageUrl: NSURL?
    var title: NSString?
    var subTitle: NSString?
    var attributedTitle: NSAttributedString?
    var attributedSUbTitle: NSAttributedString?
}



class KenBurnsSlideshowTitleView: UIView {
    private var titleLabel: UILabel! = UILabel()
    private var subTitleLabel: UILabel! = UILabel()
    private var heightConstraint: NSLayoutConstraint!
    private var gradientLayer: CAGradientLayer! = CAGradientLayer()
    
    var title: String? {
        set {
            self.titleLabel.text = newValue
        }
        get {
            return self.titleLabel.text
        }
    }
    var subTitle: String? {
        set {
            self.subTitleLabel.text = newValue
        }
        get {
            return self.subTitleLabel.text
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.gradientLayer.bounds.size = CGSizeMake(self.bounds.width, 110.0)
        self.gradientLayer.frame.origin = CGPointMake(0, self.bounds.height - self.gradientLayer.bounds.height)
    }
    
    private func configure() {
        self.backgroundColor = UIColor.clearColor()
        
        self.titleLabel.frame.size.height = 20.0
        self.titleLabel.textColor = UIColor.whiteColor()
        self.insertSubview(self.titleLabel, atIndex: 0)
        
        self.subTitleLabel.frame.size.height = 20.0
        self.subTitleLabel.textColor = UIColor.whiteColor()
        self.insertSubview(self.subTitleLabel, atIndex: 0)
        
        self.gradientLayer.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().colorWithAlphaComponent(0.6).CGColor]
        self.gradientLayer.locations = [0, 1.0]
        self.layer.insertSublayer(self.gradientLayer, atIndex: 0)
        
        self.applyConstraints(self.titleLabel, toView: self, bottomMargin: 20.0)
        self.applyConstraints(self.subTitleLabel, toView: self.titleLabel, bottomMargin: self.titleLabel.bounds.height)
    }
    
    private func applyConstraints(fromView: UIView, toView: UIView, bottomMargin: CGFloat) {
        fromView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        self.heightConstraint = NSLayoutConstraint(item: fromView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1.0, constant: fromView.bounds.height)
        fromView.addConstraint(self.heightConstraint!)
        
        let centerConst = NSLayoutConstraint(item: fromView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0)
        let leftConst = NSLayoutConstraint(item: fromView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1.0, constant: 15.0)
        let rightConst = NSLayoutConstraint(item: fromView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1.0, constant: -15.0)
        let bottomConst = NSLayoutConstraint(item: fromView, attribute: .Bottom, relatedBy: .Equal, toItem: toView, attribute: .Bottom, multiplier: 1.0, constant: -bottomMargin)
        self.addConstraints([leftConst, rightConst, bottomConst])
    }
}




@objc protocol KenBurnsInfinitePageViewDelegate: UIScrollViewDelegate {
    optional func infinitePageViewDidShowPreviousPage(#pageView: KenBurnsInfinitePageView)
    optional func infinitePageViewDidShowNextPage(#pageView: KenBurnsInfinitePageView)
}

internal class KenBurnsInfinitePageView: UIScrollView {
    override var frame: CGRect {
        didSet {
            self.updateContentViewsLayout()
        }
    }
    
    private var contentViews: [UIView]! = []
    
    private var pageOrderIndexes: [Int]! = []
    
    weak var pageViewDelegate: KenBurnsInfinitePageViewDelegate? {
        didSet {
            self.delegate = self.pageViewDelegate
        }
    }
    
    var pageItems: [UIView]? {
        didSet {
            self.removeAllSubviewsOnContentViews()
            
            var scrollEnabled = false
            self.pageOrderIndexes = []
            if self.pageItems != nil {
                for index in 0..<self.pageItems!.count {
                    self.pageOrderIndexes.append(index)
                }
                
                if !self.pageOrderIndexes.isEmpty {
                    let lastIndex = self.pageOrderIndexes.removeLast()
                    self.pageOrderIndexes.insert(lastIndex, atIndex: 0)
                    scrollEnabled = true
                }else {
                    scrollEnabled = false
                }
                
                self.layoutPageItems()
            }else {
                scrollEnabled = false
            }
            
            self.scrollEnabled = scrollEnabled
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }
    
    deinit {
        self.removeObserver(self, forKeyPath: "contentOffset")
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if keyPath == "contentOffset" {
            self.reorderContentViewsIfNeeded()
        }else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    func scrllToPreviousPage(duration: NSTimeInterval = 1.5) {
        let contentCenter = self.contentSize.width / 2
        let pageWidth = self.bounds.width
        let previousOffsetX = contentCenter - (pageWidth / 2)
        
        UIView.animateWithDuration(duration, delay: 0, options: .BeginFromCurrentState, animations: { () -> Void in
            self.contentOffset.x = previousOffsetX + 1.0
            }, completion: { (finished) -> () in
                self.contentOffset.x = previousOffsetX
        })
    }
    
    func scrollToNextPage(duration: NSTimeInterval = 1.5) {
        let contentCenter = self.contentSize.width / 2
        let pageWidth = self.bounds.width
        let nextOffsetX = contentCenter + (pageWidth / 2)
        
        UIView.animateWithDuration(duration, delay: 0, options: .BeginFromCurrentState, animations: { () -> Void in
            self.contentOffset.x = nextOffsetX - 1.0
            }, completion: { (finished) -> () in
                self.contentOffset.x = nextOffsetX
        })
    }
    
    private func configure() {
        self.scrollEnabled = false
        self.scrollsToTop = false
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.directionalLockEnabled = true
        self.clipsToBounds = true
        self.addObserver(self, forKeyPath: "contentOffset", options: .allZeros, context: nil)
        
        for index in 0..<3 {
            var contentView = UIView(frame: self.bounds)
            contentView.frame.origin.x = CGRectGetWidth(self.bounds) * CGFloat(index)
            contentView.userInteractionEnabled = false
            contentView.clipsToBounds = true
            self.contentViews.append(contentView)
            self.insertSubview(contentView, atIndex: 0)
        }
        
        self.updateContentSize()
        self.offsetCentering()
    }
    
    private func offsetCentering() {
        let contentWidth = self.contentSize.width
        let pageWidth = self.bounds.width
        let centerOffsetX = (contentWidth / 2) - (pageWidth / 2)
        
        self.contentOffset.x = round(centerOffsetX)
    }
    
    private func updateContentSize() {
        var contentWidth: CGFloat = 0.0
        for contentView: UIView in self.contentViews {
            contentWidth += contentView.bounds.width
        }
        self.contentSize = CGSizeMake(contentWidth, self.bounds.height)
    }
    
    private func updateContentViewsLayout() {
        for (index, view: UIView) in enumerate(self.contentViews!) {
            let originX = CGRectGetWidth(self.bounds) * CGFloat(index)
            view.frame = self.bounds
            view.frame.origin.x = originX
            if self.pageItems != nil {
                if self.pageItems!.count > index {
                    let page = self.pageItems![self.pageOrderIndexes[index]]
                    page.center.x = CGRectGetWidth(page.bounds) / 2
                    page.center.y = CGRectGetHeight(page.bounds) / 2
                }
            }
        }
        
        self.updateContentSize()
        self.offsetCentering()
    }
    
    private func layoutPageItems() {
        if self.pageItems != nil {
            self.removeAllSubviewsOnContentViews()
            
            if self.pageItems!.count >= 2 {
                for (index, order: Int) in enumerate(self.pageOrderIndexes) {
                    if index < 3 {
                        let page = self.pageItems![order]
                        self.addSubviewToContentView(index, view: page)
                    }else {
                        break
                    }
                }
                
                if pageItems!.count == 2 {
                    let order = self.pageOrderIndexes[0]
                    let archiveData = NSKeyedArchiver.archivedDataWithRootObject(self.pageItems![order])
                    let copiedPage = NSKeyedUnarchiver.unarchiveObjectWithData(archiveData) as UIView
                    self.addSubviewToContentView(2, view: copiedPage)
                }
                
                self.scrollEnabled = true
            }else if self.pageItems!.count == 1 {
                self.contentViews[1].addSubview(self.pageItems![0])
                self.addSubviewToContentView(1, view: self.pageItems![0])
                self.scrollEnabled = false
            }
        }
    }
    
    private func layoutBothSideItem() {
        if self.pageItems != nil {
            self.removeSubviewsOnBothSideConentView()
            
            if self.pageItems!.count >= 2 {
                let prevOrder = self.pageOrderIndexes[0]
                let prevPage = self.pageItems![prevOrder]
                var nextOrder: Int
                var nextPage: UIView
                if self.pageItems!.count >= 3 {
                    nextOrder = self.pageOrderIndexes[2]
                    nextPage = self.pageItems![nextOrder]
                }else {
                    nextOrder = self.pageOrderIndexes[0]
                    let archiveData = NSKeyedArchiver.archivedDataWithRootObject(self.pageItems![nextOrder])
                    nextPage = NSKeyedUnarchiver.unarchiveObjectWithData(archiveData) as UIView
                }
                
                self.addSubviewToContentView(0, view: prevPage)
                self.addSubviewToContentView(2, view: nextPage)
            }
        }
    }
    
    private func reorderContentViewsIfNeeded() {
        let offsetX = self.contentOffset.x
        let contentWidth = self.contentSize.width
        let pageWidth = self.bounds.width
        let centerOffsetX = (contentWidth / 2) - (pageWidth / 2)
        let previousOffsetX = centerOffsetX - pageWidth
        let nextOffsetX = centerOffsetX + pageWidth
    
        if ceil(offsetX) <= ceil(previousOffsetX) {
            let lastItem = self.contentViews.removeLast()
            self.contentViews.insert(lastItem, atIndex: 0)
            
            if !self.pageOrderIndexes.isEmpty {
                let lastIndex = self.pageOrderIndexes.removeLast()
                self.pageOrderIndexes.insert(lastIndex, atIndex: 0)
            }
            
            self.updateContentViewsLayout()
            self.offsetCentering()
            self.layoutBothSideItem()
            
            self.pageViewDelegate?.infinitePageViewDidShowPreviousPage?(pageView: self)
        }else if ceil(offsetX) >= ceil(nextOffsetX) {
            let firstItem = self.contentViews.removeAtIndex(0)
            self.contentViews.append(firstItem)
            
            if !self.pageOrderIndexes.isEmpty {
                let firstIndex = self.pageOrderIndexes.removeAtIndex(0)
                self.pageOrderIndexes.append(firstIndex)
            }
            
            self.updateContentViewsLayout()
            self.offsetCentering()
            self.layoutBothSideItem()
            
            self.pageViewDelegate?.infinitePageViewDidShowNextPage?(pageView: self)
        }
    }
    
    private func addSubviewToContentView(index: Int, view: UIView) {
        if index <= 3 {
            let contentView = self.contentViews[index]
            let size = view.bounds.size
            
            view.autoresizingMask = .FlexibleWidth | .FlexibleHeight
            view.center.x = CGRectGetWidth(view.bounds) / 2
            view.center.y = CGRectGetHeight(view.bounds) / 2
            contentView.insertSubview(view, atIndex: 0)
        }
    }
    
    private func removeAllSubviewsOnContentViews() {
        for contentView: UIView in self.contentViews {
            for subview in contentView.subviews {
                subview.removeFromSuperview()
            }
        }
    }
    
    private func removeSubviewsOnBothSideConentView() {
        let prevContentView = self.contentViews[0]
        let nextContentView = self.contentViews[2]
        for subview in prevContentView.subviews {
            subview.removeFromSuperview()
        }
        for subview in nextContentView.subviews {
            subview.removeFromSuperview()
        }
    }
}