import AudioToolbox
//import libkern

class BufferManager {
    private(set) var drawBuffer: UnsafeMutablePointer<Float32>
    var maxFrames: Int { return FFTInputBufferLen }

    var doesHaveNewFFTData: Bool {return hasNewFFTData != 0}
    var doesNeedNewFFTData: Bool {return needsNewFFTData != 0}
    var FFTOutputBufferLength: Int {return FFTInputBufferLen / 2}
    
    private var FFTInputBuffer: UnsafeMutablePointer<Float32>?
    private var FFTInputBufferFrameIndex: Int
    private var FFTInputBufferLen: Int
    private var hasNewFFTData: Int32
    private var needsNewFFTData: Int32
    private let fft: FFTransformer
    
    init(maxFramesPerSlice inMaxFramesPerSlice: Int) {
        drawBuffer = UnsafeMutablePointer.allocate(capacity: Int(inMaxFramesPerSlice))
        
        FFTInputBuffer = nil
        FFTInputBufferFrameIndex = 0
        FFTInputBufferLen = inMaxFramesPerSlice
        hasNewFFTData = 0
        needsNewFFTData = 0
    
        FFTInputBuffer = UnsafeMutablePointer.allocate(capacity: Int(inMaxFramesPerSlice))
        fft = FFTransformer(maxFramesPerSlice: inMaxFramesPerSlice)
        OSAtomicIncrement32Barrier(&needsNewFFTData)
    }
    
    deinit {
        drawBuffer.deallocate(capacity: FFTInputBufferLen)
        FFTInputBuffer?.deallocate(capacity: FFTInputBufferLen)
    }
    
    func copyAudioDataToDrawBuffer(_ inData: UnsafePointer<Float32>?, inNumFrames: Int) {
        if inData == nil { return }
        
        for i in 0..<inNumFrames {
            drawBuffer[i] = (inData?[i])!
        }
    }
    
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
        fft.compute(FFTInputBuffer, outFFTData: outFFTData)
        FFTInputBufferFrameIndex = 0
        OSAtomicDecrement32Barrier(&hasNewFFTData)
        OSAtomicIncrement32Barrier(&needsNewFFTData)
    }
}
