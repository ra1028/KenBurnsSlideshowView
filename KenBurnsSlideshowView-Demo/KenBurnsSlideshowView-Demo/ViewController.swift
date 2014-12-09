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
    @IBOutlet weak var bottomConst: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.kenBurnsView.image = UIImage(named: "SampleImage.jpg")
        let longPress = UILongPressGestureRecognizer(target: self, action: "pauseKenBurnsView:")
        self.kenBurnsView.addGestureRecognizer(longPress)
    }
    
    func pauseKenBurnsView(sender: UIGestureRecognizer) {
//        if self.kenBurnsView.state == KenBurnsView.kenBurnsViewState.Animating {
//            self.kenBurnsView.pauseMotion()
//        }else if self.kenBurnsView.state == KenBurnsView.kenBurnsViewState.Pausing {
//            self.kenBurnsView.resumeMotion()
//        }
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
    
    @IBAction func slider(sender: UISlider) {
        let value = 100 + CGFloat(sender.value * 200)
        self.bottomConst.constant = value
    }
}

