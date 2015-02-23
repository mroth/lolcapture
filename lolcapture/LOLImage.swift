import Foundation
import AppKit

class LOLImage: NSImage {
    
    /// how much margin to have on the sides of the image
    let marginSize: CGFloat = 10.0
    
    // what size the final image should be after resizing and cropping
    let desiredFinalWidth:  CGFloat = 640.0 // 960.0 is native on new iMac after cropping
    let desiredFinalHeight: CGFloat = 480.0 // 720.0 is native on new iMac after cropping
    var desiredFinalSize: CGSize {
        return CGSize(width: desiredFinalWidth, height: desiredFinalHeight)
    }

    // instance vars for the messages
    var topMessage: String?
    var bottomMessage: String?
    
    
    convenience init?(data: NSData, bottomMessage: String?, topMessage: String?) {
        self.init(data: data)
        self.bottomMessage = bottomMessage
        self.topMessage = topMessage
    }
    
    /// the raw image resized and cropped to defaults
    func resizedImage() -> NSImage {
        return LOLImage.resizeImageToFill(self, targetSize: self.desiredFinalSize)
    }
    
    /// utility function: resizes a given image to fill target size, while preserving aspect ratio
    class func resizeImageToFill(image: NSImage, targetSize: CGSize) -> NSImage {
        let imgSize = image.size
        Logger.debug("starting, image size: \(imgSize), target size: \(targetSize)")
        
        let widthRatio  = targetSize.width  / imgSize.width
        let heightRatio = targetSize.height / imgSize.height
        Logger.debug("finding widthRatio: \(widthRatio), heightRatio: \(heightRatio)")
        
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
        
        let croppingRect = NSRect(
            x: (imgSize.width  - croppingSize.width)/2,   // half the difference in width
            y: (imgSize.height - croppingSize.height)/2,  // half the difference in height
            width: croppingSize.width,
            height: croppingSize.height)
        
        Logger.debug("using croppingRect: \(croppingRect)")
        
        // do actual resize via custom drawingHandler
        // again need to avoid .lockFocus type stuff because it causes unexpected results on Retina now
        let resizingImage = NSImage(size: targetSize, flipped: false, drawingHandler: { frame in
            image.drawInRect(frame, fromRect: croppingRect, operation: .CompositeOverlay, fraction: 1.0)
            return true
        })

        return resizingImage
    }
    
    private func compositeTextOverResizedImage() -> NSImage {
        /// a local copy of whatever image data we need
        let img = resizedImage()

        /// what is our available caption width?
        let availableWidth = img.size.width - marginSize*2
        
        //https://developer.apple.com/library/mac/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/CapturingScreenContents/CapturingScreenContents.html#//apple_ref/doc/uid/TP40012302-CH10-SW32
        /// Probably more accurately referred to as a "compositingImage", because the drawingHandler is overriden
        /// to do the composition whenever drawn.  As per ABOVE_URL^^^, the old way of doing this offscreen by using
        /// lockFocus results in unexpected results from whatever the current graphics context is (e.g. retina ruins everything)
        let compositedImage = NSImage(size: img.size, flipped: false, drawingHandler: { frame in
            
            img.drawInRect(frame)
            
            if let topText = self.formattedTextForTopMessage() {
                let neededLinesToDraw = ceil(topText.size.width / availableWidth)
                let topRect = NSRect(x: self.marginSize, y: 0, width: availableWidth, height: frame.height)
                topText.drawInRect(topRect)
            }
            
            if let bottomText = self.formattedTextForBottomMessage() {
                let neededLinesToDraw = ceil(bottomText.size.width / availableWidth)
                let neededHeightToDraw = bottomText.size.height * neededLinesToDraw
                let botRect = NSRect(x: self.marginSize, y: 0, width: availableWidth, height: neededHeightToDraw)
                bottomText.drawInRect(botRect)
            }
            
            return true
        })
        
        return compositedImage
    }
    
    /// formatted text for the bottomMessage
    /// ...which needs to know its rendered size so it can be bottom aligned
    /// ...and is long so it will probably wrap across multiple lines
    private func formattedTextForBottomMessage() -> NSAttributedString? {
        if let msg = self.bottomMessage {
            
            // TODO: need to get the line-height reduced but this doesnt
            //       seem to work in conjunction with drawInRect cropping.
            //
            //let pStyle = NSMutableParagraphStyle()
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

    /// formatted text for the topMessage
    private func formattedTextForTopMessage() -> NSAttributedString? {
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
        let compositedImage = compositeTextOverResizedImage()

        let imageRep = NSBitmapImageRep(data: compositedImage.TIFFRepresentation!)!
        
        Logger.debug("imageRep.size (in points): \(imageRep.size)")
        Logger.debug("final pixel dimensions: \(imageRep.pixelsWide)x\(imageRep.pixelsHigh)")
        
        let imageData = imageRep.representationUsingType(NSBitmapImageFileType.NSJPEGFileType, properties: [NSImageCompressionFactor: 0.8])
        return imageData!
    }
    
}