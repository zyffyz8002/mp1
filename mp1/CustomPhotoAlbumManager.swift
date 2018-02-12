//
//  CustomPhotoAlbum.swift
//  mp1
//
//  Created by Yifan on 7/12/16.
//
//

import Foundation
import Photos

class CustomPhotoAlbumManager: NSObject {
    static let albumName = "SVF"
    
    func requestForPhotoAlbumAutherization() -> Bool {
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            return true
        default:
            PHPhotoLibrary.requestAuthorization{ (status) in
                print("PhotoLibrary Permission : \(status)")
            }
        }
        return false
    }
    
    fileprivate func fetchPhotoAlbum() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", CustomPhotoAlbumManager.albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        return collection.firstObject //as? PHAssetCollection
    }
    
    func savePhoto(withPhoto image : UIImage) -> Bool {
        
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            return false
        }
        
        var assetCollection : PHAssetCollection? = fetchPhotoAlbum()
        var assetCollectionChangeRequest : PHAssetCollectionChangeRequest?
        
        if assetCollection == nil {
            do
            {
                try PHPhotoLibrary.shared().performChangesAndWait {
                    PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: CustomPhotoAlbumManager.albumName)
                }
                assetCollection = fetchPhotoAlbum()
            } catch let error {
                print("creating album error: \(error)")
                return false
            }
        }
        
        do
        {
            try PHPhotoLibrary.shared().performChangesAndWait {
                assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection!)
            }
        } catch let error {
            print("assigning album error: \(error)")
            return false
        }
        
        return savePhoto(withPhoto: image, withChangeRequest: assetCollectionChangeRequest)
    }
    
    fileprivate func savePhoto(withPhoto image: UIImage, withChangeRequest assetCollectionChangeRequest : PHAssetCollectionChangeRequest?) -> Bool {
        
        if assetCollectionChangeRequest == nil {
            return false
        }
        
        do {
            try PHPhotoLibrary.shared().performChangesAndWait {
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
                assetCollectionChangeRequest?.addAssets([assetPlaceHolder!] as NSArray)
            }
        } catch let error {
            print("saving photo error: \(error)")
            return false
        }
        return true
    }


}
