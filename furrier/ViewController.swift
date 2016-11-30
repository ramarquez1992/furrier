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
    private let MAX_CHART_SIZE: Int = 512  // for speed
    private let REDRAW_INTERVAL: Double = 0.1

    private let audioController: AudioController = AudioController()
    
    private let centerX: CGFloat
    private let centerY: CGFloat
    
    private let modeSwitch: UISwitch
    private let modeLabel: UILabel
    
    private let testButton: UIButton

    private let lineChart: LineChartView
    private let visualizer: VisualizerView
    
    private var outputWave = Wave()
    
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
        lineChart.dragEnabled = false
        lineChart.scaleXEnabled = false
        lineChart.scaleYEnabled = false
        lineChart.pinchZoomEnabled = false
        lineChart.doubleTapToZoomEnabled = false
        lineChart.isUserInteractionEnabled = false


        let modeSwitchOffset = CGFloat(10)
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
        testButton.layer.zPosition = 101

        
        // SUPER CALL
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        // ADD SUBVIEWS
        modeSwitch.addTarget(self, action: #selector(ViewController.modeStateChanged(_:)), for: UIControlEvents.valueChanged)

        self.view.addSubview(visualizer)
        self.view.addSubview(lineChart)
        
        self.view.addSubview(modeLabel)
        self.view.addSubview(modeSwitch)
        
        self.view.addSubview(testButton)
        testButton.addTarget(self, action: #selector(ViewController.testButtonTapped), for: UIControlEvents.touchUpInside)
        
        
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
            if (visualizer.isHidden) {
                drawChart(data: drawBuffer!, size: drawBufferSize)
            } else {
                visualizer.setData(data: drawBuffer!, size: drawBufferSize)
                visualizer.setNeedsDisplay()
            }
        }
        
    }

    func drawChart(data: UnsafeMutablePointer<Float32>, size: Int) {
        let lineDataSet = LineChartDataSet()
        lineDataSet.setColor(NSUIColor.green)
        lineDataSet.lineWidth = 1
        lineDataSet.drawCirclesEnabled = false
        
        lineDataSet.addEntry(ChartDataEntry(x: -1.0, y: 0.0)) // ensure set never empty
        
        for i in 0..<size {
            if i >= MAX_CHART_SIZE { break }
            
            if data[i] != 0.0 || audioController.displayMode == .freqDomain {  // a hard 0 means no data
                let entry = audioController.displayMode == .timeDomain ? data[i] : (data[i]+128)/128
                lineDataSet.addEntry(ChartDataEntry(x: Double(i), y: Double( entry )))
                
                //print("\(i): \(data[i])")
            }
        }
        
        let lineData = LineChartData()
        lineData.addDataSet(lineDataSet)
        lineChart.data = lineData
        
        lineDataSet.drawFilledEnabled = audioController.displayMode == .timeDomain ? false : true
        
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        audioController.muted = false
        
        if let touch = touches.first {
            updateWaveForTouch(position: touch.location(in: self.view))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        audioController.muted = true
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            updateWaveForTouch(position: touch.location(in: self.view))
        }
    }
    
    func updateWaveForTouch(position: CGPoint) {
        let frequency = position.x/UIScreen.main.bounds.width
        let amplitude = 1-(position.y/UIScreen.main.bounds.height) // flip val so top is high, bottom low
        
        audioController.outputWave.frequency = Float32(frequency)
        audioController.outputWave.amplitude = Float32(amplitude)
    }
    
    func testButtonTapped() {
        print("TEST BUTTON TAPPED")
        audioController.playButtonPressedSound()
        
        //modeSwitch.setOn(true, animated: true)
        //modeStateChanged(modeSwitch)
        //visualizer.isHidden = !visualizer.isHidden
        
    }
    
}

