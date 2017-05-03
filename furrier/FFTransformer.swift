//
//  FFTransformer.swift
//  furrier
//

import Accelerate

class FFTransformer {
    
    //  From: aurioTouch
    private var mSpectrumAnalysis: FFTSetup?
    private var mDspSplitComplex: DSPSplitComplex
    private var mFFTNormFactor: Float32
    private var mFFTLength: vDSP_Length
    private var mLog2N: vDSP_Length
    
    
    private final var kAdjust0DB: Float32 = 1.5849e-13
    
    
    init(maxFramesPerSlice inMaxFramesPerSlice: Int) {
        mSpectrumAnalysis = nil
        mFFTNormFactor = 1.0/Float32(2*inMaxFramesPerSlice)
        mFFTLength = vDSP_Length(inMaxFramesPerSlice)/2
        mLog2N = vDSP_Length(log2Ceil(UInt32(inMaxFramesPerSlice)))
        mDspSplitComplex = DSPSplitComplex(
            realp: UnsafeMutablePointer.allocate(capacity: Int(mFFTLength)),
            imagp: UnsafeMutablePointer.allocate(capacity: Int(mFFTLength))
        )
        mSpectrumAnalysis = vDSP_create_fftsetup(mLog2N, FFTRadix(kFFTRadix2))
    }
    
    
    deinit {
        vDSP_destroy_fftsetup(mSpectrumAnalysis)
        mDspSplitComplex.realp.deallocate(capacity: mFFTLength.l)
        mDspSplitComplex.imagp.deallocate(capacity: mFFTLength.l)
    }
    
    
    func compute(_ inAudioData: UnsafePointer<Float32>?, outFFTData: UnsafeMutablePointer<Float32>?) {
        guard
            let inAudioData = inAudioData,
            let outFFTData = outFFTData
            else { return }
        
        //Generate a split complex vector from the real data
        inAudioData.withMemoryRebound(to: DSPComplex.self, capacity: Int(mFFTLength)) {inAudioDataPtr in
            vDSP_ctoz(inAudioDataPtr, 2, &mDspSplitComplex, 1, mFFTLength)
        }
        
        //Take the fft and scale appropriately
        vDSP_fft_zrip(mSpectrumAnalysis!, &mDspSplitComplex, 1, mLog2N, FFTDirection(kFFTDirection_Forward))
        vDSP_vsmul(mDspSplitComplex.realp, 1, &mFFTNormFactor, mDspSplitComplex.realp, 1, mFFTLength)
        vDSP_vsmul(mDspSplitComplex.imagp, 1, &mFFTNormFactor, mDspSplitComplex.imagp, 1, mFFTLength)
        
        //Zero out the nyquist value
        mDspSplitComplex.imagp[0] = 0.0
        
        //Convert the fft data to dB
        vDSP_zvmags(&mDspSplitComplex, 1, outFFTData, 1, mFFTLength)
        
        //In order to avoid taking log10 of zero, an adjusting factor is added in to make the minimum value equal -128dB
        vDSP_vsadd(outFFTData, 1, &kAdjust0DB, outFFTData, 1, mFFTLength)
        var one: Float32 = 1
        vDSP_vdbcon(outFFTData, 1, &one, outFFTData, 1, mFFTLength, 0)
    }

    
    
}
