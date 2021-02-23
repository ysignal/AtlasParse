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
        openPanel.begin { (response) in
            if response == .OK {
                let urls = openPanel.urls
                for url in urls {
                    if url.absoluteString.lowercased().hasSuffix(".plist") {
                        self.parsePlist(url: url)
                    } else if url.absoluteString.lowercased().hasSuffix(".png") || url.absoluteString.lowercased().hasSuffix(".jpg") || url.absoluteString.lowercased().hasSuffix(".jpeg") {
                        self.parseImage(url: url)
                    }
                }
            }
        }
    }
    
    @IBAction func saveFile(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.begin { (response) in
            if response == .OK, let url = openPanel.url {
                for item in self.dataList {
                    if let cgimage = item.image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                        let newReq = NSBitmapImageRep(cgImage: cgimage)
                        newReq.size = item.image.size
                        let pngData = newReq.representation(using: .png, properties: [:])
                        let filePath = url.appendingPathComponent(item.name)
                        try? pngData?.write(to: filePath)
                    }
                }
            }
        }
    }
    
    @IBAction func toParse(_ sender: Any) {
        isParsing = true
        let button = sender as? NSButton
        button?.isEnabled = false
        
        plitImage()
        isParsing = false
        button?.isEnabled = true
    }
    
    @IBAction func outputSwiftFile(_ sender: Any) {
        if let url = URL(string: plistPath.stringValue) {
            writeSwiftFile(plistData, url: url)
        }
    }
    
    func parseImage(url: URL) {
        imageData = NSImage(contentsOf: url)
        dataImage.image = imageData
        pngPath.stringValue = url.absoluteString.removingPercentEncoding ?? url.absoluteString
    }
    
    func parsePlist(url: URL) {
        if let data = NSDictionary(contentsOf: url) {
            plistData = data
        }
        plistPath.stringValue = url.absoluteString.removingPercentEncoding ?? url.absoluteString
    }
    
    func plitImage() {
        if let data = imageData {
            //MARK: 解析cocoa2d-x类型的plist
            if let frames = plistData["frames"] as? NSDictionary {
                dataList.removeAll()
                for key in frames.allKeys {
                    if let frame = frames[key] as? NSDictionary {
                        if let textureRect = (frame["frame"] != nil ? frame["frame"] : frame["textureRect"]) as? String {
                            let list = textureRect.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "").split(separator: ",")
                            if list.count >= 4, let name = key as? String {
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
                                if let textureRotated = frame["textureRotated"] as? Bool, textureRotated {
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
                            }
                        }
                    }
                }
                //MARK: 解析SpriteKit类型的plist
            } else if let images = plistData["images"] as? NSArray {
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
    
    func writeSwiftFile(_ data: NSDictionary, url: URL) {
        var path = url
        let fileName = String(url.lastPathComponent.split(separator: ".").first ?? "")
        path.deleteLastPathComponent()
        let manager = FileManager.default
        if !manager.fileExists(atPath: path.absoluteString) {
            path.appendPathComponent("\(fileName).swift")
            if !manager.fileExists(atPath: path.absoluteString) {
                manager.createFile(atPath: path.absoluteString, contents: nil, attributes: nil)
            }
        } else {
            path.appendPathComponent("\(fileName).swift")
            if !manager.fileExists(atPath: path.absoluteString) {
                manager.createFile(atPath: path.absoluteString, contents: nil, attributes: nil)
            }
        }
        let swiftStr = fileString(from: data, name: fileName)
        let data = swiftStr.data(using: .utf8)
        try? data?.write(to: path, options: .atomic)
    }
    
    
    func fileString(from data: NSDictionary, name: String) -> String {
        let newName = name.replacingOccurrences(of: "-", with: "_")
        let header = "// ----------------------------------------\n// Sprite definitions for '\(newName)'\n// Generated with TexturePacker 5.5.0\n//\n// https://www.codeandweb.com/texturepacker\n// ----------------------------------------\n\n"
        
        let atlasCode = "\t// Load texture atlas.\n\tprivate static let textureAtlas = SKTextureAtlas(named: \"\(name)\")\n"
        
        var nameList: [String] = []
        if let images = data["images"] as? NSArray, let image = images.firstObject as? NSDictionary, let subimages = image["subimages"] as? NSArray {
            for subimage in subimages {
                if let subDict = subimage as? NSDictionary, let subStr = subDict["name"] as? String, let subName = subStr.split(separator: ".").first {
                    nameList.append(String(subName))
                }
            }
        }
        var imageCode = "\n\t// Set texture instance."
        for subName in nameList.sorted() {
            imageCode += "\n\tstatic let \(subName) = textureAtlas.textureNamed(\"\(subName)\")"
        }
        
        let structCode = atlasCode + imageCode
        
        let structStr = "import SpriteKit\n\nstruct \(newName) {\n\n\(structCode)\n\n}"
        
        return header + structStr
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
