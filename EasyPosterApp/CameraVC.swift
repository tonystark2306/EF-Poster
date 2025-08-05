//
//  CameraVC.swift
//  EasyPosterApp
//
//  Created by iKame Elite Fresher 2025 on 8/4/25.
//

import UIKit
import AVFoundation

protocol CameraVCDelegate: AnyObject {
    func didCaptureImage(_ image: UIImage)
}

class CameraVC: UIViewController, AVCapturePhotoCaptureDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var switchCamButton: UIButton!
    @IBOutlet weak var galleryButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var previewView: UIView!
    
    private let captureSession = AVCaptureSession()
    private var outputPhoto = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var captureDevice: AVCaptureDevice?
    private var flashOn = 0

    weak var delegate: CameraVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        checkPermission()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer?.frame = previewView.bounds
    }
    
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCamera()
                    }
                }
            }
        default:
            showAlert()
        }
    }

    private func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(input) {
            captureSession.addInput(input)
                self.captureDevice = device
            }
        if captureSession.canAddOutput(outputPhoto) {
            captureSession.addOutput(outputPhoto)
        }
        
        captureSession.commitConfiguration()
        setupPreview()
        DispatchQueue.global().async {
            self.captureSession.startRunning()
        }
    }
    
    private func showAlert() {
        let alert = UIAlertController(title: "Cần quyền truy cập Camera", message: "Vui lòng cấp quyền truy cập Camera trong cài đặt", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewView.bounds
        previewView.layer.insertSublayer(previewLayer, at: 0)
    }
    
    @IBAction func didTappedFlash(_ sender: Any) {
        flashOn += 1
        var imageName = ""
        if (flashOn % 3 == 1) {
            imageName = "icFlashOn"
        }
        else if (flashOn % 3 == 2) {
            imageName = "icFlashAuto"
        }
        else {
            imageName = "icFlashOff"
        }
        flashButton.setImage(UIImage(named: imageName), for: .normal)
    }
    
    @IBAction func didTappedClose(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTappedCapture(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        if (flashOn % 3 == 1) {
            settings.flashMode = .on
        }
        else if (flashOn % 3 == 2) {
            settings.flashMode = .auto
        }
        else {
            settings.flashMode = .off
        }
        outputPhoto.capturePhoto(with: settings, delegate: self)
    }
    
    @IBAction func didTappedGallery(_ sender: Any) {
        
    }
    
    @IBAction func didTappedSwitch(_ sender: Any) {
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        
        captureSession.beginConfiguration()
        captureSession.removeInput(currentInput)
        
        let position: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        
        if let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
           let nextInput = try? AVCaptureDeviceInput(device: newDevice) {
            captureSession.addInput(nextInput)
            self.captureDevice = newDevice
        }
        captureSession.commitConfiguration()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("Lỗi: \(error!)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Could not convert photo to image")
            return
        }
        delegate?.didCaptureImage(image)
        navigationController?.popViewController(animated: true)
    }
    
}
