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
        case .Authorized:
            return true
        default:
            PHPhotoLibrary.requestAuthorization{ (status) in
                print("PhotoLibrary Permission : \(status)")
            }
        }
        return false
    }
    
    private func fetchPhotoAlbum() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", CustomPhotoAlbumManager.albumName)
        let collection = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        
        return collection.firstObject as? PHAssetCollection
    }
    
    func savePhoto(withPhoto image : UIImage) -> Bool {
        
        if PHPhotoLibrary.authorizationStatus() != .Authorized {
            return false
        }
        
        var assetCollection : PHAssetCollection? = fetchPhotoAlbum()
        var assetCollectionChangeRequest : PHAssetCollectionChangeRequest?
        
        if assetCollection == nil {
            do
            {
                try PHPhotoLibrary.sharedPhotoLibrary().performChangesAndWait {
                    PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(CustomPhotoAlbumManager.albumName)
                }
                assetCollection = fetchPhotoAlbum()
            } catch let error {
                print("creating album error: \(error)")
                return false
            }
        }
        
        do
        {
            try PHPhotoLibrary.sharedPhotoLibrary().performChangesAndWait {
                assetCollectionChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: assetCollection!)
            }
        } catch let error {
            print("assigning album error: \(error)")
            return false
        }
        
        return savePhoto(withPhoto: image, withChangeRequest: assetCollectionChangeRequest)
    }
    
    private func savePhoto(withPhoto image: UIImage, withChangeRequest assetCollectionChangeRequest : PHAssetCollectionChangeRequest?) -> Bool {
        
        if assetCollectionChangeRequest == nil {
            return false
        }
        
        do {
            try PHPhotoLibrary.sharedPhotoLibrary().performChangesAndWait {
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)
                let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
                assetCollectionChangeRequest?.addAssets([assetPlaceHolder!])
            }
        } catch let error {
            print("saving photo error: \(error)")
            return false
        }
        return true
    }


}