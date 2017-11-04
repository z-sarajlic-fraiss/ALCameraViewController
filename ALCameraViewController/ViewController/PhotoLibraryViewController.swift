//
//  ALImagePickerViewController.swift
//  ALImagePickerViewController
//
//  Created by Alex Littlejohn on 2015/06/09.
//  Copyright (c) 2015 zero. All rights reserved.
//

import UIKit
import Photos

internal let ImageCellIdentifier = "ImageCell"

internal let defaultItemSpacing: CGFloat = 1

public typealias PhotoLibraryViewSelectionComplete = (PHAsset?) -> Void

public typealias PhotoLibraryViewMultipleSelectionComplete = ([PHAsset?]) -> Void

public class PhotoLibraryViewController: UIViewController {
    
    internal var assets: PHFetchResult<PHAsset>? = nil
    
    public var onSelectionComplete: PhotoLibraryViewSelectionComplete?
    
    public var onSelectionMultipleComplete: PhotoLibraryViewMultipleSelectionComplete?
    
    public var allowMultiple = true
    
    internal var selectedAssets:[PHAsset] = []
    
    internal var buttonImageConfirmLibrarySelection:UIImage!
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        
        layout.itemSize = CameraGlobals.shared.photoLibraryThumbnailSize
        layout.minimumInteritemSpacing = defaultItemSpacing
        layout.minimumLineSpacing = defaultItemSpacing
        layout.sectionInset = UIEdgeInsets.zero
        
        
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.clear
        return collectionView
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setNeedsStatusBarAppearanceUpdate()
        
        let buttonImage = UIImage(named: "libraryCancel", in: CameraGlobals.shared.bundle, compatibleWith: nil)?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: buttonImage,
                                                           style: UIBarButtonItemStyle.plain,
                                                           target: self,
                                                           action: #selector(dismissLibrary))
        
        buttonImageConfirmLibrarySelection = UIImage(named: "libraryConfirm", in: CameraGlobals.shared.bundle, compatibleWith: nil)?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: buttonImageConfirmLibrarySelection,
                                                            style: UIBarButtonItemStyle.plain,
                                                            target: self,
                                                            action: #selector(saveSelectionInLibrary))
        
        if allowMultiple == true {
            collectionView.allowsMultipleSelection = true
        } else {
            collectionView.allowsMultipleSelection = false
        }
        
        view.backgroundColor = UIColor(white: 0.2, alpha: 1)
        view.addSubview(collectionView)
        
        _ = ImageFetcher()
            .onFailure(onFailure)
            .onSuccess(onSuccess)
            .fetch()
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.frame = view.bounds
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    public func present(_ inViewController: UIViewController, animated: Bool) {
        let navigationController = UINavigationController(rootViewController: self)
        navigationController.navigationBar.barTintColor = UIColor.black
        navigationController.navigationBar.barStyle = UIBarStyle.black
        inViewController.present(navigationController, animated: animated, completion: nil)
    }
    
    @objc public func dismissLibrary() {
        onSelectionComplete?(nil)
    }
    
    @objc public func saveSelectionInLibrary() {
        onSelectionMultipleComplete?(selectedAssets)
    }
    
    
    private func onSuccess(_ photos: PHFetchResult<PHAsset>) {
        assets = photos
        configureCollectionView()
    }
    
    private func onFailure(_ error: NSError) {
        let permissionsView = PermissionsView(frame: view.bounds)
        permissionsView.titleLabel.text = localizedString("permissions.library.title")
        permissionsView.descriptionLabel.text = localizedString("permissions.library.description")
        
        view.addSubview(permissionsView)
    }
    
    private func configureCollectionView() {
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCellIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    internal func itemAtIndexPath(_ indexPath: IndexPath) -> PHAsset? {
        return assets?[(indexPath as NSIndexPath).row]
    }
}

// MARK: - UICollectionViewDataSource -
extension PhotoLibraryViewController : UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets?.count ?? 0
    }
    
    @objc(collectionView:willDisplayCell:forItemAtIndexPath:) public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is ImageCell {
            if let model = itemAtIndexPath(indexPath) {
                (cell as! ImageCell).configureWithModel(model)
                
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCellIdentifier, for: indexPath)
        
        if let item = itemAtIndexPath(indexPath) {
            
            if selectedAssets.contains(item) {
                cell.contentView.layer.opacity = 0.3
                
                let imageView = UIImageView(image: buttonImageConfirmLibrarySelection)
                imageView.frame = CGRect(x: 2, y: 2, width: 16, height: 16)
                let view = UIView(frame: CGRect(x: cell.bounds.width - 24 , y: cell.bounds.height - 24, width: 20, height: 20))
                view.layer.borderColor = UIColor.darkGray.cgColor
                view.backgroundColor = UIColor.white
                view.layer.opacity = 0.7
                view.layer.cornerRadius = 10
                view.layer.borderWidth = 1
                view.addSubview(imageView)
                view.tag = 1000
                cell.addSubview(view)
                
            } else {
                
                cell.contentView.layer.opacity = 1
            }
            
            cell.contentView.backgroundColor = UIColor.white
            
        }
        
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate -
extension PhotoLibraryViewController : UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if allowMultiple == true {
            if let item = itemAtIndexPath(indexPath) {
                if selectedAssets.contains(item) {
                    if let index = selectedAssets.index(of: item) {
                        selectedAssets.remove(at: index)
                    }
                    
                    if let cell = collectionView.cellForItem(at: indexPath) {
                        
                        if let selectionView = cell.viewWithTag(1000) {
                            selectionView.removeFromSuperview()
                        }
                    }
                    
                    
                    
                } else {
                    selectedAssets.append(item)
                }
            }
            
            collectionView.reloadItems(at: [indexPath])
        } else {
            onSelectionComplete?(itemAtIndexPath(indexPath))
        }
    }
}
