//
//  BufferManager.swift
//  aurioTouch
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/1/30.
//
//
/*
 
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class handles buffering of audio data that is shared between the view and audio controller
 
 */

import AudioToolbox
import libkern


let kNumDrawBuffers = 12
let kDefaultDrawSamples = 1024


class BufferManager {
        
    private(set) var drawBuffers: UnsafeMutablePointer<UnsafeMutablePointer<Float32>?>
    var currentDrawBufferLength: Int
    private var mDrawBufferIndex: Int
    
    
    
    private(set) var drawBuffer: UnsafeMutablePointer<Float32>
    var maxFrames: Int { return FFTInputBufferLen }

    var doesHaveNewFFTData: Bool {return hasNewFFTData != 0}
    var doesNeedNewFFTData: Bool {return needsNewFFTData != 0}
    var FFTOutputBufferLength: Int {return FFTInputBufferLen / 2}
    
    private var FFTInputBuffer: UnsafeMutablePointer<Float32>?
    private var FFTInputBufferFrameIndex: Int
    private var FFTInputBufferLen: Int
    private var hasNewFFTData: Int32   //volatile
    private var needsNewFFTData: Int32 //volatile
    
    //private var FFTHelper: FFTHelper
    
    init(maxFramesPerSlice inMaxFramesPerSlice: Int) {
        //REMOVING THIS BLOCK BREAKS CHART
        drawBuffers = UnsafeMutablePointer.allocate(capacity: Int(kNumDrawBuffers))
        mDrawBufferIndex = 0
        currentDrawBufferLength = kDefaultDrawSamples
        for i in 0..<kNumDrawBuffers {
            drawBuffers[Int(i)] = UnsafeMutablePointer.allocate(capacity: Int(inMaxFramesPerSlice))
        }
        ////////////////
        
        
        drawBuffer = UnsafeMutablePointer.allocate(capacity: Int(inMaxFramesPerSlice))
        
        
        FFTInputBuffer = nil
        FFTInputBufferFrameIndex = 0
        FFTInputBufferLen = inMaxFramesPerSlice
        hasNewFFTData = 0
        needsNewFFTData = 0
    
        FFTInputBuffer = UnsafeMutablePointer.allocate(capacity: Int(inMaxFramesPerSlice))
        //FFTHelper = FFTHelper(maxFramesPerSlice: inMaxFramesPerSlice)
        OSAtomicIncrement32Barrier(&needsNewFFTData)
    }
    
    deinit {
        //for i in 0..<kNumDrawBuffers {
            //drawBuffers[Int(i)]?.deallocate(capacity: mFFTInputBufferLen)
            //drawBuffers[Int(i)] = nil
        //}
        //drawBuffers.deallocate(capacity: kNumDrawBuffers)
        
        drawBuffer.deallocate(capacity: FFTInputBufferLen)
        FFTInputBuffer?.deallocate(capacity: FFTInputBufferLen)
    }
    
    func copyAudioDataToDrawBuffer(_ inData: UnsafePointer<Float32>?, inNumFrames: Int) {
        if inData == nil { return }
        
        for i in 0..<inNumFrames {
            //if i + mDrawBufferIndex >= currentDrawBufferLength {
                //cycleDrawBuffers()
                //mDrawBufferIndex = -i
            //}
            //drawBuffers[0]?[i + mDrawBufferIndex] = (inData?[i])!
            
            //drawBuffer[i + mDrawBufferIndex] = (inData?[i])!  // weird indexing??
            
            drawBuffer[i] = (inData?[i])!
        }
        //mDrawBufferIndex += inNumFrames
    }
    
    /*func cycleDrawBuffers() {
        // Cycle the lines in our draw buffer so that they age and fade. The oldest line is discarded.
        for drawBuffer_i in stride(from: (kNumDrawBuffers - 2), through: 0, by: -1) {
            memmove(drawBuffers[drawBuffer_i + 1], drawBuffers[drawBuffer_i], size_t(currentDrawBufferLength))
        }
    }*/
    
    func copyAudioDataToFFTInputBuffer(_ inData: UnsafePointer<Float32>, numFrames: Int) {
        let framesToCopy = min(numFrames, FFTInputBufferLen - FFTInputBufferFrameIndex) // min of numFrames and # of free spots in buffer
        memcpy(FFTInputBuffer?.advanced(by: FFTInputBufferFrameIndex), inData, size_t(framesToCopy * MemoryLayout<Float32>.size))
        FFTInputBufferFrameIndex += framesToCopy * MemoryLayout<Float32>.size
        if FFTInputBufferFrameIndex >= FFTInputBufferLen {
            OSAtomicIncrement32(&hasNewFFTData)
            OSAtomicDecrement32(&needsNewFFTData)
        }
    }
    
    func getFFTOutput(_ outFFTData: UnsafeMutablePointer<Float32>) {
        //FFTHelper.computeFFT(FFTInputBuffer, outFFTData: outFFTData)
        FFTInputBufferFrameIndex = 0
        OSAtomicDecrement32Barrier(&hasNewFFTData)
        OSAtomicIncrement32Barrier(&needsNewFFTData)
    }
}
