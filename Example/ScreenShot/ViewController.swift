//
//  ViewController.swift
//  ScreenShot
//
//  Created by Jin Hyong Park on 06/28/2018.
//  Copyright (c) 2018 Jin Hyong Park. All rights reserved.
//

import UIKit
import ScreenShot

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Recorder.shared.record()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func exportButtonAction(_ sender: Any) {
        Recorder.shared.export()
    }
}

