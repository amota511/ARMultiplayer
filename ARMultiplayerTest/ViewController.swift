//
//  ViewController.swift
//  ARMultiplayerTest
//
//  Created by amota511 on 11/21/17.
//  Copyright © 2017 Aaron Motayne. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var plane : SCNNode!
    
    var stringURL = String()
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    var timer = Timer()
    
    enum error: Error {
        case noCameraAvailable
        case videoInputInitFail
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]//, ARSCNDebugOptions.showWorldOrigin]
        // Create a new scene
        let scene = SCNScene(named: "Drachen.scn")!
        
        
        // Set the scene to the view
        sceneView.scene = scene
        
        addTapGestureToSceneView()
        scheduledTimerWithTimeInterval()
        addBottomSpacePlane()
        
        //setUpQRReader()
        
    }
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    func setUpQRReader() {
        
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            //Get an instance of the AVCpatureDeviceInput class using the previous device object
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session:captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                
                view.addSubview(qrCodeFrameView)
                view.bringSubview(toFront: qrCodeFrameView)
            }
            
        } catch {
            print(error)
            return
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            
            // Check if the metadataObjects array is not nil and it contains at least one object.
            if metadataObjects == nil || metadataObjects.count == 0 {
                qrCodeFrameView?.frame = CGRect.zero
                print("No QR code is detected")
                return
            }
            
            // Get the metadata object.
            let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            if metadataObj.type == AVMetadataObject.ObjectType.qr {
                // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
                let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
                qrCodeFrameView?.frame = barCodeObject!.bounds
                
                if metadataObj.stringValue != nil {
                    //messageLabel.text = metadataObj.stringValue
                    print(metadataObj.stringValue)
                }
            }
        }
    }
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    func scheduledTimerWithTimeInterval() {
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(featurePointScan), userInfo: nil, repeats: true)
    }
    
    
    @objc func featurePointScan() {
        
        checkFeaturePointsAtCenterScreen()
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(stopFeaturePointScan))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func stopFeaturePointScan() {
        timer.invalidate()
    }
    
    func checkFeaturePointsAtCenterScreen() {
        
        let centerLocation = sceneView.center
        let hitTestResultsWithFeaturePoints = sceneView.hitTest(centerLocation, types: .featurePoint)
        
        if hitTestResultsWithFeaturePoints.first != nil {
            
            print("Feature points found")
//            featureFoundIndicatorSquare?.isHidden = true
//            updateFeatureFoundDesctionLabel(text: "Tap The Screen Where You Would Like To Place The Solar System")
//            featurePointFound = true
//            featureFoundIndicatorSquare?.layer.removeAllAnimations()
            
            let hitTestResultWithFeaturePoints = hitTestResultsWithFeaturePoints.last!
            let translation = hitTestResultWithFeaturePoints.worldTransform.translation
            
            //sceneView.session.add(anchor: hitTestResultWithFeaturePoints.anchor!)
            updatePlaneLocation(x: translation.x, y: translation.y, z: translation.z)
        } else {
            print("Could NOT find feature points")
//            featureFoundIndicatorSquare?.isHidden = false
//            updateFeatureFoundDesctionLabel(text: "For Best Results Point Camera At A Flat Surface Then Slowly Move Camera Closer To Then Further Away From The surface Until The Square Disapears")
//            featurePointFound = false
            hidePlane()
        }
    }
    
    func addBottomSpacePlane() {
        
        let planeGeo = SCNPlane(width: 0.22, height: 0.22)
        planeGeo.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "green-black-grid")
        planeGeo.firstMaterial?.isDoubleSided = true
        plane = SCNNode(geometry: planeGeo)
        plane.runAction(SCNAction.rotateBy(x: 1.5708, y: 0, z: 0, duration: 0.0))
        
        
        sceneView.scene.rootNode.addChildNode(plane)
        
        createDragon()
        createTroll()
        //addPlanet()
    }
    /////////
    var node: SCNNode!
    var animations = [String: CAAnimation]()
    
    func createDragon() {
        
        let dragon = sceneView.scene.rootNode.childNode(withName: "run", recursively: true)!
        dragon.removeFromParentNode()
        
        plane.addChildNode(dragon)
        node = dragon
        
        dragon.scale = SCNVector3(0.001,0.001,0.001)
        dragon.position = SCNVector3(0,0.075,-0.01)
        
        dragon.runAction(SCNAction.rotateBy(x: -1.5708, y: 0, z: 1.5708 * 2, duration: 0.0))
        
        for anim in node.animationKeys {
            animations["\(anim)"] = node.animation(forKey: "\(anim)")
        }
        
        print(dragon.animationKeys, dragon.actionKeys)
        
        walk()
    }
    
    func playAnimation(named: String){ //also works for armature
        if let animation = animations[named] {
            node.addAnimation(animation, forKey: named)
            
        }
    }
    
    func walk() {
        
        node.removeAnimation(forKey: "walk")
        //  node.removeAnimationForKey("rest", fadeOutDuration: 0.3)
        playAnimation(named: "run")
//        let run = SCNAction.repeatForever(SCNAction.moveBy(x: 0, y: 0, z: 12, duration: 1))
//        run.timingMode = .easeInEaseOut //ease the action in to try to match the fade-in and fade-out of the animation
//        node.runAction(run, forKey: "run")
    }
    /////////////
    func createTroll() {
        
        let scene = SCNScene(named: "troll.scn")!
        
        let troll = scene.rootNode.childNode(withName: "Armature", recursively: true)!
        troll.removeFromParentNode()
        
        plane.addChildNode(troll)
        
        troll.scale = SCNVector3(0.001,0.001,0.001)
        troll.position = SCNVector3(0,-0.075,-0.001)

        //troll.runAction(SCNAction.rotateBy(x: 1.5708 * 2, y: 0, z: 0, duration: 0.0))
        
        troll.rotate(by: SCNQuaternion(1.000,0.027,0.0,0.0), aroundTarget: troll.position)
        //troll.removeAllActions()
        print(troll.animationKeys, "/////////////////////")
    }
    
    func addPlanet() {
        
        let planet = SCNSphere(radius: 0.05)
        planet.firstMaterial?.diffuse.contents = UIColor(red: 45.0/255.0, green: 160.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        //planet.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "pluto")
        //planet.firstMaterial?.locksAmbientWithDiffuse = false
        //planet.firstMaterial?.ambient.contents = UIColor.black
        
        let planetNode = SCNNode(geometry: planet)
        planetNode.position = SCNVector3(0,0,-0.1)//SCNVector3(-9.4,0,0)
        plane.addChildNode(planetNode)
        
        floatBody(body: planetNode)
    }
    
    func floatBody(body: SCNNode) {
        
        
        let lowerAction = SCNAction.move(by: SCNVector3(0,0,-0.01), duration: 1.0)
        let raiseAction = SCNAction.move(by: SCNVector3(0,0,0.01), duration: 1.0)
        //SCNAction.moveBy(x: 0, y: 0, z: 0.005, duration: 1.0)
        //rotateBy(x: 0, y: CGFloat(2 * Double.pi), z: 0, duration: 5)
        let actionGroup = SCNAction.sequence([lowerAction,raiseAction])
        let action = SCNAction.repeatForever(actionGroup)
        
        body.runAction(action, forKey: "myrotate")
    }
    
    func updatePlaneLocation(x: Float, y: Float, z: Float) {
        plane.position = SCNVector3(x,y,z)
        plane.isHidden = false
    }
    
    func hidePlane() {
        plane.isHidden = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
   
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}
