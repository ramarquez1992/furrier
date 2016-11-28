//
//  ViewController.swift
//  furrier
//
//  Created by Marquez, Richard A on 11/27/16.
//  Copyright © 2016 WSU. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private let REDRAW_INTERVAL: Double = 0.5

    private let audioController: AudioController = AudioController()
    
    private let centerX: CGFloat
    private let centerY: CGFloat
    private let startButton: UIButton
    private let num1Label: UILabel
    private let num2Label: UILabel
    private let num3Label: UILabel
    private var ctr: Int = 0
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        // INIT LOCATIONS
        centerX = UIScreen.main.bounds.maxX / 2
        centerY = UIScreen.main.bounds.maxY / 2
        
        
        // NUM LABELS
        num1Label = UILabel(frame: CGRect(x: centerX-50-150, y: centerY-50, width: 100, height: 100))
        num1Label.textAlignment = .center
        num1Label.text = "num1"
        num1Label.isUserInteractionEnabled = true
        
        num2Label = UILabel(frame: CGRect(x: centerX-50, y: centerY-50, width: 100, height: 100))
        num2Label.textAlignment = .center
        num2Label.text = "num2"
        num2Label.isUserInteractionEnabled = true
        
        num3Label = UILabel(frame: CGRect(x: centerX-50+150, y: centerY-50, width: 100, height: 100))
        num3Label.textAlignment = .center
        num3Label.text = "num3"
        num3Label.isUserInteractionEnabled = true

        
        // START BUTTON
        startButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        startButton.setTitle("Start", for: UIControlState())
        startButton.setTitleColor(.black, for: UIControlState())
        startButton.backgroundColor = .green
        startButton.isEnabled = true
        
        
        // SUPER CALL
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        
        // ADD SUBVIEWS
        self.view.addSubview(num1Label)
        self.view.addSubview(num2Label)
        self.view.addSubview(num3Label)
        num1Label.addGestureRecognizer(UIPanGestureRecognizer(
            target: self,
            action: #selector(ViewController.moveNumLabel(_:))
        ))
        
        self.view.addSubview(startButton)
        startButton.addTarget(self, action: #selector(ViewController.startButtonPressed), for: UIControlEvents.touchUpInside)
        
        
        // MISC SETUP
        self.view.backgroundColor = .cyan
        
        Timer.scheduledTimer(withTimeInterval: REDRAW_INTERVAL, repeats: true, block: {(timer: Timer) -> Void in
            self.drawView()
        })
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
    
    
    ////////////////////////////////////////////////////////////////////////////
    
    
    func drawView() {
        self.num1Label.text = "ctr:\(self.ctr)"
        self.ctr += 1
        
        let (drawBuffer, drawBufferSize) = audioController.getDrawBuffer()
        self.num2Label.text = "sz:\(drawBufferSize)"
        self.num3Label.text = "0th:\(drawBuffer[0])"
        
        
        
    }
    
    func startButtonPressed() {
        print("START BUTTON PRESSED")
        audioController.playButtonPressedSound()
    }

    func moveNumLabel(_ recognizer: UIPanGestureRecognizer) {
        let translation: CGPoint = recognizer.translation(in: view)
        
        let newX = recognizer.view!.center.x + translation.x
        let newY = recognizer.view!.center.y + translation.y
        
        recognizer.view?.center = CGPoint(x: newX, y: newY)
        recognizer.setTranslation(CGPoint(x: 0, y: 0), in: view)
    }
}

