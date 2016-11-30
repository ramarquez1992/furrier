//
//  VisualizerView.swift
//  furrier
//
//  Created by Marquez, Richard A on 11/29/16.
//  Copyright © 2016 WSU. All rights reserved.
//

import UIKit

class VisualizerView: UIView {
    var data: UnsafeMutablePointer<Float32> = UnsafeMutablePointer.allocate(capacity: 0)
    var dataSize: Int = 0
    var max: Float32 = 0
    
    func setData(data: UnsafeMutablePointer<Float32>, size: Int) {
        self.data = data
        
        dataSize = 0
        max = data[0]
        
        for i in 0..<size {
            if data[i] != 0 {
                dataSize += 1
            }
            
            if abs(data[i]) > abs(max) {
                max = data[i]
            }
        }
        
        print("size: \(dataSize) max: \(max)")
    }
    
    override func draw(_ rect: CGRect) {
        //TODO: visualize the data
        
        let barWidth = bounds.width/CGFloat(dataSize)
        var fillColor: UIColor

        for i in 0..<dataSize {
            var normalized = (1/max) * abs(data[i])
            fillColor = getRandomColor()
            fillColor.setFill()
            let barHeight = bounds.height*CGFloat(normalized)

            var path = UIBezierPath(rect: CGRect(x: CGFloat(i)*barWidth, y: 0, width: barWidth, height: barHeight))
            path.fill()
        }
        
        /*
        //var path = UIBezierPath(ovalIn: rect)
        //fillColor.setFill()
        //path.fill()
        
        //set up the width and height variables
        //for the horizontal stroke
        let plusHeight: CGFloat = 3.0
        let plusWidth: CGFloat = min(bounds.width, bounds.height) * 0.6
        
        //create the path
        var plusPath = UIBezierPath()
        
        //set the path's line width to the height of the stroke
        plusPath.lineWidth = abs(CGFloat(data[0]))
        
        //move the initial point of the path
        //to the start of the horizontal stroke
        plusPath.move(to: CGPoint(
            x:bounds.width/2 - plusWidth/2 + 0.5,
            y:bounds.height/2 + 0.5))
        
        //add a point to the path at the end of the stroke
        plusPath.addLine(to: CGPoint(
            x:bounds.width/2 + plusWidth/2 + 0.5,
            y:bounds.height/2 + 0.5))
        
        var isAddButton = true
        //Vertical Line
        if isAddButton {
            //move to the start of the vertical stroke
            plusPath.move(to: CGPoint(
                x:bounds.width/2 + 0.5,
                y:bounds.height/2 - plusWidth/2 + 0.5))
            
            //add the end point to the vertical stroke
            plusPath.addLine(to: CGPoint(
                x:bounds.width/2 + 0.5,
                y:bounds.height/2 + plusWidth/2 + 0.5))
        }
        
        //set the stroke color
        UIColor.white.setStroke()
        
        //draw the stroke
        plusPath.stroke()
        
        
        for i in 0..<dataSize {
            //data[i]
        }
        */
        
    }
    
    func getRandomColor() -> UIColor {
        let red = CGFloat(drand48())
        let green = CGFloat(drand48())
        let blue = CGFloat(drand48())
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
}
