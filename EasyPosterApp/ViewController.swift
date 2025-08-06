import UIKit
import PhotosUI
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet var originnalImageView: [UIImageView]!
    @IBOutlet var nameTextFields: [UITextField]!
    @IBOutlet weak var finalImageView: UIImageView!
    
    private var listImage: [UIImage] = [] {
        didSet {
            updateImageViews()
        }
    }
    
    private var listText: [NSAttributedString] {
        return nameTextFields.map({
            .init(string: $0.text ?? "Khuyết danh", attributes: textAttributes)
        })
    }
    
    private var finalImage: UIImage?
    
    lazy var textAttributes: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return [
            .font: UIFont.systemFont(ofSize: 16, weight: .heavy),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.white
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Reset",
            style: .plain,
            target: self,
            action: #selector(resetImages)
        )
    }
    
    private func updateImageViews() {
        originnalImageView.forEach { imageView in
            if imageView.tag < listImage.count {
                imageView.image = listImage[imageView.tag]
            } else {
                imageView.image = nil
            }
        }
    }
    
    @objc private func resetImages() {
        let alert = UIAlertController(
            title: "Reset Images",
            message: "Bạn có chắc muốn xóa tất cả ảnh và bắt đầu lại?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            self.listImage.removeAll()
            self.finalImage = nil
            self.finalImageView.image = nil
            self.nameTextFields.forEach { $0.text = "" }
        })
        
        present(alert, animated: true)
    }

    @IBAction func tapUpload(_ sender: UIButton) {
        let alert = UIAlertController(title: "Select Options", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Take Photos", style: .default, handler: { _ in
            self.requestCameraPermissionAndOpenCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default, handler: { _ in
            self.openPhotoLibrary()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func openPhotoLibrary() {
        var config = PHPickerConfiguration()
        let remainingSlots = max(0, 5 - listImage.count)
        
        guard remainingSlots > 0 else {
            showAlert(title: "Đã đủ ảnh", message: "Bạn đã có đủ 5 ảnh. Hãy reset để chọn ảnh mới.")
            return
        }
        
        config.selectionLimit = remainingSlots
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func requestCameraPermissionAndOpenCamera() {
        guard listImage.count < 5 else {
            showAlert(title: "Đã đủ ảnh", message: "Bạn đã có đủ 5 ảnh. Hãy reset để chụp ảnh mới.")
            return
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            openCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    granted ? self.openCamera() : self.showPermissionAlert()
                }
            }
        default:
            showPermissionAlert()
        }
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Lỗi", message: "Camera không khả dụng")
            return
        }
        let cameraPicker = CameraVC()
        cameraPicker.delegate = self
        navigationController?.pushViewController(cameraPicker, animated: true)
    }

    private func showPermissionAlert() {
        showAlert(title: "Camera Permission Required", message: "Please allow camera permission in Settings")
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func tapCreatePoster(_ sender: UIButton) {
        let frame = finalImageView.bounds
        let textBoundHeight: CGFloat = 24
        let width = frame.width
        let height = frame.height - textBoundHeight
        let renderer = UIGraphicsImageRenderer(bounds: frame)
        
        guard listImage.count == 5 else {
            showAlert(title: "Chưa đủ ảnh", message: "Cần đủ 5 ảnh để tạo poster. Hiện tại: \(listImage.count)/5 ảnh.")
            return
        }
        
        let image = renderer.image { context in
            let frame1 = CGRect(x: 0, y: 0, width: width * 1/4, height: height)
            listImage[0].draw(in: frame1)
            
            let frame5 = CGRect(x: width * 3/4, y: 0, width: width * 1/4, height: height)
            listImage[4].draw(in: frame5)
            
            let rectPath = UIBezierPath()
            rectPath.move(to: CGPoint(x: width/7, y: 0))
            rectPath.addLine(to: CGPoint(x: width * 3/7, y: 0))
            rectPath.addLine(to: CGPoint(x: width * 3/8, y: height))
            rectPath.addLine(to: CGPoint(x: width * 1/4, y: height))
            rectPath.close()
            rectPath.addClip()
            
            let frame2 = CGRect(x: width * 1/7, y: 0, width: width * 2/7, height: height)
            listImage[1].draw(in: frame2)
            
            UIGraphicsGetCurrentContext()?.resetClip()
            
            let rectPath2 = UIBezierPath()
            rectPath2.move(to: CGPoint(x: width * 3/7, y: 0))
            rectPath2.addLine(to: CGPoint(x: width * 4/7, y: 0))
            rectPath2.addLine(to: CGPoint(x: width * 5/8, y: height))
            rectPath2.addLine(to: CGPoint(x: width * 3/8, y: height))
            rectPath2.close()
            rectPath2.addClip()
            
            let frame3 = CGRect(x: width * 3/8, y: 0, width: width/4, height: height)
            listImage[2].draw(in: frame3)
            
            UIGraphicsGetCurrentContext()?.resetClip()
            
            let rectPath3 = UIBezierPath()
            rectPath3.move(to: CGPoint(x: width * 4/7, y: 0))
            rectPath3.addLine(to: CGPoint(x: width * 6/7, y: 0))
            rectPath3.addLine(to: CGPoint(x: width * 3/4, y: height))
            rectPath3.addLine(to: CGPoint(x: width * 5/8, y: height))
            rectPath3.close()
            rectPath3.addClip()
            
            let frame4 = CGRect(x: width * 4/7, y: 0, width: width * 2/7, height: height)
            listImage[3].draw(in: frame4)
            
            UIGraphicsGetCurrentContext()?.resetClip()
            
            let borderPath = UIBezierPath()
            borderPath.move(to: CGPoint(x: width/7, y: 0))
            borderPath.addLine(to: CGPoint(x: width/4, y: height))
            borderPath.move(to: CGPoint(x: width * 3/7, y: 0))
            borderPath.addLine(to: CGPoint(x: width * 3/8, y: height))
            borderPath.move(to: CGPoint(x: width * 4/7, y: 0))
            borderPath.addLine(to: CGPoint(x: width * 5/8, y: height))
            borderPath.move(to: CGPoint(x: width * 6/7, y: 0))
            borderPath.addLine(to: CGPoint(x: width * 3/4, y: height))
            
            UIColor.white.setStroke()
            borderPath.lineWidth = 4
            borderPath.stroke()
            
            UIColor.systemBrown.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: height, width: width, height: textBoundHeight)).fill()
            
            listText[0].draw(in: CGRect(x: 0, y: height, width: width/3, height: textBoundHeight))
            listText[1].draw(in: CGRect(x: width/3, y: height, width: width/3, height: textBoundHeight))
            listText[2].draw(in: CGRect(x: width * 2/3, y: height, width: width/3, height: textBoundHeight))
        }
        finalImage = image
        finalImageView.image = image
    }
    
    @IBAction func tapSave(_ sender: UIButton) {
        guard let savedImage = finalImage else {
            showAlert(title: "Chưa có poster", message: "Hãy tạo poster trước khi lưu.")
            return
        }
        UIImageWriteToSavedPhotosAlbum(savedImage, nil, nil, nil)
        showAlert(title: "Đã lưu", message: "Poster đã được lưu vào thư viện ảnh.")
    }
}

extension ViewController: CameraVCDelegate {
    func didCaptureImage(_ image: UIImage) {
        if listImage.count < 5 {
            listImage.append(image)
        }
    }
}

extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        var loadedImages: [UIImage] = []
        let dispatchGroup = DispatchGroup()
        
        results.forEach { result in
            dispatchGroup.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                if let img = image as? UIImage {
                    loadedImages.append(img)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            for image in loadedImages {
                if self.listImage.count < 5 {
                    self.listImage.append(image)
                } else {
                    break
                }
            }
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            if listImage.count < 5 {
                listImage.append(image)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
