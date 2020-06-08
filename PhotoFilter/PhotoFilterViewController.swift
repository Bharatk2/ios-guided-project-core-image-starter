import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

class PhotoFilterViewController: UIViewController {
    
    /// created core image context.
    private let context = CIContext(options: nil)
    private var originalImage: UIImage? {
        didSet {
            //            updateViews()
            guard let originalImage = originalImage else {
                scaledImage = nil // clear out image if set to nil
                return
            }
            var scaledSize = imageView.bounds.size
            let scale = UIScreen.main.scale
            scaledSize = CGSize(width: scaledSize.width * scale, height: scaledSize.height * scale)
            scaledImage = originalImage.imageByScaling(toSize: scaledSize)
        }
    }
    
    private var scaledImage: UIImage? {
        didSet {
            updateViews()
        }
    }
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var contrastSlider: UISlider!
    @IBOutlet weak var saturationSlider: UISlider!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let filter = CIFilter.colorControls()
        filter.brightness = 1 // ranges are dpendent on implementation / documentation
        print(filter.attributes)
        // this is just a test image to see whhat's going on.
        originalImage = imageView.image
    }
    //    414*3 = 1,242 pixels [potrait on iphone 11 pro max ]
    
    private func filterImage(_ image: UIImage) -> UIImage? {
        //        UIImager -> CGImage -> CIImage
        guard let cgImage = image.cgImage else { return nil }
        
        let ciImage = CIImage(cgImage: cgImage)
        
        //        Filtering
        let filter = CIFilter.colorControls() // mya not wrk for some custom filters (KVC Protocols)
        filter.inputImage = ciImage
        filter.brightness = brightnessSlider.value
        filter.contrast = contrastSlider.value
        filter.saturation = saturationSlider.value
        
        //        CIImage -> CGImage -> UIImage - pull the image out - hooking up the pluming
        guard let outputCIImage = filter.outputImage else { return nil }
        
        // get to the cg image to get the pixels data render
        //        render
        
        guard let outputCGImage = context.createCGImage(outputCIImage, from: CGRect(origin: .zero, size: image.size)) else { return nil }
        
        
        return UIImage(cgImage: outputCGImage)
    }
    
    private func updateViews() {
        //        what to do in order for the updateviews to change the image
        guard let scaledImage = scaledImage else { return }
        imageView.image = filterImage(scaledImage)
        
    }
    // MARK: Actions
    
    @IBAction func choosePhotoButtonPressed(_ sender: Any) {
        // TODO: show the photo picker so we can choose on-device photos
        // UIImagePickerController + Delegate
        presentImagePickerController()
        
    }
    
    private func presentImagePickerController() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("eRROR: THE PHOTO LIBRARY NOT AVAILABLE ")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
        
        
    }
    
    @IBAction func savePhotoButtonPressed(_ sender: UIButton) {
        // TODO: Save to photo library
        saveAndFilterPhoto()
        
    }
    
    private func saveAndFilterPhoto() {
        guard let originalImage = originalImage else { return }
        
        guard let processedImage = filterImage(originalImage.flattened) else { return }
        
        PHPhotoLibrary.requestAuthorization { (status) in
            guard status == .authorized else { return } // TODO: Handle other cases
            //        as long as we are authorized then we are able to do changes
            PHPhotoLibrary.shared().performChanges({
                
                PHAssetChangeRequest.creationRequestForAsset(from: processedImage)
                
            }) { (success, error) in
                if let error = error {
                    print("error saving photo: \(error)")
                    return
                }
                DispatchQueue.main.async {
                    print("saved photo")
                }
            }
        }
        
        
    }
    
    // MARK: Slider events
    
    @IBAction func brightnessChanged(_ sender: UISlider) {
        updateViews()
    }
    
    @IBAction func contrastChanged(_ sender: Any) {
        updateViews()
    }
    
    @IBAction func saturationChanged(_ sender: Any) {
        updateViews()
    }
    
}

extension PhotoFilterViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            originalImage = image
        }
        
        dismiss(animated: false)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}

extension PhotoFilterViewController: UINavigationControllerDelegate {
    
}

