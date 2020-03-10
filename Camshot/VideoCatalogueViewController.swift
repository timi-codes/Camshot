//
//  VideoCatalogueViewController.swift
//  Camshot
//
//  Created by Timi Tejumola on 07/03/2020.
//  Copyright © 2020 Timi Tejumola. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit


class VideoCatalogueViewController: UICollectionViewController {
    private var videos: [Video] = []
    private var estimateWidth = 140.0
    private var cellMarginSize = 16.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DataManager.shared.firstVC = self
        setUpNavigation()
        getAllVideos()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "VideoViewCell", bundle: nil), forCellWithReuseIdentifier: "VideoCell")
        setUpGridview()
    }
    
    
    func setUpNavigation(){
        navigationItem.title = "Camshot"
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.heavy),
            NSAttributedString.Key.foregroundColor: UIColor.systemPink
        ]

        let cameraButton = UIButton(type: .system)
        cameraButton.setImage(#imageLiteral(resourceName: "cam-icon").withRenderingMode(.alwaysOriginal), for: .normal)
//        cameraButton.imageView?.contentMode = .scaleAspectFit
        cameraButton.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        cameraButton.addTarget(self, action: #selector(showCamera), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cameraButton)

    }
    
    
    func setUpGridview(){
        let flow = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flow.minimumInteritemSpacing = CGFloat(self.cellMarginSize)
        flow.minimumLineSpacing = CGFloat(self.cellMarginSize)
    }
    
    
    @objc func showCamera(){
        let cameraVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CameraVC")
        let navVC = UINavigationController(rootViewController: cameraVC)
        self.present(navVC, animated: false, completion: nil)

    }
    
func getAllVideos(){
        videos = []
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            for url in fileURLs {
                videos.append(Video(url: url, filter: "CIVibrance"))
            }
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    
        print("\(videos)==>")
        
    }
        
    // MARK: - PREPARE
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "playVideo" {
            let videoPlayerViewController = segue.destination as! AVPlayerViewController
            let videoFileURL = sender as! URL
            videoPlayerViewController.player = AVPlayer(url: videoFileURL)
        }
    }
    
}

extension VideoCatalogueViewController  {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
  
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoViewCell
        cell.setData(video: videos[indexPath.row])
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        performSegue(withIdentifier: "playVideo", sender: videos[indexPath.row].url)
    }
}

extension VideoCatalogueViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.calculateWidth()
        
        return CGSize(width: width, height: width * 1.5)
    }
    
    func calculateWidth() -> CGFloat {
        let estimatedWidth = CGFloat(estimateWidth)
        let cellCount = floor(CGFloat(self.view.frame.size.width / estimatedWidth))
        
        let margin = CGFloat(cellMarginSize * 2)
        let width = (self.view.frame.size.width - CGFloat(cellMarginSize) * (cellCount - 1) - margin) / cellCount
        
        return width
    }
}
