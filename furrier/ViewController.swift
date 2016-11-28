//
//  ViewController.swift
//  furrier
//
//  Created by Marquez, Richard A on 11/27/16.
//  Copyright © 2016 WSU. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private let startButton: UIButton
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        startButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        
        startButton.setTitle("Start", for: UIControlState())
        startButton.setTitleColor(UIColor.black, for: UIControlState())
        startButton.backgroundColor = UIColor.green
        startButton.isEnabled = true
        
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        
        self.view.addSubview(startButton)
        startButton.addTarget(self, action: #selector(ViewController.startButtonPressed), for: UIControlEvents.touchUpInside)
        
        self.view.backgroundColor = UIColor.cyan
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all
    }
    
    func startButtonPressed() {
        print("START BUTTON PRESSED")
    }

}

