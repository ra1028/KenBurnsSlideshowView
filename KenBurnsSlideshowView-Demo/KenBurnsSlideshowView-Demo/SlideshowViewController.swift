//
//  SlideshowViewController.swift
//  KenBurnsSlideshowView-Demo
//
//  Created by Ryo Aoyama on 12/12/14.
//  Copyright (c) 2014 Ryo Aoyama. All rights reserved.
//

import UIKit

class SlideshowViewController: UIViewController {
    var imageCount = 0
    
    @IBOutlet weak var kenBurnsSlideshowView: KenBurnsSlideshowView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpSlideshow()
    }
    
    private func setUpSlideshow() {
        var images: [KenBurnsSlideshowImageObject] = []
        for i in 1...15 {
            var name = "SampleImage"
            name += "\(i)" + ".jpg"
            let imageObject = KenBurnsSlideshowImageObject()
            imageObject.title = "\(name)"
            imageObject.image = UIImage(named: name)
            images.append(imageObject)
            self.imageCount++
        }
        self.kenBurnsSlideshowView.images = images
        let duration: CGFloat = 10.0
        self.kenBurnsSlideshowView.slideshowDuration = duration
        self.kenBurnsSlideshowView.kenBurnsEffectDuration = duration
        self.kenBurnsSlideshowView.coverImage = UIImage(named: "SampleImage16.jpg")
    }
    
    
    @IBAction func plusButton(sender: AnyObject) {
        if self.kenBurnsSlideshowView.isShowingCoverImage {
            self.kenBurnsSlideshowView.hideCoverImage(animated: true)
        }else {
            self.kenBurnsSlideshowView.showCoverImage(animated: true)
        }
//        self.imageCount++
//        if imageCount <= 16 {
//            var name = "SampleImage"
//            name += "\(self.imageCount)" + ".jpg"
//            let imageObject = KenBurnsSlideshowImageObject()
//            imageObject.title = "\(name)"
//            imageObject.image = UIImage(named: name)
//            self.kenBurnsSlideshowView.appendImage(image: imageObject)
//        }else {
//            self.imageCount--
//        }
    }
}
