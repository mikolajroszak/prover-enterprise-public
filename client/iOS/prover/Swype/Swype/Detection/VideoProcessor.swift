import UIKit
import Common
import AVFoundation

protocol SwypeDetectorStateDelegate: class {
    func detectorDidChangeState(to: SwypeDetectorState?)
    func detectorDidChangeIndex(to: Int)
    func detectorDidUpdateFps(_ fps: Double)
}

protocol VideoRecorderDelegate: class {
    func process(buffer: CVImageBuffer, timestamp: CMTime, callingQueue: DispatchQueue)
    func recorderDidUpdateFps(_ fps: Double)
    
    func getSwypeCode() -> String?
    func getTimeStamps() -> [UInt]?
    func getMinProcessingTime() -> UInt
    func getMaxProcessingTime() -> UInt
    func getTotalFrames() -> UInt
    func getTotalTime() -> UInt
    func getSwypeHelperVersion() -> Int
    func recordFailed()
    func recordFinished(at url: URL)
    func metadataSaved(at url: URL, status: AVAssetExportSession.Status)
    
    var detectorXScale: Double { get }
    var detectorYScale: Double { get }
}

class VideoProcessor {

    private enum RecordingStatus {
        case idle, recording, finishing
    }

    private var sessionCaptureStarted: Bool = false

    //public var isCapturing: Bool { return videoRecorder.isRunning }
    //public var isFinishing: Bool { return recordingStatus == .finishing }
    public var isRecording: Bool { return recordingStatus == .recording }
    private var recordingStatus: RecordingStatus = .idle

    private var videoRecorder: VideoRecorder! {
        willSet {
            if newValue == nil {
                print("[VideoProcessor] self.videoRecorder will set to nil!")
            }
        }
        didSet {
            if videoRecorder == nil {
                print("[VideoProcessor] self.videoRecorder did set to nil!")
            }
        }
    }

    private var swypeDetector: SwypeDetector! {
        willSet {
            if newValue == nil {
                print("[VideoProcessor] self.swypeDetector will set to nil!")
            }
        }
        didSet {
            if swypeDetector == nil {
                print("[VideoProcessor] self.swypeDetector did set to nil!")
            }
        }
    }

    private(set) var videoURL: URL!

    private weak var delegate: VideoProcessorDelegate!
    private weak var coordinateDelegate: SwypeDetectorCoordinateDelegate!
    
    init(videoPreviewView: VideoPreviewView,
         coordinateDelegate: SwypeDetectorCoordinateDelegate,
         delegate: VideoProcessorDelegate) {

        videoRecorder = VideoRecorder(withParent: videoPreviewView, delegate: self)

        self.coordinateDelegate = coordinateDelegate
        self.delegate = delegate
    }

    deinit {
        print("[VideoProcessor] deinit")
    }
}

// MARK: - Public methods (Detector)
extension VideoProcessor {

    func setSwypeCode(_ code: String) {
        swypeDetector?.setSwypeCode(code)
    }
}

// MARK: - Public methods (Detector)
extension VideoProcessor {
    
    func startCapture() {
        guard !sessionCaptureStarted else {
            return
        }

        sessionCaptureStarted = true
        videoRecorder.startSession()
    }

    func stopCapture() {
        guard sessionCaptureStarted else {
            return
        }

        sessionCaptureStarted = false
        videoRecorder.stopSession()
    }
    
    func startRecord() {
        guard recordingStatus == .idle else {
            return
        }

        recordingStatus = .recording

        let frameSize = Settings.currentVideoOutputResolution

        swypeDetector = SwypeDetector(
                frameWidth: frameSize.width, frameHeight: frameSize.height,
                stateDelegate: self, coordinateDelegate: coordinateDelegate)

        videoURL = nil

        videoRecorder.startRecord()
    }
    
    func stopRecord() {
        guard recordingStatus == .recording else {
            return
        }

        recordingStatus = .finishing

        videoRecorder.stopRecord()
    }
}

// MARK: - VideoCameraDelegate
extension VideoProcessor: VideoRecorderDelegate {
    func process(buffer: CVImageBuffer, timestamp: CMTime, callingQueue: DispatchQueue) {
        switch delegate.controllerState {
        case .waitingForCode,
             .didReceiveCode,
             .waitingForCircle,
             .waitingToStartSwypeCode,
             .detectingSwypeCode:
            swypeDetector.process(buffer, timestamp: timestamp, callingQueue: callingQueue)

        case .requestingBalanceAndPriceOnAppearance,
             .readyToGetSwypeCode,
             .requestingBalanceAndPriceThenGetSwypeCode,
             .gettingSwypeCode,
             .finishingWithoutDetectedSwypeCode,
             .swypeCodeDetected,
             .finishingWithDetectedSwypeCode,
             .submittingMediaHash,
             .confirmingMediaHashSubmission:
            break
        }
    }
    
    func recorderDidUpdateFps(_ fps: Double) {
        delegate.recorderDidUpdateFps(fps)
    }

    func getSwypeCode() -> String? {
        return swypeDetector.getSwypeCode()
    }

    func getTimeStamps() -> [UInt]? {
        return swypeDetector.getTimeStamps()
    }

    func getMinProcessingTime() -> UInt {
        return swypeDetector.getMinProcessingTime()
    }

    func getMaxProcessingTime() -> UInt {
        return swypeDetector.getMaxProcessingTime()
    }

    func getTotalFrames() -> UInt {
        return swypeDetector.getTotalFrames()
    }

    func getTotalTime() -> UInt {
        return swypeDetector.getTotalTime()
    }

    func getSwypeHelperVersion() -> Int {
        return swypeDetector.getSwypeHelperVersion()
    }

    var detectorXScale: Double {
        return swypeDetector.detectorXScale
    }

    var detectorYScale: Double {
        return swypeDetector.detectorYScale
    }

    func recordFinished(at url: URL) {
        delegate.recordFinished()
    }

    func recordFailed() {
        delegate.recordFailed()
    }

    func metadataSaved(at url: URL, status: AVAssetExportSession.Status) {
        videoURL = (status == .completed) ? url : nil
        swypeDetector = nil
        recordingStatus = .idle

        delegate.metadataSaved(status: status)
    }
}

// MARK: - DetectorStateDelegate
extension VideoProcessor: SwypeDetectorStateDelegate {
    func detectorDidChangeState(to state: SwypeDetectorState?) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [unowned self] in
                self.detectorDidChangeState(to: state)
            }
            return
        }
        
        guard let state = state else {
            // Handle nil state here
            return
        }

        debugPrint("[VideoProcessor] Detector has changed state to", state, state.rawValue)

        switch state {
        case .waitingForCode:
            delegate.detectorDidChangeControllerState(to: .waitingForCode)
        case .waitingForCircle:
            delegate.detectorDidChangeControllerState(to: .waitingForCircle)
        case .waitingToStartSwypeCode:
            delegate.detectorDidChangeControllerState(to: .waitingToStartSwypeCode)
        case .detectingSwypeCode:
            delegate.detectorDidChangeControllerState(to: .detectingSwypeCode)
        case .swypeCodeDetected:
            delegate.detectorDidChangeControllerState(to: .swypeCodeDetected)
        }
    }

    func detectorDidChangeIndex(to index: Int) {
        delegate.detectorDidChangeSwypeIndex(to: index)
    }

    func detectorDidUpdateFps(_ fps: Double) {
        delegate.detectorDidUpdateFps(fps)
    }
}
