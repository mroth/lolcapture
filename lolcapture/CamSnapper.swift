import Foundation
import AVFoundation

class CamSnapper {

    /// What is the currently preferred capture device?
    ///
    /// - returns: The default device used to capture photographic images.
    class func preferredDevice() -> AVCaptureDevice? {
        // TODO: figure out what's up with the below being implicitly unwrapped.
        //
        // This will change to an optional in Swift 1.2 hopefully -- assuming
        // AVFoundation is updated with Obj-C nullable properties?
        //
        // In the meantime, we can cast it ourselves via return type.
        return AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    }

    /// Returns a list of all devices that are capable of capturing images
    class func compatibleDevices() -> [AVCaptureDevice]? {
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]
        if devices.count == 0 { return nil }
        return devices
    }

    /// Returns all devices where either the ID or name matches the query string
    class func devicesMatchingString(query: String) -> [AVCaptureDevice]? {
        if let candidates = compatibleDevices() {
            let matches = candidates.filter {
                $0.uniqueID.lowercaseString.rangeOfString(query)      != nil ||
                $0.localizedName.lowercaseString.rangeOfString(query) != nil
            }
            // only return the match array if it actually contains a match
            if matches.count > 0 {
                return matches
            }
        }
        return nil
    }

    /// Do the main capture!
    ///
    /// - parameter warmupDelay: How long to delay capture for warmup (default: 0.0).
    /// - returns: The captured image data serialized to JPEG encoding.
    class func capture(warmupDelay: NSTimeInterval = 0.0, camera: AVCaptureDevice) -> NSData? {
        let captureSession = AVCaptureSession()

        // AVCaptureDevicInput is a failable initializer
        // ...so in theory this should catch failure?
        // ...in which case error proc isn't really needed, just Obj-C legacy
        if let cameraInput = try? AVCaptureDeviceInput(device: camera) {

            // begin configuration block
            captureSession.beginConfiguration()

            // set session defaults to photo capture
            captureSession.sessionPreset = AVCaptureSessionPresetPhoto

            // set default input to the camera
            captureSession.addInput(cameraInput)

            // make a still image output object and make it the output target
            let imageOutput = AVCaptureStillImageOutput()
            captureSession.addOutput(imageOutput)

            // commit configuration details and start session running
            captureSession.commitConfiguration()
            captureSession.startRunning()

            // use dispatch group to know when (async) image capture is done.
            //
            // it's a shame there doesn't seem to be a built-in synchronous way
            // to do this, since this is a rare occassion where we WANT to block
            // the main thread.
            let captureGroup = dispatch_group_create()
            dispatch_group_enter(captureGroup)
            Logger.debug("starting capture task")

            // sleep on this thread for delay to enable full camera warm-up.
            //
            // AVFoundation seems to be good at waiting till the camera sees an
            // image, but doesn't wait for white-balance & exposure adjustment.
            Logger.debug("sleeping for \(warmupDelay) sec. to allow camera to warmup...")
            NSThread.sleepForTimeInterval(warmupDelay)
            Logger.debug("...warmup complete.")

            // make a local optional var to hold the buffer after async capture
            var imageBuffer: CMSampleBuffer? = nil

            // do the async capture
            let videoChannel = imageOutput.connectionWithMediaType(AVMediaTypeVideo)
            imageOutput.captureStillImageAsynchronouslyFromConnection(
                videoChannel,
                completionHandler:{(buffer: CMSampleBuffer!, err: NSError!) in
                    Logger.debug("finishing capture task")
                    imageBuffer = buffer
                    dispatch_group_leave(captureGroup)
                }
            )

            // wait for dispatch group complete then stop session
            let timeoutSec = warmupDelay + 10
            let timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(timeoutSec * Double(NSEC_PER_SEC)))
            let dispatchResults = dispatch_group_wait(captureGroup, timeout)
            captureSession.stopRunning()

            // dispatch actually had timed out if results are non-zero
            if dispatchResults != 0 {
                print("ERROR! Timed out waiting for camera data.")
                return nil
            }

            // all good, return some jpeg pics plz
            return AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageBuffer)
        }

        // we shouldn't ever get here unless we can't get camera input.
        //
        // its unfortunate the results of the failure condition way down here,
        // but that seems to be a side-effect of using "if let" idomatic Swift.
        return nil
    }

}
