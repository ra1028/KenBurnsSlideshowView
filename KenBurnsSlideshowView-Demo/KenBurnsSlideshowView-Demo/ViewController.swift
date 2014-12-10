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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.kenBurnsView.image = UIImage(named: "SampleImage1.jpg")
//        self.kenBurnsView.image = UIImage(named: "SampleImage2.jpg")
        let tap = UITapGestureRecognizer(target: self, action: "pauseKenBurnsView:")
        let longPress = UILongPressGestureRecognizer(target: self, action: "showWholeImage:")
        tap.requireGestureRecognizerToFail(longPress)
        self.kenBurnsView.addGestureRecognizer(tap)
        self.kenBurnsView.addGestureRecognizer(longPress)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.kenBurnsView.updateImageViewSize()
    }
    
    func pauseKenBurnsView(sender: UIGestureRecognizer) {
        if self.kenBurnsView.state == KenBurnsView.kenBurnsViewState.Animating {
            self.kenBurnsView.pauseMotion()
        }else if self.kenBurnsView.state == KenBurnsView.kenBurnsViewState.Pausing {
            self.kenBurnsView.resumeMotion()
        }
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
}

