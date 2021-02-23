//
//  ImageCollectionViewItem.swift
//  ParsePlist
//
//  Created by user on 2021/2/3.
//

import Cocoa

class ImageCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var plitImage: NSImageView!
    @IBOutlet weak var imageName: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func configuration(of item: ImageItem) {
        plitImage.image = item.image
        imageName.stringValue = item.name
    }
    
}
