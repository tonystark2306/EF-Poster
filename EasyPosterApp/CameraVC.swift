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
    
    private var flashMode: AVCaptureDevice.FlashMode = .off {
        didSet {
            updateFlashButton()
        }
    }

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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
        let alert = UIAlertController(title: "Camera Permission Required", message: "Please allow camera permission in settings", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewView.bounds
        previewView.layer.insertSublayer(previewLayer, at: 0)
    }
    
    private func updateFlashButton() {
        let imageName: String
        switch flashMode {
        case .on:
            imageName = "icFlashOn"
        case .auto:
            imageName = "icFlashAuto"
        case .off:
            imageName = "icFlashOff"
        @unknown default:
            imageName = "icFlashOff"
        }
        flashButton.setImage(UIImage(named: imageName), for: .normal)
    }
    
    @IBAction func didTappedFlash(_ sender: Any) {
        switch flashMode {
        case .off:
            flashMode = .on
        case .on:
            flashMode = .auto
        case .auto:
            flashMode = .off
        @unknown default:
            flashMode = .off
        }
    }
    
    @IBAction func didTappedClose(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTappedCapture(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
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
            print("Error: \(error!)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("error")
            return
        }
        delegate?.didCaptureImage(image)
        navigationController?.popViewController(animated: true)
    }
    
}
