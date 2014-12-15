//
//  KenBurnsSlideshowView.swift
//  KenBurnsSlideshowView-Demo
//
//  Created by Ryo Aoyama on 12/12/14.
//  Copyright (c) 2014 Ryo Aoyama. All rights reserved.
//

import UIKit

class KenBurnsSlideshowView: UIView, UIGestureRecognizerDelegate, KenBurnsInfinitePageViewDelegate {
    var images: [UIImage]? {
        didSet {
            self.updateKenBurnsViewImage()
            self.layoutKenburnsViews()
        }
    }
    
    override var bounds: CGRect {
        didSet {
            for kenburnsView in self.kenBurnsViews {
                kenburnsView.frame.size = self.bounds.size
            }
        }
    }
    
    private var kenBurnsViews: [KenBurnsView]! = []
    private var scrollView: KenBurnsInfinitePageView!
    private var darkCoverView: UIView = UIView()
    
    var previousKenBurnsView: KenBurnsView {
        return self.kenBurnsViews[2]
    }
    
    var currentKenBurnsView: KenBurnsView {
        return self.kenBurnsViews[0]
    }
    
    var nextKenBurnsView: KenBurnsView {
        return self.kenBurnsViews[1]
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
    }
    
    private func configure() {
        self.configureViews()
        self.configureObserver()
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
        longPress.minimumPressDuration = 0.22
        longPress.delegate = self
        self.addGestureRecognizer(longPress)
        
        var views = [UIView]()
        for i in 1...3 {
            var view = UIView(frame: UIScreen.mainScreen().bounds)
            var label = UILabel()
            label.frame.size = CGSizeMake(100, 100)
            label.font = UIFont.boldSystemFontOfSize(50.0)
            label.text = "\(i)"
            view.addSubview(label)
            views.append(view)
        }
        
        self.scrollView.pageItems = views
        
        for i in 0...2 {
            let kenBurns = KenBurnsView(frame: self.bounds)
            NSNotificationCenter.defaultCenter().removeObserver(kenBurns)
            self.kenBurnsViews.append(kenBurns)
        }
        
        self.updateKenBurnsViewImage()
        self.layoutKenburnsViews()
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.pauseBothSideKenBurnsView()
        })
    }
    
    func pauseCurrentKenBurnsMotion() {
        self.currentKenBurnsView.pauseMotion()
    }
    
    func resumeCurrentKenBurnsMotion() {
        self.currentKenBurnsView.resumeMotionWithMomentDelay()
    }
    
    private func updateKenBurnsViewImage() {
        if self.images != nil {
            if self.images!.count >= 3 {
                for (index, kenburns) in enumerate(self.kenBurnsViews) {
                    kenburns.image = self.images![index]
                }
                self.scrollView.scrollEnabled = true
            }else if self.images!.count == 2 {
                self.kenBurnsViews[0].image = self.images![0]
                self.kenBurnsViews[1].image = self.images![1]
                self.kenBurnsViews[2].image = self.images![1]
                self.scrollView.scrollEnabled = true
            }else if self.images!.count == 1 {
                self.kenBurnsViews[0].image = self.images![0]
                self.scrollView.scrollEnabled = false
            }
        }else {
            self.scrollView.scrollEnabled = false
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
        case .Cancelled:
            fallthrough
        case .Ended:
            var delay:Double = self.currentKenBurnsView.wholeImageShowing ? 0.2 : 0
            self.currentKenBurnsView.zoomImageAndRestartMotion(delay: delay)
        default:
            break
        }
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
        
        self.pauseBothSideKenBurnsView()
        
        self.layoutKenburnsViews()
    }
    
    func infinitePageViewDidShowNextPage(#pageView: KenBurnsInfinitePageView) {
        let nextView = self.kenBurnsViews.removeAtIndex(0)
        self.kenBurnsViews.append(nextView)
        
        self.pauseBothSideKenBurnsView()
        
        self.layoutKenburnsViews()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if keyPath == "contentOffset" {
            self.reorderContentViewsIfNeeded()
        }else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
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
            
            view.setTranslatesAutoresizingMaskIntoConstraints(false)
            contentView.insertSubview(view, atIndex: 0)
            
            let widthConst = NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1.0, constant: size.width)
            let heightConst = NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1.0, constant: size.height)
            view.addConstraints([widthConst, heightConst])
            
            let horizontalConst = NSLayoutConstraint(item: view, attribute: .CenterX, relatedBy: .Equal, toItem: contentView, attribute: .CenterX, multiplier: 1.0, constant: 0)
            let verticalConst = NSLayoutConstraint(item: view, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1.0, constant: 0)
            contentView.addConstraints([horizontalConst, verticalConst])
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