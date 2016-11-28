//
//  FFTransformer.swift
//  furrier
//
//  Created by Marquez, Richard A on 11/28/16.
//  Copyright © 2016 WSU. All rights reserved.
//

import Foundation

class FFTransformer {
    var maxFrames: Int
    
    init(_ inMaxFrames: Int) {
        self.maxFrames = inMaxFrames
    }
 
    func compute(_ inAudioData: UnsafePointer<Float32>?, outFFTData: UnsafeMutablePointer<Float32>?) {
        // TODO: implement
    }
}
