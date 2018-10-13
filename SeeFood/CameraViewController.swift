//
//  CameraViewController.swift
//  SeeFood
//
//  Created by Nafeh Shoaib on 2018-10-13.
//  Copyright © 2018 nafehshoaib. All rights reserved.
//

import UIKit
import AVFoundation
import CameraManager
import SwiftyJSON
import Alamofire

class CameraViewController: UIViewController {
    let session = URLSession.shared

    @IBOutlet var cameraView: UIView!
    var cameraManager: CameraManager!
    
    var myImage: UIImage!
    
    var googleAPIKey = "AIzaSyAgyXmYjRvIrVL6U1EktJsuuIaoeci-96I"
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraManager = CameraManager()
        cameraManager.addPreviewLayerToView(self.cameraView)
        // Do any additional setup after loading the view.
    }
    
    func resizeImage(_ imageSize: CGSize, image: UIImage) -> Data {
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = newImage?.pngData()!
        UIGraphicsEndImageContext()
        return resizedImage!
    }
    
    @IBAction func didPressTakePhotoButton(_ sender: UIButton) {
        cameraManager.capturePictureWithCompletion({ (image, error) -> Void in
            self.myImage = image
            print("Photo taken!")
            var imageData = self.myImage.pngData()
            if (imageData!.count > 2097152) {
                let oldSize: CGSize = self.myImage.size
                let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
                imageData = self.resizeImage(newSize, image: self.myImage)
            }
            self.googleCloudRequest(data: (imageData?.base64EncodedString())!)
        })
        
    }
    
    func googleCloudRequest(data: String) {
        let httpHeaders: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        let requestObj: [String: Any?] =
            [
                "image": [
                    "content" : data
                ],
                "features": [
                    [
                        "type": "OBJECT_LOCALIZATION"
                    ]
                ]
            ]
        let jsonRequest = ["requests": [requestObj]]
        
        Alamofire.request(googleURL, method: .post, parameters: jsonRequest, encoding: JSONEncoding.default, headers: httpHeaders).responseJSON { response in
            //print(jsonRequest)
            print(response)
            //handleFoodVectors(response: response["responses"])
        }
    }
    
    func handleFoodVectors(response: JSON) {
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
