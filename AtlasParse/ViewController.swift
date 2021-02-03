//
//  ViewController.swift
//  AtlasParse
//
//  Created by user on 2021/2/3.
//

import Cocoa

struct ImageItem {
    var image: NSImage
    var name: String
}

class ViewController: NSViewController {
    
    @IBOutlet weak var dataImage: NSImageView!
    @IBOutlet weak var plistPath: NSTextField!
    @IBOutlet weak var pngPath: NSTextField!
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var indicator: NSProgressIndicator!

    var isParsing: Bool = false {
        didSet {
            if isParsing {
                indicator.isHidden = false
                indicator.startAnimation(nil)
            } else {
                indicator.isHidden = true
                indicator.stopAnimation(nil)
            }
        }
    }
    
    var dataList: [ImageItem] = []
    
    var plistData: NSDictionary = [:]
    var imageData: NSImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(ImageCollectionViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "image"))
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func openFile(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = true
//        openPanel.allowedFileTypes = ["plist", "png"]
        openPanel.begin { (response) in
            if response == .OK {
                let urls = openPanel.urls
                for url in urls {
                    if url.absoluteString.hasSuffix(".plist") {
                        self.parsePlist(url: url)
                    } else if url.absoluteString.hasSuffix(".png") {
                        self.parseImage(url: url)
                    }
                }
            }
        }
//        openPanel.beginSheetModal(for: NSApp.mainWindow!) { (response) in
//            if response == .OK {
//                let paths = openPanel.urls
//                print(paths)
//            }
//        }
    }
    
    @IBAction func saveFile(_ sender: Any) {
        
    }
    
    @IBAction func toParse(_ sender: Any) {
        isParsing = true
        let button = sender as? NSButton
        button?.isEnabled = false
        
        plitImage()
        isParsing = false
        button?.isEnabled = true
    }
    
    func parseImage(url: URL) {
        imageData = NSImage(contentsOf: url)
        dataImage.image = imageData
        pngPath.stringValue = url.absoluteString
    }
    
    func parsePlist(url: URL) {
        if let data = NSDictionary(contentsOf: url) {
            plistData = data
            plistPath.stringValue = url.absoluteString
        }
    }
    
    func plitImage() {
        if let data = imageData {
            if let images = plistData["images"] as? NSArray {
                for image in images {
                    if let imageDict = image as? NSDictionary {
                        if let subimages = imageDict["subimages"] as? NSArray {
                            dataList.removeAll()
                            for subimage in subimages {
                                if let subDict = subimage as? NSDictionary {
                                    if let textureRect = subDict["textureRect"] as? String {
                                        let list = textureRect.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "").split(separator: ",")
                                        if list.count >= 4, let name = subDict["name"] as? String {
                                            let x = CGFloat(NSString(string: String(list[0])).floatValue)
                                            let y = CGFloat(NSString(string: String(list[1])).floatValue)
                                            let width = CGFloat(NSString(string: String(list[2])).floatValue)
                                            let height = CGFloat(NSString(string: String(list[3])).floatValue)
                                            let newImage: NSImage = NSImage(size: NSSize(width: width, height: height))
                                            let clipRect = NSRect(x: 0, y: 0, width: width, height: height)
                                            let rect = CGRect(x: -x, y: y-data.size.height+height, width: data.size.width, height: data.size.height)
                                            newImage.lockFocus()
                                            data.draw(in: rect)
                                            let path = NSBezierPath(rect: clipRect)
                                            path.addClip()
                                            newImage.unlockFocus()
                                            if let textureRotated = subDict["textureRotated"] as? Bool, textureRotated {
                                                // 图片方向调换
                                                let rotateImage: NSImage = NSImage(size: NSSize(width: height, height: width))
                                                rotateImage.lockFocus()
                                                let rorate = NSAffineTransform()
                                                rorate.rotate(byDegrees: 90)
                                                rorate.concat()
                                                newImage.draw(in: CGRect(x: 0, y: -height, width: width, height: height))
                                                rotateImage.unlockFocus()
                                                dataList.append(ImageItem(image: rotateImage, name: name))
                                            } else {
                                                dataList.append(ImageItem(image: newImage, name: name))
                                            }
//                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        collectionView.reloadData()
    }
}

extension ViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        if let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "image"), for: indexPath) as? ImageCollectionViewItem {
            item.configuration(of: dataList[indexPath.item])
            return item
        }
        return NSCollectionViewItem()
    }
}
