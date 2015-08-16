import Foundation
import AppKit

class LOLImage: NSImage {

    /// how much margin to have on the sides of the image
    let marginSize: CGFloat = 10.0

    // what size the final image should be after resizing and cropping
    var desiredFinalWidth:  CGFloat = 640.0 // 960.0 is native cropped for new 720p cameras
    var desiredFinalHeight: CGFloat = 480.0 // 720.0 is native cropped for new 720p cameras
    var desiredFinalSize: CGSize {
        return CGSize(width: desiredFinalWidth, height: desiredFinalHeight)
    }

    // instance vars for the messages
    var topMessage, bottomMessage: String?

    // initializer that adds our common message values
    convenience init?(data: NSData, bottomMessage: String?, topMessage: String?) {
        self.init(data: data)
        self.bottomMessage = bottomMessage
        self.topMessage = topMessage
    }

    /// The raw image resized and cropped to the current settings.
    func resizedImage() -> NSImage {
        return LOLImage.resizeImageToFill(self, targetSize: self.desiredFinalSize)
    }

    /// Resizes given image to fill target size, while preserving aspect ratio.
    ///
    /// The edges of the image on one plane will be cropped off to maintain the
    /// original pixel aspect ratio while allowing arbitrary boundaries.
    ///
    /// :param: image Image to be resized
    /// :param: targetSize Desired size of the resulting image
    /// :returns: A new lovely resized-to-fill image.
    class func resizeImageToFill(image: NSImage, targetSize: CGSize) -> NSImage {
        let imgSize = image.size
        Logger.debug("image size: \(imgSize), target size: \(targetSize)")

        // calculate the relative height/width ratios for original::target
        let widthRatio  = targetSize.width  / imgSize.width
        let heightRatio = targetSize.height / imgSize.height
        Logger.debug("widthRatio: \(widthRatio), heightRatio: \(heightRatio)")

        // okay, so what we essentially need to do is make a NSRect of the
        // appropriate size to preframe the image to the desired aspect ratio,
        // so that we can use it as the contextual srcRect for resize operation.

        // oddly(?), the constrained dimension is always the same absolute
        // value, no matter whether it is going to be applied to width / height.
        let constrainedDimension = imgSize.width / 4 * 3

        var cropSize: CGSize
        if widthRatio < heightRatio {
            cropSize = CGSize(width: constrainedDimension, height: imgSize.height)
        } else if widthRatio > heightRatio {
            cropSize = CGSize(width: imgSize.width, height: constrainedDimension)
        } else {
            cropSize = CGSize(width: imgSize.width, height: imgSize.height)
        }

        let croppingRect = NSRect(
            x: (imgSize.width  - cropSize.width)/2,  // 0.5x diff in width
            y: (imgSize.height - cropSize.height)/2, // 0.5x diff in height
            width: cropSize.width,
            height: cropSize.height)

        Logger.debug("using croppingRect: \(croppingRect)")

        // do actual resize via custom drawingHandler
        // again, need to avoid .lockFocus type stuff because it can cause
        // unexpected results on Retina aware machines.
        let resizingImage = NSImage(size: targetSize, flipped: false, drawingHandler: { frame in
            image.drawInRect(frame,
                             fromRect: croppingRect,
                             operation: .CompositeOverlay,
                             fraction: 1.0)
            return true
        })

        return resizingImage
    }

    /// Composites LOLText over the resized image.
    ///
    /// :returns: Image resized to current settings, with LOLtext applied.
    private func compositeTextOverResizedImage() -> NSImage {
        /// a local copy of whatever image data we need
        let img = resizedImage()

        /// what is our available caption width?
        let availableWidth = img.size.width - marginSize*2

        // https://developer.apple.com/library/mac/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/CapturingScreenContents/CapturingScreenContents.html#//apple_ref/doc/uid/TP40012302-CH10-SW32
        /// Probably more accurately referred to as a "compositingImage",
        /// because the drawingHandler is overriden to do the composition
        /// whenever drawn.  As per ABOVE_URL^^^, the old way of doing this
        /// offscreen by using lockFocus results in unexpected results from
        /// the current graphics context (e.g. retina ruins everything).
        let compositedImage = NSImage(size: img.size, flipped: false, drawingHandler: { frame in

            img.drawInRect(frame)

            if let topText = self.formattedTextForTopMessage() {
                let neededLinesToDraw = ceil(topText.size.width / availableWidth)
                let topRect = NSRect(x: self.marginSize,
                                     y: 0,
                                     width: availableWidth,
                                     height: frame.height)

                topText.drawInRect(topRect)
            }

            if let bottomText = self.formattedTextForBottomMessage() {
                let neededLinesToDraw = ceil(bottomText.size.width / availableWidth)
                let neededHeightToDraw = bottomText.size.height * neededLinesToDraw
                let botRect = NSRect(x: self.marginSize,
                                     y: 0,
                                     width: availableWidth,
                                     height: neededHeightToDraw)

                bottomText.drawInRect(botRect)
            }

            return true
        })

        return compositedImage
    }

    /// :returns: Formatted text for the `bottomMessage`.
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

    /// :returns: Formatted text for the `topMessage`.
    private func formattedTextForTopMessage() -> NSAttributedString? {
        if let msg = self.topMessage {
            let rightAlignParagraphStyle = NSMutableParagraphStyle()
            rightAlignParagraphStyle.alignment = NSTextAlignment.RightTextAlignment

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
