//
//  FirebaseStorageManager.swift
//  Camshot
//
//  Created by Timi Tejumola on 08/03/2020.
//  Copyright © 2020 Timi Tejumola. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Firebase

class VideoUtils {
    
    func uniqueFileNameWithExtention(fileExtension: String) -> String {
        let uniqueString: String = ProcessInfo.processInfo.globallyUniqueString
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddh hmmsss"
        let dateString: String = formatter.string(from: Date())
        let uniqueName: String = "\(uniqueString)_\(dateString)"
        if fileExtension.count > 0 {
            let fileName: String = "\(uniqueName).\(fileExtension)"
            return fileName
        }
        return uniqueName
    }
    
    func writeToFile(url: URL, filename: String) {
        do {
           let videoData = try Data(contentsOf: url)
           let fm = FileManager.default

           guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
               print("Unable to reach the documents folder")
               return
           }
            let localUrl = docUrl.appendingPathComponent(filename)
            try videoData.write(to: localUrl)
            print("done2: ",docUrl, localUrl)

        } catch {
           print("could not save data")
        }
    }
    
    func videoPreviewImage(url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        if let cgImage = try? generator.copyCGImage(at: CMTime(seconds: 2, preferredTimescale: 60), actualTime: nil) {
            return UIImage(cgImage: cgImage)
        }
        else {
            return nil
        }
    }
    
//    func getThumbnailImageFromVideoUrl(url: URL, completion: @escaping ((_ image: UIImage?)->Void)) {
//        DispatchQueue.global().async { //1
//            let asset = AVAsset(url: url) //2
//            let avAssetImageGenerator = AVAssetImageGenerator(asset: asset) //3
//            avAssetImageGenerator.appliesPreferredTrackTransform = true //4
//            let thumnailTime = CMTimeMake(value: 2, timescale: 1) //5
//            do {
//                let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil) //6
//                let thumbImage = UIImage(cgImage: cgThumbImage) //7
//                DispatchQueue.main.async { //8
//                    completion(thumbImage) //9
//                }
//            } catch {
//                print(error)
//                print(error.localizedDescription) //10
//                DispatchQueue.main.async {
//                    completion(nil) //11
//                }
//            }
//        }
//    }

    public func uploadMetadata(localFile: URL, serverFileName: String, filter: String?, completionHandler: @escaping (_ isSuccess: Bool, _ documentID: String?) -> Void) {

        let db = Firestore.firestore()
        
        var ref: DocumentReference? = nil
        ref = db.collection("videos").addDocument(data: [
            "filter": filter,
            "filename": serverFileName
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
                completionHandler(false, nil)
            } else {
                print("Document added with ID: \(ref!.documentID)")
                completionHandler(true, ref!.documentID)
            }
        }
    }
    
    public func filterImage(){
        
    }
}
