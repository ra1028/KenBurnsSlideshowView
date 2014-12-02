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
        self.kenBurnsView.image = UIImage(named: "SampleImage.jpg")
    }
}

