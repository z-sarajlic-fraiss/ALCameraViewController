//
//  SingleImageSavingInteractor.swift
//  ALCameraViewController
//
//  Created by Alex Littlejohn on 2016/02/16.
//  Copyright © 2016 zero. All rights reserved.
//

import UIKit
import Photos

public typealias SingleImageSaverSuccess = (PHAsset) -> Void
public typealias SingleImageSaverFailure = (NSError) -> Void

public class SingleImageSaver {
    private let errorDomain = "com.zero.singleImageSaver"
    
    private var success: SingleImageSaverSuccess?
    private var failure: SingleImageSaverFailure?
    
    private var image: UIImage?
    
    public init() { }
    
    public func onSuccess(_ success: @escaping SingleImageSaverSuccess) -> Self {
        self.success = success
        return self
    }
    
    public func onFailure(_ failure: @escaping SingleImageSaverFailure) -> Self {
        self.failure = failure
        return self
    }
    
    public func setImage(_ image: UIImage) -> Self {
        self.image = image
        return self
    }
    
    let assetCollection: PHAssetCollection? = {
        var assetCollection: PHAssetCollection? = nil
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", CameraGlobals.shared.albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if collection.firstObject != nil {
            return collection.firstObject
        }
        
        do {
            try PHPhotoLibrary.shared().performChangesAndWait({
                
                
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: CameraGlobals.shared.albumName)
                
                
                
            })
        } catch {
            print("UNABLE TO WRITE INTO MEDIA")
            return nil
            
        }
        assetCollection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions).firstObject
        
        return assetCollection
    }()
    
    public func save() -> Self {
        
        _ = PhotoLibraryAuthorizer { error in
            if error == nil {
                self._save()
            } else {
                self.failure?(error!)
            }
        }

        return self
    }
    /*
    private func _save() {
        guard let image = image else {
            self.invokeFailure()
            return
        }
        
        var assetIdentifier: PHObjectPlaceholder?
        
        PHPhotoLibrary.shared()
            .performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                assetIdentifier = request.placeholderForCreatedAsset
            }) { finished, error in
                
                guard let assetIdentifier = assetIdentifier, finished else {
                    self.invokeFailure()
                    return
                }
                
                self.fetch(assetIdentifier)
        }
    }
    */
    
    private func _save() {
        guard let image = image else {
            self.invokeFailure()
            return
        }
        var assetIdentifier: PHObjectPlaceholder?
        
        if assetCollection == nil {
            self.invokeFailure()
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            assetIdentifier = assetChangeRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection!)
            
            let enumeration: NSArray = [assetIdentifier!]
            albumChangeRequest!.addAssets(enumeration)
            
        }) { finished, error in
            
            if let assetIdentifier = assetIdentifier {
                self.fetch(assetIdentifier)
            } else {
                self.invokeFailure()
                return
            }
        }
    }
    
    private func fetch(_ assetIdentifier: PHObjectPlaceholder) {
        
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier.localIdentifier], options: nil)
        
        DispatchQueue.main.async {
            guard let asset = assets.firstObject else {
                self.invokeFailure()
                return
            }
            
            self.success?(asset)
        }
    }
    
    private func invokeFailure() {
        let error = errorWithKey("error.cant-fetch-photo", domain: errorDomain)
        failure?(error)
    }
}
