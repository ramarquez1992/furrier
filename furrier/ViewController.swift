//
//  ViewController.swift
//  furrier
//
//  Created by Marquez, Richard A on 11/27/16.
//  Copyright © 2016 WSU. All rights reserved.
//

import UIKit
import Charts

class ViewController: UIViewController {
    private let REDRAW_INTERVAL: Double = 0.1

    private let audioController: AudioController = AudioController()
    
    private let centerX: CGFloat
    private let centerY: CGFloat
    
    private let modeSwitch: UISwitch
    private let modeLabel: UILabel
    
    private let testButton: UIButton

    private let lineChart: LineChartView
    private let visualizer: VisualizerView
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        // INIT LOCATIONS
        centerX = UIScreen.main.bounds.maxX / 2
        centerY = UIScreen.main.bounds.maxY / 2
        
        visualizer = VisualizerView()
        visualizer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        visualizer.layer.zPosition = 100
        visualizer.isHidden = true
        
        // CHART
        lineChart = LineChartView()
        lineChart.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.maxX, height: UIScreen.main.bounds.maxY)
        lineChart.noDataText = ""
        lineChart.leftAxis.axisMaximum = 1
        lineChart.leftAxis.axisMinimum = -1
        lineChart.leftAxis.enabled = false
        lineChart.rightAxis.enabled = false
        lineChart.xAxis.enabled = false
        lineChart.drawBordersEnabled = false
        lineChart.drawMarkers = false
        lineChart.drawGridBackgroundEnabled = false
        lineChart.legend.enabled = false
        lineChart.chartDescription?.enabled = false


        var modeSwitchOffset = CGFloat(10)
        modeSwitch = UISwitch()
        modeSwitch.frame = CGRect(x: UIScreen.main.bounds.width-modeSwitch.frame.width-modeSwitchOffset, y: modeSwitchOffset, width: modeSwitch.frame.width, height: modeSwitch.frame.height)
        modeSwitch.setOn(false, animated: false)
        
        modeLabel = UILabel()
        modeLabel.frame = CGRect(x: UIScreen.main.bounds.width-modeSwitch.frame.width, y: modeSwitch.frame.height+modeSwitchOffset, width: modeSwitch.frame.width, height: modeSwitch.frame.height)
        modeLabel.textAlignment = .left
        modeLabel.text = "TIME"
        modeLabel.textColor = UIColor.white
        
        
        // TEST BUTTON
        testButton = UIButton(type: .roundedRect)
        testButton.frame = CGRect(x: modeSwitchOffset, y: modeSwitchOffset, width: 60, height: 40)
        testButton.setTitle("TEST", for: UIControlState())
        testButton.setTitleColor(.black, for: UIControlState())
        testButton.backgroundColor = .green
        testButton.layer.cornerRadius = 5
        testButton.isEnabled = true
        
        // SUPER CALL
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        // ADD SUBVIEWS
        modeSwitch.addTarget(self, action: #selector(ViewController.modeStateChanged(_:)), for: UIControlEvents.valueChanged)

        self.view.addSubview(visualizer)
        self.view.addSubview(lineChart)
        
        self.view.addSubview(modeLabel)
        self.view.addSubview(modeSwitch)
        
        self.view.addSubview(testButton)
        testButton.addTarget(self, action: #selector(ViewController.startButtonPressed), for: UIControlEvents.touchUpInside)
        
        
        // MISC SETUP
        self.view.backgroundColor = .purple
        
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
        let (drawBuffer, drawBufferSize) = audioController.getDrawBuffer()
        if drawBufferSize > 0 {
            drawChart(data: drawBuffer!, size: drawBufferSize)
        }
        
    }

    func drawChart(data: UnsafeMutablePointer<Float32>, size: Int) {
        let lineDataSet = LineChartDataSet()
        lineDataSet.setColor(NSUIColor.green)
        lineDataSet.lineWidth = 1
        lineDataSet.drawCirclesEnabled = false
        
        lineDataSet.addEntry(ChartDataEntry(x: -1.0, y: 0.0)) // ensure set never empty
        
        for i in 0..<size {
            if data[i] != 0.0 || audioController.displayMode == .freqDomain {  // a hard 0 means no data
                lineDataSet.addEntry(ChartDataEntry(x: Double(i), y: Double(data[i])))
            }
        }
        
        let lineData = LineChartData()
        lineData.addDataSet(lineDataSet)
        lineChart.data = lineData
        
        lineChart.notifyDataSetChanged()
    }
    
    func modeStateChanged(_ switchState: UISwitch) {
        if switchState.isOn {
            audioController.displayMode = .freqDomain
            modeLabel.text = "FREQ"
        } else {
            audioController.displayMode = .timeDomain
            modeLabel.text = "TIME"
        }
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

