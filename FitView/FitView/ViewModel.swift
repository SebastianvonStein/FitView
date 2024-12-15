//
//  ViewModel.swift
//  FitView
//
//  Created by Konstantin Freiherr von Stein on 10/27/24.
//

import Foundation
import SwiftUI
import CreateMLComponents
import Vision
import AVFoundation
import SceneKit

// Processed Pose Data
class ProcessedPoseData: Identifiable {
    var id = UUID()
    var x: Float
    var y: Float
    var z: Float
    var name: String
    
    init(x: Float, y: Float, z: Float, name: String) {
        self.x = x
        self.y = y
        self.z = z
        self.name = name
    }
    
    func debugDescription() -> String {
        return "\(name):\n    x: \(x)\n    y: \(y)\n    z: \(z)"
    }
}

enum Mode: String {
    case Situps, Lunges, Home, Squats, Pushups
}

class ViewModel: ObservableObject {

    // Data
    @Published var liveCamera: CGImage?
    @Published var livePose: VNHumanBodyPose3DObservation?
    @Published var sceneKitScene: SCNScene = SCNScene()
    @Published var processedData: [ProcessedPoseData]? // Can probably be removed if not debuging... Shouldn't need to be passed
    
    // Mode
    @Published var selectedMode: Mode = .Situps
    
    // State
    @Published var doingExercise: Bool = false
    
    // Distance Value
    @Published var distance: CGFloat = 0.59
    @Published var count: Int = 0
    
    // Variable Params
    @Published var goingToKnee: Bool = false
    
    @Published var goingDown: Bool = true
    private var trailingDistanceForLunges: [Bool] = [false, false]
    
    @Published var lowThreshold: CGFloat = 0.5
    @Published var highThreshold: CGFloat = 0.68
    
    
    private let session = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var ciContext = CIContext()
    
    private var displayCameraTask: Task<Void, Error>?
    
    private var displayImageTask: Task<Void, Error>?
    
    /// The camera configuration to define the basic camera position, pixel format, and resolution to use.
    private var configuration = VideoReader.CameraConfiguration()
    
    // MARK: - Public Funcs () - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    // Global Start
    public func startCapture() {
        setupCamera()
        //justSendVideo()
        doingExercise = true
        print("Global START ✅ - startCapture()")
    }

    
    // Global Stop
    public func stopCapture() {
        print("Global STOP ❎ - stopCapture()")
        doingExercise = false
        displayCameraTask?.cancel()
        displayImageTask?.cancel()
    }
    
    // Start Video
    public func startLiveVideo() {
        displayImageTask = Task {
            try await self.beginPassingCameraFeed()
        }
    }
    
    // Stop Video
    public func stopLiveVideo() {
        displayImageTask?.cancel()
    }
    
    // Start Analysis
    public func startLivePoseAnalysisPipeline() {
        displayCameraTask = Task {
            try await self.beginPoseExtraction()
        }
    }
    
    public func stopLivePoseAnalysisPipeline() {
        displayCameraTask?.cancel()
    }
    
    // MARK: - Private Funcs () - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    // Init Camera Task & PoseDisplay
    private func setupCamera() {
        print("Task & Camera Setup 🔄 - setupCamera()")
        
        if let displayCameraTask = displayCameraTask {
            displayCameraTask.cancel()
        }
        
        displayCameraTask = Task {
            try await self.beginPoseExtraction()
        }
        
    }
    
    private func justSendVideo() {
        displayImageTask = Task {
            try await self.beginPassingCameraFeed()
        }
    }
    
    private func beginPassingCameraFeed() async throws {
        let frameSequence = try await VideoReader.readCamera(configuration: configuration)
        
        for try await frame in frameSequence {
            
            if Task.isCancelled {
                return
            }
            
            if let cgImage = CIContext().createCGImage(frame.feature, from: frame.feature.extent) {
                await displayCamera(image: cgImage)
            }
        }
    }

    // MARK: - TASK DISPATCH REVISED -
    
    private func beginPoseExtraction() async throws {
        print("Frame Sequence, Pose Extraction and Publishing 🔄 - beginPoseExtraction()")
        
        let frameSequence = try await VideoReader.readCamera(configuration: configuration)
        var frameCount = 0
        
        for try await frame in frameSequence {
            
            if let cgImage = CIContext().createCGImage(frame.feature, from: frame.feature.extent) {
                await displayCamera(image: cgImage)
            }
            
            frameCount += 1
            if frameCount % 4 != 0 { continue }
            
            if Task.isCancelled {
                return
            }
            
            Task.detached(priority: .high) {
                guard let poses = self.performPoseExtraction(ciImage: frame.feature) else {
                    print("Unable to find Pose ‼️ - beginPoseExtraction()")
                    return
                }

                await MainActor.run {
                        let processedPoseData = self.convertRawPoseData(rawPose: poses)
                            self.displayData(data: processedPoseData)
                            self.displayPose(poses: poses)
                   
                    
                        if self.selectedMode == .Situps {
                            self.distance = self.calcDistanceToHeadFromKnees(poseData: self.processedData!)
                            self.calcSitupCount(
                                ldistance: self.distance,
                                lgoingToKnee: &self.goingToKnee,
                                llowThreshold: self.lowThreshold,
                                lhighThreshold: self.highThreshold,
                                count: &self.count
                            )
                        } else if self.selectedMode == .Squats {
                            self.distance = self.calculateAngleBetweenPoints(poseData: self.processedData!)
                            self.calcSquatCount(
                                distance: self.distance,
                                goingDown: &self.goingDown,
                                count: &self.count,
                                trailingHistory: &self.trailingDistanceForLunges
                            )
                        } else if self.selectedMode == .Pushups {
                            self.distance = self.calculateDistanceBetweenHandsAndHead(poseData: self.processedData!)
                            self.calcPushupCount(distance: self.distance, goingDown: &self.goingDown, count: &self.count, trailingHistory: &self.trailingDistanceForLunges)
                        }
                    }
            }
        }
        
        
    }
    


    private func performPoseExtraction(ciImage: CIImage) -> VNHumanBodyPose3DObservation? {
        
        func resizeCIImage(ciImage: CIImage) -> CIImage? {
            let scale: CGFloat = 0.3
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            return ciImage.transformed(by: transform)
        }
        
        guard let resizedCIImage = resizeCIImage(ciImage: ciImage) else { return nil }
        
        let request = VNDetectHumanBodyPose3DRequest()
        let requestHandler = VNImageRequestHandler(ciImage: resizedCIImage)
        
        do {
            try requestHandler.perform([request])
            if let returnedObservation = request.results?.first as? VNHumanBodyPose3DObservation {
                return returnedObservation
            }
        } catch {
            print("Unable to perform pose request ‼️ - \(error.localizedDescription) - performPoseExtraction()")
        }
        
        return nil
    }
    
    @MainActor func displayPose(poses: VNHumanBodyPose3DObservation) {
        self.livePose = poses
    }
    
    
    @MainActor func displayCamera(image: CGImage) {
        self.liveCamera = image
    }
    
    @MainActor func displayData(data: [ProcessedPoseData]) {
        self.processedData = data
    }
    
    func convertRawPoseData(rawPose: VNHumanBodyPose3DObservation) -> [ProcessedPoseData] {
        var localFunctionPose: [ProcessedPoseData] = []
        for jointName in rawPose.availableJointNames {
            let data: SIMD4<Float> = try! rawPose.recognizedPoint(jointName).position.columns.3
            let newProcessedElement = ProcessedPoseData(x: data.x, y: data.y, z: data.z, name: jointName.rawValue.rawValue)
            //print(newProcessedElement.debugDescription())
            localFunctionPose.append(newProcessedElement)
        }
        return localFunctionPose
    }

    // MARK: SITUPS -

    func calcDistanceToHeadFromKnees(poseData: [ProcessedPoseData]) -> CGFloat {
        // Find the points for the right knee, left knee, and center head
        guard let rightKnee = poseData.first(where: { $0.name == "human_right_knee_3D" }),
              let leftKnee = poseData.first(where: { $0.name == "human_left_knee_3D" }),
              let centerHead = poseData.first(where: { $0.name == "human_center_head_3D" }) else {
            fatalError("Required points not found in pose data")
        }
        // Avg. Cords of Knees
        let avgX = (rightKnee.x + leftKnee.x) / 2
        let avgY = (rightKnee.y + leftKnee.y) / 2
        let avgZ = (rightKnee.z + leftKnee.z) / 2
        // Euclidean distance to head...
        let deltaX = centerHead.x - avgX
        let deltaY = centerHead.y - avgY
        let deltaZ = centerHead.z - avgZ
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)
        // Ret
        return CGFloat(distance)
    }
    
    
    func calcSitupCount(ldistance: CGFloat, lgoingToKnee: inout Bool, llowThreshold: CGFloat, lhighThreshold: CGFloat, count: inout Int) {
        if lgoingToKnee == true {
            if ldistance < llowThreshold {
                lgoingToKnee = false
                count += 1
            }
        } else {
            if ldistance > lhighThreshold {
                lgoingToKnee = true
            }
        }
    }
    
  
    
    // MARK: SQUATS -
    func calculateAngleBetweenPoints(poseData: [ProcessedPoseData]) -> CGFloat {
        
        // Processe Pose Data
        guard let bottom = poseData.first(where: { $0.name == "human_right_ankle_3D" }),
              let center = poseData.first(where: { $0.name == "human_left_knee_3D" }),
              let top = poseData.first(where: { $0.name == "human_root_3D" }) else {
            fatalError("Required points not found in pose data")
        }
        // Vectors
        let vector1 = (x: bottom.x - center.x, y: bottom.y - center.y, z: bottom.z - center.z)
        let vector2 = (x: top.x - center.x, y: top.y - center.y, z: top.z - center.z)
        // Dot product of the vectors
        let dotProduct = vector1.x * vector2.x + vector1.y * vector2.y + vector1.z * vector2.z
        // Magnitudes
        let magnitude1 = sqrt(vector1.x * vector1.x + vector1.y * vector1.y + vector1.z * vector1.z)
        let magnitude2 = sqrt(vector2.x * vector2.x + vector2.y * vector2.y + vector2.z * vector2.z)
        // coisne
        let cosineAngle = dotProduct / (magnitude1 * magnitude2)
        let clampedCosineAngle = max(min(cosineAngle, 1.0), -1.0)
        // Ang rad -> degs...
        let angleInRadians = acos(clampedCosineAngle)
        let angleInDegrees = angleInRadians * 180 / .pi
        // Ret
        return CGFloat(angleInDegrees)
    }
    
    func calcSquatCount(distance: CGFloat, goingDown: inout Bool, count: inout Int, trailingHistory: inout [Bool]) {
        if goingDown == true {
            // Not ideal method of confirming trailing distance condition but works...
            // Same approach in cal pushup... Helps reduce momentary "stutters" form triggering counts.
            if distance < 70 && trailingHistory[0] == false {
                trailingHistory[0] = true
            }
            if distance < 70 && trailingHistory[1] == false {
                trailingHistory[1] = true
            }
            if trailingHistory[0] == true && trailingHistory[1] == true && distance < 70 {
                count += 1
                goingDown = false
            }
            
        } else {
            if distance > 110 {
                goingDown = true
            }
        }
    }
    
    // MARK: PUSHUPS -
    func calculateDistanceBetweenHandsAndHead(poseData: [ProcessedPoseData]) -> CGFloat {
        // Find the points for the right knee, left knee, and center head
        guard let rightHand = poseData.first(where: { $0.name == "human_right_wrist_3D" }),
              let leftHand = poseData.first(where: { $0.name == "human_left_wrist_3D" }),
              let centerHead = poseData.first(where: { $0.name == "human_center_head_3D" }) else {
            fatalError("Required points not found in pose data")
        }
        // Avg. the Hands
        let avgX = (rightHand.x + leftHand.x) / 2
        let avgY = (rightHand.y + leftHand.y) / 2
        let avgZ = (rightHand.z + leftHand.z) / 2
        // Euclidean distance to haed...
        let deltaX = centerHead.x - avgX
        let deltaY = centerHead.y - avgY
        let deltaZ = centerHead.z - avgZ
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)
        // Ret
        return CGFloat(distance)
    }
    
    func calcPushupCount(distance: CGFloat, goingDown: inout Bool, count: inout Int, trailingHistory: inout [Bool]) {
        if goingDown == true {
            // Not ideal method of confirming trailing distance condition but works...
            if distance < 0.48 && trailingHistory[0] == false {
                trailingHistory[0] = true
            }
            if distance < 0.48 && trailingHistory[1] == false {
                trailingHistory[1] = true
                count += 1
                goingDown = false
            }
            /* if trailingHistory[0] == true && trailingHistory[1] == true && distance < 0.48 { ... } */
        } else {
            if distance > 0.55 { goingDown = true; trailingHistory = [false, false] }
        }
    }
    
    // MARK: - - - SCENEKIT - CURRENTLY UNUSED - - -
    
    public func removeAll(scene: SCNScene) {
        scene.rootNode.childNodes.forEach { node in
            node.removeFromParentNode()
        }
    }
    
    func addJointsToSceneKit(scene: SCNScene, joints: [ProcessedPoseData]) {
        print(joints.count)
        
        let redMaterial = SCNMaterial()
        let blueMaterial = SCNMaterial()
        let greenMaterial = SCNMaterial()
        #if os(macOS)
        redMaterial.diffuse.contents = NSColor.red
        blueMaterial.diffuse.contents = NSColor.blue
        greenMaterial.diffuse.contents = NSColor.green
        #elseif os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
        redMaterial.diffuse.contents = UIColor.red
        blueMaterial.diffuse.contents = UIColor.blue
        greenMaterial.diffuse.contents = UIColor.green
        #endif
        
        joints.forEach { (joint) in
            let sphere = SCNSphere(radius: 0.05)
            if joint.name.contains("head") {
                sphere.radius = 0.1
            } else if joint.name.contains("knee") {
                sphere.radius = 0.1
            }
            
            if joint.name.contains("right") {
                sphere.materials = [redMaterial]
            } else if joint.name.contains("left") {
                sphere.materials = [blueMaterial]
            } else {
                sphere.materials = [greenMaterial]
            }
            let node = SCNNode(geometry: sphere)
            node.position = SCNVector3(joint.x, joint.y, joint.z)
            scene.rootNode.addChildNode(node)
        }
    }

    
    
    // MARK: - - - TESTING - CURRENTLY UNUSED - - -
    
    // TESTING ONLY - PERFORM POSE EXTRACTION ON ASSET IMAGE
    public func runWithTestImage() {
        let testCGImage: CGImage? = convertToCGImage(imageName: "LexiTest")
        runHumanBodyPose3DRequestOnImage(image: testCGImage)
    
    }

    // TESTING ONLY - POSE EXTRACTION ON ASSET IMAGE
    private func runHumanBodyPose3DRequestOnImage(image: CGImage?) {
        if let image = image {
            let request = VNDetectHumanBodyPose3DRequest()
            let requestHandler = VNImageRequestHandler(cgImage: image)
            do {
                try requestHandler.perform([request])
                if let returnedObservation = request.results?.first as? VNHumanBodyPose3DObservation {
                    self.livePose = returnedObservation
                    self.liveCamera = image
                }
            } catch {
                print("unable to perform request: \(error.localizedDescription)")
            }
        }
    }
    
    // TESTING ONLY - IMAGE CONVERSION
    private func convertToCGImage(imageName: String) -> CGImage? {
        #if os(iOS)
        let uiImage = UIImage(named: imageName)
        return uiImage?.cgImage
        #elseif os(macOS)
        guard let nsImage = NSImage(named: imageName) else { return nil }
        var rect = NSRect(origin: .zero, size: nsImage.size)
        return nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil)
        #endif
    }
}

