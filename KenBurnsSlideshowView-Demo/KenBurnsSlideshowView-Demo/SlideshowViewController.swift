//
//  SlideshowViewController.swift
//  KenBurnsSlideshowView-Demo
//
//  Created by Ryo Aoyama on 12/12/14.
//  Copyright (c) 2014 Ryo Aoyama. All rights reserved.
//

import UIKit

class SlideshowViewController: UIViewController {
    @IBOutlet weak var kenBurnsSlideshowView: KenBurnsSlideshowView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpSlideshow()
    }
    
    private func setUpSlideshow() {
        var images: [UIImage] = []
        for i in 1...3 {
            var name = "SampleImage"
            name += "\(i)" + ".jpg"
            images.append(UIImage(named: name)!)
        }
        self.kenBurnsSlideshowView.images = images
        self.kenBurnsSlideshowView.slideshowDuration = 4.0
    }
}
