//
//  Skywaymanager.swift
//  SkywaySample
//
//  Created by Ryo Tabuchi on 2023/06/24.
//

import Foundation
import SkyWayRoom
import Vision

protocol SkywayManagerDelegate: AnyObject {
    func didPartnerJoined(videoStream: RemoteVideoStream?)
}
class SkywayManager: NSObject {
    
    enum SMError: Error {
        case createRoom
        case joinRoom
        case publishAudio
        case publishVideo
        
        var message: String {
            switch self {
            case .createRoom:
                return "トークルームの作成に失敗しました"
            case .joinRoom:
                return "トークルームへの参加に失敗しました"
            case .publishAudio:
                return "音声の配信に失敗しました"
            case .publishVideo:
                return "映像の配信に失敗しました"
            }
        }
    }
    
    private static let token: String = "発行されたtoken"
    
    private let firestoreManager = FirestoreManager()
    private var me: SkyWayRoom.LocalSFURoomMember?
    private var audioPublication: SkyWayRoom.RoomPublication? {
        me?.publications.first {
            $0.contentType == .audio
        }
    }
    
    private let captureSession = AVCaptureSession()
    
    var localVideoStream: LocalVideoStream?
    private var frameSource: CustomFrameVideoSource?
    
    var isMute: Bool = false {
        didSet {
            Task {
                do {
                    if isMute {
                        try await audioPublication?.disable()
                    } else {
                        try await audioPublication?.enable()
                    }
                } catch {
                    print("Failed to switch mute.")
                }
            }
        }
    }
    
    var useSpeaker: Bool = false {
        didSet {
            do {
                if useSpeaker {
                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                } else {
                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
                }
            } catch {
                print("Failed to switch speaker.")
            }
        }
    }
    
    var useBackground: Bool = false
    
    private var room: SFURoom? {
        didSet {
            room?.delegate = self
        }
    }
    
    weak var delegate: SkywayManagerDelegate?
    
    func createRoom(name: String,
                    password: String?) async -> Result<SSRoom, SMError> {
        do {
            try await Context.setup(withToken: Self.token,
                                    options: nil)
            let option = Room.InitOptions()
            guard let room: SFURoom = try? await .create(with: option) else {
                return .failure(.createRoom)
            }
            let ssRoom = SSRoom(id: room.id,
                                name: name,
                                password: password)
            try await firestoreManager.createRoom(room: ssRoom)
            
            try await join(room: room)
            
            return .success(ssRoom)
        } catch {
            return .failure(.joinRoom)
        }
    }
    
    func joinRoom(room ssRoom: SSRoom) async -> Result<SSRoom, SMError> {
        do {
            try await Context.setup(withToken: Self.token,
                                     options: nil)
            let query = SkyWayRoom.Room.Query()
            query.id = ssRoom.id
            let room: SFURoom = try await .find(by: query)
            
            try await join(room: room)
            
            return .success(ssRoom)
        } catch {
            print(error.localizedDescription)
            return .failure(.joinRoom)
        }
    }
    
    private func join(room: SFURoom) async throws {
        if let member = room.members.first(where: { member in
            member.metadata == UserDefaults.uuid
        }) {
            try? await member.leave()
        }
        let memberInit: Room.MemberInitOptions = .init()
        memberInit.name = UserDefaults.userName
        memberInit.metadata = UserDefaults.uuid
        let member = try await room.join(with: memberInit)
        me = member
        // AudioStreamの作成
        let auidoSource: MicrophoneAudioSource = .init()
        let audioStream = auidoSource.createStream()
        let _ = try await member.publish(audioStream, options: nil)
        
        let frameSource: CustomFrameVideoSource = .init()
        let localVideoStream: LocalVideoStream = frameSource.createStream()
        self.localVideoStream = localVideoStream
        self.frameSource = frameSource
        let _ = try await member.publish(localVideoStream, options: nil)
        startCaptureVideo()
        
        self.room = room
    }
    
    func leave() async {
        captureSession.stopRunning()
        try? await me?.leave()
        try? await room?.dispose()
        me = nil
        room = nil
        localVideoStream = nil
        frameSource = nil
        try? await Context.dispose()
    }
}

extension SkywayManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    private func startCaptureVideo() {
        // Cameraの設定
        guard let camera = CameraVideoSource.supportedCameras().first(where: { $0.position == .front }) else {
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                
                let videoDataOutput = AVCaptureVideoDataOutput()
                videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "queue"))
                videoDataOutput.alwaysDiscardsLateVideoFrames = true
                
                guard captureSession.canAddOutput(videoDataOutput) else { return }
                captureSession.addOutput(videoDataOutput)
                
                // アウトプットの画像を縦向きに変更（標準は横）
                for connection in videoDataOutput.connections {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                    }
                }
                
                captureSession.commitConfiguration()
                captureSession.startRunning()
            }
        } catch {
            
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        if #available(iOS 15.0, *), useBackground {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }
            let originalImage = CIImage(cvImageBuffer: imageBuffer)
            guard let pixelBuffer = originalImage.pixelBuffer else {
                return
            }
            let backgroundImage = CIImage(cgImage: UIImage(named: "background")!.cgImage!)
            lazy var personSegmentationRequest: VNGeneratePersonSegmentationRequest = {
                let request = VNGeneratePersonSegmentationRequest()
                request.qualityLevel = .fast
                request.outputPixelFormat = kCVPixelFormatType_OneComponent8
                return request
            }()
            let sequenceRequestHandler = VNSequenceRequestHandler()
            try? sequenceRequestHandler.perform([personSegmentationRequest],
                                                on: pixelBuffer,
                                                orientation: .up)
            guard let resultPixelBuffer = personSegmentationRequest.results?.first?.pixelBuffer else { return }
            var maskImage = CIImage(cvPixelBuffer: resultPixelBuffer)

            // 結果のマスクイメージはサイズが変わっているので、オリジナルか背景のサイズに合わせる
            let scaleX = originalImage.extent.width / backgroundImage.extent.width
            let scaleY = originalImage.extent.height / backgroundImage.extent.height
            let resizedBackgroundImage = backgroundImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
            let scaleXForMask = originalImage.extent.width / maskImage.extent.width
            let scaleYForMask = originalImage.extent.height / maskImage.extent.height
            maskImage = maskImage.transformed(by: .init(scaleX: scaleXForMask, y: scaleYForMask))

            let filter = CIFilter(name: "CIBlendWithMask", parameters: [
                        kCIInputImageKey: originalImage,
                        kCIInputBackgroundImageKey: resizedBackgroundImage,
                        kCIInputMaskImageKey: maskImage])
            
            if let outputImage = filter?.outputImage {
                CIContext(options: [.useSoftwareRenderer:false])
                    .render(outputImage,
                            to: imageBuffer,
                            bounds: outputImage.extent,
                            colorSpace: CGColorSpace(name: CGColorSpace.extendedSRGB))
                frameSource?.updateFrame(with: sampleBuffer)
            }
        } else {
            frameSource?.updateFrame(with: sampleBuffer)
        }
    }
}

extension SkywayManager: RoomDelegate {
    func roomPublicationListDidChange(_ room: SkyWayRoom.Room) {
        guard let me,
              let partner = room.members.first(where: { $0.id != me.id }),
              let audioPublication = partner.publications.first(where: { $0.contentType == .audio }),
              let videoPublication = partner.publications.first(where: { $0.contentType == .video }) else {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didPartnerJoined(videoStream: nil)
            }
            return
        }
        
        Task {
            guard let _ = try? await me.subscribe(publicationId: audioPublication.id, options: nil) else {
                print("[Tutorial] Subscribing failed.")
                return
            }
            print("🎉Subscribing audio stream successfully.")
            
            guard let videoSubscription = try? await me.subscribe(publicationId: videoPublication.id, options: nil) else {
                print("[Tutorial] Subscribing failed.")
                return
            }
            print("🎉Subscribing video stream successfully.")
            
            if let remoteVideoStream = videoSubscription.stream as? RemoteVideoStream {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.didPartnerJoined(videoStream: remoteVideoStream)
                }
            }
        }
    }
}

extension CVPixelBuffer {
    var sampleBuffer: CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?
        
        var timimgInfo  = CMSampleTimingInfo()
        var formatDescription: CMFormatDescription? = nil
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: self,
                                                     formatDescriptionOut: &formatDescription)
        guard let formatDescription else {
            return nil
        }
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: self,
            formatDescription: formatDescription,
            sampleTiming: &timimgInfo,
            sampleBufferOut: &sampleBuffer
        )
        return sampleBuffer
    }
}
