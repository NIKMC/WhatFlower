//
//  ViewController.swift
//  WhatFlower
//
//  Created by Ivan Nikitin on 14/04/2018.
//  Copyright © 2018 Иван Никитин. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var descriptionFlower: UILabel!
    private let wikipediaURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String
    @IBOutlet weak var imagePhoto: UIImageView!
    let imagePicker = UIImagePickerController()
    
    @IBAction func photoTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("can't import flowerClassifier model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            let classification = request.results?.first as? VNClassificationObservation
        
            self.navigationItem.title = classification?.identifier.capitalized
            
            self.getInfo(title: (classification?.identifier.capitalized)!)
        }
        
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        do{
            try handler.perform([request])
        } catch {
            
        }
    }
    
    func getInfo(title: String) {
        let parameter : [String: String] = [
            "format":"json",
            "action":"query",
            "prop" : "extracts|pageimages",
            "exintro":"",
            "explaintext":"",
            "titles":title,
            "indexpageids":"",
            "redirects":"1",
            "pithumbsize":"500"
        ]
        Alamofire.request(wikipediaURL!, method: .get, parameters: parameter).responseJSON { (response) in
            guard response.result.isSuccess else {
                print("Error while fetching response: \(String(describing: response.result.error))")
                return
            }
            print(JSON(response.result.value!))
            let flowerJSON : JSON = JSON(response.result.value!)
            
            let pageId = flowerJSON["query"]["pageids"][0].stringValue

            let flowerDescription = flowerJSON["query"]["pages"][pageId]["extract"].stringValue
            
            let flowerImageURL = flowerJSON["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
            
            self.imagePhoto.sd_setImage(with: URL(string: flowerImageURL))
            
            self.descriptionFlower.text = flowerDescription
            
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let userPickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            guard let convertedCIImage = CIImage(image: userPickedImage) else {
                fatalError("Cannot convert to ciImage")
            }
            detect(image: convertedCIImage)
            
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
    }


}

