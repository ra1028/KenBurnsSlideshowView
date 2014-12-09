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
//        self.kenBurnsView.image = UIImage(named: "SampleImage.jpg")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.kenBurnsView.image = UIImage(named: "SampleImage.jpg")
    }
    
    @IBAction func slider(sender: UISlider) {
        let value = 100 + CGFloat(sender.value * 200)
        self.bottomConst.constant = value
    }
}

