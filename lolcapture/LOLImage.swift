//
//  LOLImage.swift
//  lolcommits
//
//  Created by Matthew Rothenberg on 2/9/15.
//  Copyright (c) 2015 Matthew Rothenberg. All rights reserved.
//

import Foundation
import AppKit

class LOLImage {
    
    // storage for the raw image before processing
    private let image: NSImage!
    
    /// how much margin to have on the sides of the image
    let marginSize: CGFloat = 10.0
    
    // what size the final image should be after resizing and cropping
    let desiredFinalWidth:  CGFloat = 640.0 // 960.0 would be native on iMac after cropping
    let desiredFinalHeight: CGFloat = 480.0 // 720.0 would be native on iMac after cropping
    var desiredFinalSize: CGSize {
        return CGSize(width: desiredFinalWidth, height: desiredFinalHeight)
    }
    
    // instance vars for the messages
    var topMessage: String?
    var bottomMessage: String?
    
    
    init(imageData: NSData) {
        // TODO: want to init from whatever the best generic image representation is
        // that way we are more flexible w/r/t whatever comes out of camsnap and other shit
        self.image = NSImage(data: imageData)
        
        // TODO: remove fake init data!
        self.topMessage = "d3adb33f69"
        self.bottomMessage = "now is the time for all good men to come to the aide of their country. lorem ipsum hipsterium fixie PBR blanc nolit et tempus fugit admin."
    }
    
    init(imageData: NSData, gitMsg: String, gitSHA: String) {
        self.image = NSImage(data: imageData)
        self.topMessage = gitSHA
        self.bottomMessage = gitMsg
    }
    
    
    func resizedImage() -> NSImage {
        return resizeImageToFill(self.image, targetSize: self.desiredFinalSize)
    }
    
    /// utility function: resizes a given image to fill target size, while preserving aspect ratio
    private func resizeImageToFill(image: NSImage, targetSize: CGSize) -> NSImage {
        let imgSize = image.size
        println("DEBUG[resize]: starting, image size: \(imgSize), target size: \(targetSize)")
        
        let widthRatio  = targetSize.width  / imgSize.width
        let heightRatio = targetSize.height / imgSize.height
        println("DEBUG[resize]: finding widthRatio: \(widthRatio), heightRatio: \(heightRatio)")
        
        //let scaleRatio = max(widthRatio, heightRatio)
        //let newSize = CGSizeMake(imgSize.width * scaleRatio, imgSize.height * scaleRatio)
        //println("new size before cropping will be: \(newSize)")
        
        // okay, so what we essentially need to do is make a NSRect of the appropriate size to precrop the image
        // to the desired aspect ratio, so we can use it as the contextual srcRect in the actual resize operation
        var croppingSize: CGSize
        if widthRatio < heightRatio {
            croppingSize = CGSize(width: imgSize.width / 4 * 3, height: imgSize.height)
        } else if widthRatio > heightRatio {
            croppingSize = CGSize(width: imgSize.width, height: imgSize.width / 4 * 3)
        } else {
            croppingSize = CGSize(width: imgSize.width, height: imgSize.height)
        }
        
        // let widthDiff = imgSize.width - croppingSize.width
        // let heightDiff = imgSize.height - croppingSize.height
        let croppingRect = NSRect(
            x: (imgSize.width  - croppingSize.width)/2,   // from difference in width
            y: (imgSize.height - croppingSize.height)/2,  // from difference in height
            width: croppingSize.width,
            height: croppingSize.height)
        
        println("DEBUG[resize]: using croppingRect: \(croppingRect)")
        
        // OMG WILL THIS WORK?? IT WILLLLLLLLLLLL (not what i pasted before but my new version oh yeah suckit internet
        let resizingImage = NSImage(size: targetSize, flipped: false, drawingHandler: { frame in
            image.drawInRect(frame, fromRect: croppingRect, operation: .CompositeOverlay, fraction: 1.0)
            return true
        })

        return resizingImage
    }
    
    private func compositeText() -> NSImage {
        /// a local copy of whatever image data we need
//         let img = self.image
        let img = resizedImage()
        
        /// what is our available caption width?
        let availableWidth = img.size.width - marginSize*2
        
        //https://developer.apple.com/library/mac/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/CapturingScreenContents/CapturingScreenContents.html#//apple_ref/doc/uid/TP40012302-CH10-SW32
        /// Probably more accurately referred to as a "compositingImage", because the drawingHandler is overriden
        /// to do the composition whenever drawn.  As per ABOVE_URL^^^, the old way of doing this offscreen by using
        /// lockFocus results in unexpected results from whatever the current graphics context is (e.g. retina ruins everything)
        let compositedImage = NSImage(size: img.size, flipped: false, drawingHandler: { frame in
            
            img.drawInRect(frame)
            
            if let topText = self.formattedTextForTop() {
                let neededLinesToDraw = ceil(topText.size.width / availableWidth)
                let topRect = NSRect(x: self.marginSize, y: 0, width: availableWidth, height: frame.height)
                topText.drawInRect(topRect)
            }
            
            if let bottomText = self.formattedTextForBottom() {
                let neededLinesToDraw = ceil(bottomText.size.width / availableWidth)
                let neededHeightToDraw = bottomText.size.height * neededLinesToDraw
                let botRect = NSRect(x: self.marginSize, y: 0, width: availableWidth, height: neededHeightToDraw)
                bottomText.drawInRect(botRect)
            }
            
            return true
        })
        
        return compositedImage
    }
    
    /// figure out how to draw the bottom message
    /// ...which needs to know its rendered size so it can be bottom aligned
    /// ...and is long so it will probably wrap across multiple lines
    private func formattedTextForBottom() -> NSAttributedString? {
        if let msg = self.bottomMessage {
            
            let pStyle = NSMutableParagraphStyle()
            //pStyle.lineSpacing = -9
            //pStyle.lineHeightMultiple = 0.5
            
            let msgString = NSAttributedString(
                string: msg,
                attributes: [
                    NSFontAttributeName: NSFont(name: "Impact", size: 48)!,
                    NSStrokeColorAttributeName: NSColor.blackColor(),
                    NSStrokeWidthAttributeName: NSNumber(float: -4.2),
                    NSForegroundColorAttributeName: NSColor.whiteColor(),
                    //NSParagraphStyleAttributeName: pStyle,
                ])
            return msgString
        } else {
            return nil
        }
    }

    /// figure out how to draw the top message.
    /// this one is easier since its a fixed length of chars (for now) and top aligned.
    /// but does need to be right aligned.
    private func formattedTextForTop() -> NSAttributedString? {
        if let msg = self.topMessage {
            let rightAlignParagraphStyle = NSMutableParagraphStyle()
            rightAlignParagraphStyle.alignment = NSTextAlignment(rawValue: 1)! //NSRightTextAlignment, swift cant seem to find?
            
            let msgString = NSAttributedString(
                string: msg,
                attributes: [
                    NSFontAttributeName: NSFont(name: "Impact", size: 32)!,
                    NSStrokeColorAttributeName: NSColor.blackColor(),
                    NSStrokeWidthAttributeName: NSNumber(float: -4.2),
                    NSForegroundColorAttributeName: NSColor.whiteColor(),
                    NSParagraphStyleAttributeName: rightAlignParagraphStyle
                ])
            
            return msgString
        } else {
            return nil
        }
    }
    
    /// render the final representation of the image as JPEG data
    func render() -> NSData {
        let compositedImage = compositeText()

        let imageRep = NSBitmapImageRep(data: compositedImage.TIFFRepresentation!)!
        
        println("DEBUG[render]: imageRep.size (in points): \(imageRep.size)")
        println("DEBUG[render]: final pixel dimensions: \(imageRep.pixelsWide)x\(imageRep.pixelsHigh)")
        
        let imageData = imageRep.representationUsingType(NSBitmapImageFileType.NSJPEGFileType, properties: [NSImageCompressionFactor: 0.8])
        return imageData!
    }
    
}