import Foundation
import AVFoundation

class CamSnapper {
    
    /// Returns a list of devices that are capable of capturing images
    class func compatibleDevices() -> [(id: String, name: String)] {
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as [AVCaptureDevice]
        return devices.map { ($0.uniqueID, $0.localizedName) }
    }
    
    /// What is the currently preferred capture device?
    private class func preferredDevice() -> AVCaptureDevice? {
        // TODO: need to figure out wtf is up with this being implicitly unwrapped.
        // I mean it can legit be nil right? This will all change in Swift 1.2 I guess -- assuming
        // AVFoundation is updated with Obj-C nullable properties.
        return AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    }
    
    /// Do the main capture!
    class func capture() -> NSData? {
        let camera = preferredDevice()
        let captureSession = AVCaptureSession()
        
        // AVCaptureDevicInput is a failable initializer.. so in theory this should catch failure?
        // ...in which case the error proc isn't really needed.
        if let cameraInput = AVCaptureDeviceInput(device: camera, error: nil) {
            

            // begin configuration block
            captureSession.beginConfiguration()
            
            // set session defaults to photo capture
            captureSession.sessionPreset = AVCaptureSessionPresetPhoto
            
            // set default input to the camera
            captureSession.addInput(cameraInput)
            
            // make a still image output object and make it the output target
            var imageOutput = AVCaptureStillImageOutput()
            captureSession.addOutput(imageOutput)
            
            // commit configuration details and start session running
            captureSession.commitConfiguration()
            captureSession.startRunning()
            
            // use a dispatch group so we will know when the (async) image capture is done
            // it's a shame there doesn't seem to be a built in synchronous way to do this
            // since this is a rare occassion where we WANT to block the main thread.
            let captureGroup = dispatch_group_create()
            dispatch_group_enter(captureGroup)
            debug("capture", "starting capture task")
            
            // make a local optional var to hold the buffer after async capture
            var imageBuffer: CMSampleBuffer? = nil
            
            // do the async capture
            let videoChannel = imageOutput.connectionWithMediaType(AVMediaTypeVideo)
            imageOutput.captureStillImageAsynchronouslyFromConnection(
                videoChannel,
                completionHandler:{(buffer: CMSampleBuffer!, err: NSError!) in
                    debug("capture", "finishing capture task")
                    imageBuffer = buffer
                    dispatch_group_leave(captureGroup)
                }
            )
            
            dispatch_group_wait(captureGroup, DISPATCH_TIME_FOREVER) //FIXME: let's not wait forever
            captureSession.stopRunning()
            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageBuffer)
            return imageData
        }
        
        // we shouldn't ever get here unless we can't get camera input.
        // its unfortunate this moves the results of the failure condition way down here but that seems
        // to be the side-effect of using "if let" idomatic Swift.  Should look into this more.
        return nil
    }
    
    
    
    
}