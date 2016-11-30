//
//  AudioController.swift
//  furrier
//
//  Created by Marquez, Richard A on 11/27/16.
//  
//  Uses aruiTouch by Apple Inc.
//  Swift translation by OOPer in cooperation with shlab.jp, on 2015/1/31.
//

import AVFoundation
import AudioToolbox

class AudioController: AURenderCallbackDelegate {

    enum displayModeType {
        case timeDomain
        case freqDomain
    }
    
    var displayMode = displayModeType.timeDomain
    
    var muted: Bool = true
    var outputWave = Wave()
    
    var rioUnit: AudioUnit? = nil

    var dcRejectionFilter: DCRejectionFilter!
    var bufferManager: BufferManager!
    var audioPlayer: AVAudioPlayer?
    
    var audioChainIsBeingReconstructed: Bool = false
    
    private var FFTData: UnsafeMutablePointer<Float32>!

    
    init() {
        self.setupAudioChain()
        AudioOutputUnitStart(rioUnit!)
    }
    
    func setupAudioChain() {
        self.setupAudioSession()
        self.setupIOUnit()
    }
    
    func setupAudioSession() {
        let sessionInstance = AVAudioSession.sharedInstance()
        
        do {
            try sessionInstance.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try sessionInstance.setPreferredIOBufferDuration(0.005)
            
            // handle media services reset
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(AudioController.handleMediaServerReset(_:)),
                                                   name: NSNotification.Name.AVAudioSessionMediaServicesWereReset,
                                                   object: sessionInstance)
            
            try sessionInstance.setActive(true)
        } catch {
            print("Error info: \(error)")
        }
    }
    
    func setupIOUnit() {
        // Create a new instance of AURemoteIO
        
        var desc = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_Output),  // an output unit provides input, output, or both input and output simultaneously. It can be used as the head of an audio unit processing graph
            componentSubType: OSType(kAudioUnitSubType_RemoteIO),  // for input, output, or simultaneous input and output
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),  // vendor specifier
            componentFlags: 0,
            componentFlagsMask: 0)
        
        
        let comp = AudioComponentFindNext(nil, &desc)  // gets audio component w/ specified description
        AudioComponentInstanceNew(comp!, &self.rioUnit)  // initialize unit from component
        
        
        //  Enable input and output on AURemoteIO
        //  Input is enabled on the input scope of the input element
        //  Output is enabled on the output scope of the output element
        var one: UInt32 = 1
        AudioUnitSetProperty(self.rioUnit!, AudioUnitPropertyID(kAudioOutputUnitProperty_EnableIO), AudioUnitScope(kAudioUnitScope_Input), 1, &one, SizeOf32(one))  // input is element 1
        AudioUnitSetProperty(self.rioUnit!, AudioUnitPropertyID(kAudioOutputUnitProperty_EnableIO), AudioUnitScope(kAudioUnitScope_Output), 0, &one, SizeOf32(one))  // output is element 0
        
        // Explicitly set the input and output client formats
        // sample rate = 44100, num channels = 1, format = 32 bit floating point
        var ioFormat = CAStreamBasicDescription(sampleRate: 44100, numChannels: 1, pcmf: .float32, isInterleaved: false)
        AudioUnitSetProperty(self.rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_StreamFormat), AudioUnitScope(kAudioUnitScope_Output), 1, &ioFormat, SizeOf32(ioFormat))
        AudioUnitSetProperty(self.rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_StreamFormat), AudioUnitScope(kAudioUnitScope_Input), 0, &ioFormat, SizeOf32(ioFormat))
        
        // Set the MaximumFramesPerSlice property. This property is used to describe to an audio unit the maximum number
        // of samples it will be asked to produce on any single given call to AudioUnitRender
        var maxFramesPerSlice: UInt32 = 4096
        AudioUnitSetProperty(self.rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_MaximumFramesPerSlice), AudioUnitScope(kAudioUnitScope_Global), 0, &maxFramesPerSlice, SizeOf32(UInt32.self))
        
        // Get the property value back from AURemoteIO. We are going to use this value to allocate buffers accordingly
        var propSize = SizeOf32(UInt32.self)
        AudioUnitGetProperty(self.rioUnit!, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, &propSize)
        
        
        // INIT INSTANCE VARS
        self.dcRejectionFilter = DCRejectionFilter()
        self.bufferManager = BufferManager(maxFramesPerSlice: Int(maxFramesPerSlice))
        self.FFTData = UnsafeMutablePointer.allocate(capacity: bufferManager.FFTOutputBufferLength)
        bzero(self.FFTData, size_t(bufferManager.FFTOutputBufferLength * MemoryLayout<Float32>.size))

        
        // Set the render callback on AURemoteIO
        var renderCallback = AURenderCallbackStruct(
            inputProc: AudioController_RenderCallback,
            inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
        )
        //AudioUnitSetProperty(self.rioUnit!, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallback, MemoryLayout<AURenderCallbackStruct>.size.ui)
        AudioUnitSetProperty(self.rioUnit!, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallback, UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        
        // Initialize the AURemoteIO instance
        AudioUnitInitialize(self.rioUnit!)

    }
    
    @objc func handleMediaServerReset(_ notification: Notification) {
        print("Media server has been reset; handling...")
        audioChainIsBeingReconstructed = true
        
        usleep(25000) // Wait to ensure these objects are not deleted while being accessed elsewhere
        
        // Rebuild the audio chain
        dcRejectionFilter = nil
        bufferManager = nil
        audioPlayer = nil
        
        self.setupAudioChain()
        AudioOutputUnitStart(rioUnit!)
        
        audioChainIsBeingReconstructed = false
    }
    
    ////////////////////////////////////////////////////////////////////////////
    
    func performRender(_ ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>, inTimeStamp: UnsafePointer<AudioTimeStamp>, inBufNumber: UInt32, inNumberFrames: UInt32, ioData: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        
        let ioPtr = UnsafeMutableAudioBufferListPointer(ioData)
        var err: OSStatus = noErr
        
        if audioChainIsBeingReconstructed { return err }
        
        // we are calling AudioUnitRender on the input bus of AURemoteIO
        // this will store the audio data captured by the microphone in ioData
        err = AudioUnitRender(rioUnit!, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData)
        
        // filter out the DC component of the signal
        //dcRejectionFilter?.processInplace(ioPtr[0].mData!.assumingMemoryBound(to: Float32.self), numFrames: inNumberFrames)
        
        if displayMode == .timeDomain {
            // time domain waveform
            bufferManager.copyAudioDataToDrawBuffer(ioPtr[0].mData?.assumingMemoryBound(to: Float32.self), inNumFrames: Int(inNumberFrames))
        } else {
            // freq domain waveform
            if bufferManager.doesNeedNewFFTData {
                bufferManager.copyAudioDataToFFTInputBuffer(ioPtr[0].mData!.assumingMemoryBound(to: Float32.self), numFrames: Int(inNumberFrames))
            }
        }
        
        // ioData is both input AND output param
        // mute audio if set
        if muted {
            for i in 0..<ioPtr.count {
                memset(ioPtr[i].mData, 0, Int(ioPtr[i].mDataByteSize))
            }
        } else {
            
            let audioOut: UnsafeMutablePointer<Float32> = ioPtr[0].mData!.assumingMemoryBound(to: Float32.self)
            let numFrames = Int(inNumberFrames)
            
            var neg: Float = 1.0
            var ctr = 0
            let maxCtr = 15 // represents freq somehow...
            for i in 0..<numFrames {
                let newOutVal = (outputWave.amplitude*0.3  *   neg   )
                //print("orig: \(audioOut[i]) new: \(newOutVal)")
                audioOut[i] = newOutVal
                
                ctr += 1
                if ctr >= maxCtr {
                    ctr = 0
                    neg *= -1
                }
            }

        }
        
        return err;
    }
    
    ////////////////////////////////////////////////////////////////////////////

    func playButtonPressedSound() {
        createButtonPressedSound()
        audioPlayer?.play()
    }
    
    private func createButtonPressedSound() {
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "button_press", ofType: "caf")!)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
        } catch {
            print("Error info: \(error)")
        }
        
    }
    
    func getDrawBuffer() -> (UnsafeMutablePointer<Float32>?, Int) {
        switch displayMode {
        case .timeDomain:
            return (data: bufferManager.drawBuffer, size: bufferManager.maxFrames)
            
        case .freqDomain:
            if bufferManager.doesHaveNewFFTData {
                bufferManager.getFFTOutput(FFTData)
                return (data: FFTData, size: bufferManager.FFTOutputBufferLength)
            } else {
                return (data: nil, size: -1)
            }
        }
        
    }
}


////////////////////////////////////////////////////////////////////////////


@objc protocol AURenderCallbackDelegate {
    func performRender(_ ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                       inTimeStamp: UnsafePointer<AudioTimeStamp>,
                       inBufNumber: UInt32,
                       inNumberFrames: UInt32,
                       ioData: UnsafeMutablePointer<AudioBufferList>) -> OSStatus
}

private let AudioController_RenderCallback: AURenderCallback = {(inRefCon,
    ioActionFlags/*: UnsafeMutablePointer<AudioUnitRenderActionFlags>*/,
    inTimeStamp/*: UnsafePointer<AudioTimeStamp>*/,
    inBufNumber/*: UInt32*/,
    inNumberFrames/*: UInt32*/,
    ioData/*: UnsafeMutablePointer<AudioBufferList>*/)
    -> OSStatus
    in
    let delegate = unsafeBitCast(inRefCon, to: AURenderCallbackDelegate.self)
    let result = delegate.performRender(ioActionFlags,
                                        inTimeStamp: inTimeStamp,
                                        inBufNumber: inBufNumber,
                                        inNumberFrames: inNumberFrames,
                                        ioData: ioData!)
    return result
}



//	This is a macro that does a sizeof and casts the result to a UInt32. This is useful for all the
//	places where -wshorten64-32 catches assigning a sizeof expression to a UInt32.
//	For want of a better place to park this, we'll park it here.
func SizeOf32<T>(_ X: T) ->UInt32 {return UInt32(MemoryLayout<T>.stride)}
func SizeOf32<T>(_ X: T.Type) ->UInt32 {return UInt32(MemoryLayout<T>.stride)}
