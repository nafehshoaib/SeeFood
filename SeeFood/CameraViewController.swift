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
import Foundation

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
            if let resultData = response.result.value {
                let jsonResultData = JSON(resultData)
                self.handleFoodVectors(response: jsonResultData["responses"][0]["localizedObjectAnnotations"])
            }
            //handleFoodVectors(response: response["responses"])
        }
    }
    
    func handleFoodVectors(response: JSON) {
        var foodObjects: [[String: Any]] = [];
        for i in 0...response.array!.count-1 {
            let name = response[i]["name"].string
            var xEs = 0.0
            var yS = 0.0
            for j in 0...response[i]["boundingPoly"]["normalizedVertices"].array!.count-1 {
                let coordinateX = response[i]["boundingPoly"]["normalizedVertices"][j]["x"]
                let coordinateY = response[i]["boundingPoly"]["normalizedVertices"][j]["y"]
                //print(coordinateX);
                xEs += coordinateX.doubleValue
                yS += coordinateY.doubleValue
            }
            foodObjects.append([
                "name" : name!,
                "coordinate" : xEs + yS
            ])
        }
        print(foodObjects)
        
        var trackedCoordinates: [Double] = []
        for i in 0...foodObjects.count-1 {
            if foodObjects[i]["name"] as! String == "Food" {
                trackedCoordinates.append(foodObjects[i]["coordinate"] as! Double)
            }
        }
        sendToWolfram(name: "grape")
    }
    
    
    func sendToWolfram(name: String) {
        Alamofire.request("https://api.wolframalpha.com/v2/query?input=" + name + "&appid=AHG9EG-XHHQ6U7KAW&output=xml", method: .get).responseString { response in
            if let responseString = response.value {
                let beginningIndex = responseString.endIndex(of: "total calories ")!.encodedOffset + 1
                let endIndex = responseString.index(of:" | fat calories")!.encodedOffset + 1
                let calories = Double(responseString.substring(beginningIndex..<endIndex))
                print(calories)
            }
        }
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

extension StringProtocol where Index == String.Index {
    func index(of string: Self, options: String.CompareOptions = []) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }
    func endIndex(of string: Self, options: String.CompareOptions = []) -> Index? {
        return range(of: string, options: options)?.upperBound
    }
    func indexes(of string: Self, options: String.CompareOptions = []) -> [Index] {
        var result: [Index] = []
        var start = startIndex
        while start < endIndex,
            let range = self[start..<endIndex].range(of: string, options: options) {
                result.append(range.lowerBound)
                start = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
    func ranges(of string: Self, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var start = startIndex
        while start < endIndex,
            let range = self[start..<endIndex].range(of: string, options: options) {
                result.append(range)
                start = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}

public extension String {
    
    //right is the first encountered string after left
    func between(_ left: String, _ right: String) -> String? {
        guard
            let leftRange = range(of: left), let rightRange = range(of: right, options: .backwards)
            , leftRange.upperBound <= rightRange.lowerBound
            else { return nil }
        
        let sub = self[leftRange.upperBound...]
        let closestToLeftRange = sub.range(of: right)!
        return String(sub[..<closestToLeftRange.lowerBound])
    }
    
    var length: Int {
        get {
            return self.count
        }
    }
    
    func substring(to : Int) -> String {
        let toIndex = self.index(self.startIndex, offsetBy: to)
        return String(self[...toIndex])
    }
    
    func substring(from : Int) -> String {
        let fromIndex = self.index(self.startIndex, offsetBy: from)
        return String(self[fromIndex...])
    }
    
    func substring(_ r: Range<Int>) -> String {
        let fromIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
        let toIndex = self.index(self.startIndex, offsetBy: r.upperBound)
        let indexRange = Range<String.Index>(uncheckedBounds: (lower: fromIndex, upper: toIndex))
        return String(self[indexRange])
    }
    
    func character(_ at: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: at)]
    }
    
    func lastIndexOfCharacter(_ c: Character) -> Int? {
        return range(of: String(c), options: .backwards)?.lowerBound.encodedOffset
    }
}
