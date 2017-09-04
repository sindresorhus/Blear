import UIKit
import FDTake
import IIDelayedAction
import NZAssetsLibrary
import JGProgressHUD

let IS_IPAD = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad
let IS_IPHONE = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone
let SCREEN_WIDTH = UIScreen.main.bounds.size.width
let SCREEN_HEIGHT = UIScreen.main.bounds.size.height
let IS_LARGE_SCREEN = IS_IPHONE && max(SCREEN_WIDTH, SCREEN_HEIGHT) >= 736.0

final class ViewController: UIViewController {
	var sourceImage: UIImage?
	var imageView: UIImageView!
	var slider: UISlider!
	var blurAmount: Float = 50
	let stockImages = Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: "bundled-photos")!
	var delayedAction: IIDelayedAction?
	lazy var randomImageIterator: AnyIterator<URL> = self.stockImages.uniqueRandomElement()

	override var canBecomeFirstResponder: Bool {
		return true
	}

	override var prefersStatusBarHidden: Bool {
		return true
	}

	override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
		if motion == .motionShake {
			randomImage()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		// This is to ensure that it always ends up with the current blur amount when the slider stops
		// since we're using `DispatchQueue.global().async` the order of events aren't serial
		delayedAction = IIDelayedAction({ _ in }, withDelay: 0.2)
		delayedAction?.onMainThread = false

		imageView = createInitialImageView()
		view.addSubview(imageView)

		let pickImageButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-pick"), style: .plain, target: self, action: #selector(pickImage))
		pickImageButton.width = 20

		slider = createSlider()
		let sliderAsToolbarItem = UIBarButtonItem(customView: slider)

		let saveImageButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-save"), style: .plain, target: self, action: #selector(saveImage))
		saveImageButton.width = 20

		let TOOLBAR_HEIGHT: CGFloat = IS_IPAD ? 80 : 70
		let toolbar = UIToolbar(frame: CGRect(x: 0, y: view.frame.size.height - TOOLBAR_HEIGHT, width: view.frame.size.width, height: TOOLBAR_HEIGHT))
		toolbar.autoresizingMask = .flexibleWidth
		toolbar.alpha = 0.6
		toolbar.tintColor = #colorLiteral(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)

		// Remove background
		toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
		toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)

		// Gradient background
		let GRADIENT_PADDING: CGFloat = 40
		let gradient = CAGradientLayer()
		gradient.frame = CGRect(x: 0, y: -GRADIENT_PADDING, width: toolbar.frame.size.width, height: toolbar.frame.size.height + GRADIENT_PADDING)
		gradient.colors = [
			UIColor.clear.cgColor,
			UIColor.black.withAlphaComponent(0.1).cgColor,
			UIColor.black.withAlphaComponent(0.3).cgColor,
			UIColor.black.withAlphaComponent(0.4).cgColor
		]
		toolbar.layer.addSublayer(gradient)

		let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

		toolbar.items = [
			pickImageButton,
			flexible,
			sliderAsToolbarItem,
			flexible,
			saveImageButton
		]
		view.addSubview(toolbar)

		// Important that this is here at the end for the fading to work
		randomImage()
	}

	func createSlider() -> UISlider {
		let SLIDER_MARGIN: CGFloat = 120
		let slider = UISlider(frame: CGRect(x: 0, y: 0, width: view.frame.size.width - SLIDER_MARGIN, height: view.frame.size.height))
		slider.minimumValue = 10
		slider.maximumValue = 100
		slider.value = blurAmount
		slider.isContinuous = true
		slider.setThumbImage(#imageLiteral(resourceName: "slider-thumb"), for: .normal)
		slider.autoresizingMask = [
			.flexibleWidth,
			.flexibleTopMargin,
			.flexibleBottomMargin,
			.flexibleLeftMargin,
			.flexibleRightMargin
		]
		slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
		return slider
	}

	func pickImage() {
		let fdTake = FDTakeController()
		fdTake.allowsVideo = false
		fdTake.didGetPhoto = { photo, _ in
			self.changeImage(photo)
		}
		fdTake.present()
	}

	func blurImage(_ blurAmount: Float) -> UIImage {
		return UIImageEffects.imageByApplyingBlur(
			to: sourceImage,
			withRadius: CGFloat(blurAmount * (IS_LARGE_SCREEN ? 0.8 : 1.2)),
			tintColor: UIColor(white: 1, alpha: CGFloat(max(0, min(0.25, blurAmount * 0.004)))),
			saturationDeltaFactor: CGFloat(max(1, min(2.8, blurAmount * (IS_IPAD ? 0.035 : 0.045)))),
			maskImage: nil
		)
	}

	func createInitialImageView() -> UIImageView {
		UIGraphicsBeginImageContextWithOptions(CGSize(width: view.frame.size.width, height: view.frame.size.height), false, 0)
		let p = UIBezierPath(rect: CGRect(origin: .zero, size: view.frame.size))
		UIColor.black.setFill()
		p.fill()
		let blackFill = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		let imageView = UIImageView(image: blackFill)
		imageView.contentMode = .scaleAspectFill
		imageView.clipsToBounds = true
		imageView.frame = CGRect(origin: .zero, size: view.frame.size)
		return imageView
	}

	func updateImage() {
		DispatchQueue.global(qos: .userInteractive).async {
			let tmp = self.blurImage(self.blurAmount)
			DispatchQueue.main.async {
				self.imageView.image = tmp
			}
		}
	}

	func updateImageDebounced() {
		performSelector(inBackground: #selector(updateImage), with: IS_IPAD ? 0.1 : 0.06)
	}

	func sliderChanged(_ sender: UISlider) {
		blurAmount = sender.value
		updateImageDebounced()
		delayedAction?.action { _ in
			self.updateImage()
		}
	}

	func saveImage(_ button: UIBarButtonItem) {
		button.isEnabled = false

		// Rewrap the image as PNG
		let pngImage = UIImage(data: UIImagePNGRepresentation(imageView.image!)!)
		let assetsLibrary = NZAssetsLibrary.default()

		assetsLibrary?.save(pngImage, toAlbum: "Blear") { error in
			button.isEnabled = true

			let HUD = JGProgressHUD(style: .light)!
			HUD.indicatorView = nil
			HUD.animation = JGProgressHUDFadeZoomAnimation()

			if let error = error {
				HUD.textLabel.text = error.localizedDescription
			} else {
				HUD.indicatorView = JGProgressHUDImageIndicatorView(image: #imageLiteral(resourceName: "hud-saved"))
				HUD.indicatorView.tintColor = .black
			}

			HUD.show(in: self.view)
			HUD.dismiss(afterDelay: 0.8)

			// Only on first save
			if UserDefaults.standard.isFirstLaunch {
				Util.delay(seconds: 1) {
					let alert = UIAlertController(
						title: "Changing Wallpaper",
						message: "In the Photos app go to the wallpaper you just saved, tap the action button on the bottom left and choose 'Use as Wallpaper'.",
						preferredStyle: .alert
					)
					alert.addAction(UIAlertAction(title: "OK", style: .default))
					self.present(alert, animated: true)
				}
			}
		}
	}

	func changeImage(_ image: UIImage) {
		let tmp = NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: imageView)) as! UIImageView
		view.insertSubview(tmp, belowSubview: slider.superview!)
		imageView.image = image
		sourceImage = UIImage(view: imageView)
		updateImageDebounced()

		// The delay here is important so it has time to blur the image before we start fading
		UIView.animate(withDuration: 0.6, delay: (IS_LARGE_SCREEN ? 0.4 : 0.1), options: .curveEaseInOut, animations: {
			tmp.alpha = 0
		}, completion: { _ in
			tmp.removeFromSuperview()
		})
	}

	func randomImage() {
		changeImage(UIImage(url: randomImageIterator.next()!)!)
	}
}
