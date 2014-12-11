//
//  ViewController.swift
//  KenBurnsSlideshowView-Demo
//
//  Created by Ryo Aoyama on 12/1/14.
//  Copyright (c) 2014 Ryo Aoyama. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var kenBurnsView: KenBurnsView!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.kenBurnsView.image = UIImage(named: "SampleImage1.jpg")
        let longPress = UILongPressGestureRecognizer(target: self, action: "showWholeImage:")
        longPress.minimumPressDuration = 0.2
        self.kenBurnsView.addGestureRecognizer(longPress)
    }
    
    func showWholeImage(sender: UIGestureRecognizer) {
        switch sender.state {
        case .Began:
            self.kenBurnsView.showWholeImage()
        case .Cancelled:
            fallthrough
        case .Ended:
            self.kenBurnsView.zoomImageAndRestartMotion()
        default:
            break
        }
    }
    
    @IBAction func buttonHandler(sender: UIButton) {
        var imageName = "SampleImage"
        imageName += sender.titleLabel!.text! + ".jpg"
        self.kenBurnsView.image = UIImage(named: imageName)
    }
}

