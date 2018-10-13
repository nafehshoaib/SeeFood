//
//  ViewController.swift
//  SeeFood
//
//  Created by Nafeh Shoaib on 2018-10-12.
//  Copyright © 2018 nafehshoaib. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftyJSON

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    let session = URLSession.shared
    
    @IBOutlet var previewView: UIView!
    
    var captureSession: AVCaptureSession!
    var stillImageOutput:AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    var image: UIImage!
    
    
    var googleAPIKey = "AIzaSyAgyXmYjRvIrVL6U1EktJsuuIaoeci-96I"
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }

    @IBAction func didPressTakePhotoButton(_ sender: UIButton) {
//        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
//        stillImageOutput.capturePhoto(with: settings, delegate: self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium;
        guard let camera = AVCaptureDevice.default(for: AVMediaType.video)
            else {
                print("Unable to access back camera!")
                return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
        } catch {
            print(error)
        }
    }
    
    func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        previewView.layer.addSublayer(videoPreviewLayer!)
        self.captureSession.startRunning()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {

        guard let imageData = photo.fileDataRepresentation()
            else { return }

        image = UIImage(data: imageData)!
        googleCloudRequest(imageData: imageData.base64EncodedString(options: .endLineWithCarriageReturn))
    }

    func googleCloudRequest( imageData: String) {
        var request = URLRequest(url: googleURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")

        let jsonRequest: [String: Any?] = [
            "requests": [
                "images": [
                    "content": imageData
                ]
            ],
            "features": [

            ]
        ]

        let jsonObject = JSON(jsonRequest)
        guard let data = try? jsonObject.rawData() else {
            return
        }

        request.httpBody = data
         DispatchQueue.global().async { self.runRequestOnBackgroundThread(request) }
    }

    func runRequestOnBackgroundThread(_ request: URLRequest) {
        // run the request

        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }

            self.analyzeResults(data)
        }

        task.resume()
    }

    func analyzeResults(_ dataToParse: Data) {
        print(dataToParse)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
}

