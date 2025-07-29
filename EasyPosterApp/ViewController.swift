//
//  ViewController.swift
//  EasyPosterApp
//
//  Created by Trần Đạt on 26/7/25.
//

import UIKit
import PhotosUI

class ViewController: UIViewController {
    @IBOutlet var originnalImageView: [UIImageView]!
    @IBOutlet var nameTextFields: [UITextField]!
    @IBOutlet weak var finalImageView: UIImageView!
    
    private var listImage: [UIImage] = [] {
        didSet {
            if !listImage.isEmpty {
                originnalImageView.forEach({
                    $0.image = listImage[$0.tag]
                })
            }
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
    }

    @IBAction func tapUpload(_ sender: UIButton) {
        var config = PHPickerConfiguration()
        config.selectionLimit = 3
        config.filter = .images
        let picker = PHPickerViewController.init(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @IBAction func tapCreatePoster(_ sender: UIButton) {
        let frame = finalImageView.bounds
        let textBoundHeight: CGFloat = 24
        let width = frame.width
        let height = frame.height - textBoundHeight
        let renderer = UIGraphicsImageRenderer(bounds: frame)
        let image = renderer.image { context in
            let frame1 = CGRect(x: 0, y: 0, width: width * 7/20, height: height)
            let firstImage = listImage.first!
            firstImage.draw(in: frame1)
            
            let thirdImage = listImage[2]
            let frame3 = CGRect(x: width * 13/20, y: 0, width: width * 7/20, height: height)
            thirdImage.draw(in: frame3)
            
            // Tạo path hình thang đều theo đì zai
            let rectPath = UIBezierPath()
            rectPath.move(to: .init(x: width/4, y: .zero))
            rectPath.addLine(to: .init(x: width * 3/4, y: .zero))
            rectPath.addLine(to: .init(x: width * 13/20, y: height))
            rectPath.addLine(to: .init(x: width * 7/20, y: height))
            rectPath.close()
            
            rectPath.addClip()
            
            let secondImage = listImage[1]
            let frame2 = CGRect(x: width/4, y: 0, width: width/2, height: height)
            secondImage.draw(in: frame2)
            
            // Bỏ clip đi để còn vẽ típ
            UIGraphicsGetCurrentContext()?.resetClip()
            
            let borderPath = UIBezierPath()
            borderPath.move(to: .init(x: width/4, y: .zero))
            borderPath.addLine(to: .init(x: width * 7/20, y: height))
            borderPath.move(to: .init(x: width * 3/4, y: .zero))
            borderPath.addLine(to: .init(x: width * 13/20, y: height))
            UIColor.white.setStroke()
            borderPath.lineWidth = 4
            borderPath.stroke()
            
            UIColor.systemBrown.setFill()
            UIBezierPath(rect: CGRect(origin: .init(x: .zero, y: height), size: .init(width: width, height: textBoundHeight))).fill()
            
            let listAttributedText = listText
            listAttributedText[0].draw(in: .init(x: 0, y: height, width: width/3, height: textBoundHeight))
            listAttributedText[1].draw(in: .init(x: width/3, y: height, width: width/3, height: textBoundHeight))
            listAttributedText[2].draw(in: .init(x: width * 2/3, y: height, width: width/3, height: textBoundHeight))
        }
        finalImage = image
        finalImageView.image = image
    }
    
    @IBAction func tapSave(_ sender: UIButton) {
        if let savedImage = finalImage {
            UIImageWriteToSavedPhotosAlbum(savedImage, nil, nil, nil)
        }
    }
}

extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard results.count == 3 else {
            print("Cần chọn đủ 3 ảnh")
            return
        }
        var listImage: [UIImage] = []
        results.forEach { result in
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let self else { return }
                listImage.append(image as! UIImage)
                if listImage.count == 3 {
                    DispatchQueue.main.async {
                        self.listImage = listImage
                    }
                }
            }
        }
    }
}
