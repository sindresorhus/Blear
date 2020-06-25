import UIKit
import Photos
import MobileCoreServices
import Combine
import JGProgressHUD

final class ViewController: UIViewController {
	var sourceImage: UIImage?

	let stockImages = Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: "Bundled Photos")!
	lazy var randomImageIterator: AnyIterator<URL> = self.stockImages.uniqueRandomElement()

	var workItem: DispatchWorkItem?

	lazy var scrollView = with(UIScrollView()) {
		$0.frame = view.bounds
		$0.bounces = false
		$0.showsHorizontalScrollIndicator = false
		$0.showsVerticalScrollIndicator = false
		$0.contentInsetAdjustmentBehavior = .never
	}

	lazy var imageView = with(UIImageView()) {
		$0.image = UIImage(color: .black, size: view.frame.size)
		$0.contentMode = .scaleAspectFit
		$0.clipsToBounds = true
		$0.frame = view.bounds
	}

	lazy var slider = with(UISlider()) {
		let SLIDER_MARGIN: CGFloat = 120
		$0.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - SLIDER_MARGIN, height: view.frame.size.height)
		$0.minimumValue = 10
		$0.maximumValue = 100
		$0.value = Float(Constants.initialBlurAmount)
		$0.isContinuous = true
		$0.setThumbImage(UIImage(named: "SliderThumb")!, for: .normal)
		$0.autoresizingMask = [
			.flexibleWidth,
			.flexibleTopMargin,
			.flexibleBottomMargin,
			.flexibleLeftMargin,
			.flexibleRightMargin
		]
		$0.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
	}

	var saveBarButton: UIBarButtonItem!

	override var canBecomeFirstResponder: Bool { true }

	override var prefersStatusBarHidden: Bool { true }

	override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
		if motion == .motionShake {
			randomImage()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.addSubview(scrollView)
		scrollView.addSubview(imageView)

		let TOOLBAR_HEIGHT: CGFloat = 80 + window.safeAreaInsets.bottom
		let toolbar = UIToolbar(frame: CGRect(x: 0, y: view.frame.size.height - TOOLBAR_HEIGHT, width: view.frame.size.width, height: TOOLBAR_HEIGHT))
		toolbar.autoresizingMask = .flexibleWidth
		toolbar.alpha = 0.6
		toolbar.tintColor = .white

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
		saveBarButton = UIBarButtonItem(image: UIImage(named: "PickButton")!, target: self, action: #selector(pickImage), width: 20)
		toolbar.items = [
			saveBarButton,
			.flexibleSpace,
			UIBarButtonItem(customView: slider),
			.flexibleSpace,
			UIBarButtonItem(image: UIImage(named: "SaveButton")!, target: self, action: #selector(saveImage), width: 20)
		]
		view.addSubview(toolbar)

		// Important that this is here at the end for the fading to work.
		randomImage()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		showShakeTipIfNeeded()
	}

	@objc
	func pickImage() {
		let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
				self.showImagePicker(with: .camera)
			})
		}

		actionSheet.addAction(UIAlertAction(title: "Choose from Library", style: .default) { _ in
			self.showImagePicker(with: .photoLibrary)
		})

		actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		if let popoverPresentationController = actionSheet.popoverPresentationController {
			popoverPresentationController.barButtonItem = saveBarButton
		}
		present(actionSheet, animated: true, completion: nil)
	}

	func showImagePicker(with type: UIImagePickerController.SourceType) {
		let picker = UIImagePickerController()
		picker.sourceType = type
		picker.mediaTypes = [kUTTypeImage as String]
		picker.delegate = self
		present(picker, animated: true, completion: nil)
	}

	func blurImage(_ blurAmount: Float) -> UIImage {
		UIImageEffects.imageByApplyingBlur(
			to: sourceImage,
			withRadius: CGFloat(blurAmount * (IS_LARGE_SCREEN ? 0.8 : 1.2)),
			tintColor: UIColor(white: 1, alpha: CGFloat(max(0, min(0.25, blurAmount * 0.004)))),
			saturationDeltaFactor: CGFloat(max(1, min(2.8, blurAmount * (IS_IPAD ? 0.035 : 0.045)))),
			maskImage: nil
		)
	}

	@objc
	func updateImage(blurAmount: Float) {
		if let workItem = workItem {
			workItem.cancel()
		}

		let workItem = DispatchWorkItem {
			let temp = self.blurImage(blurAmount)
			DispatchQueue.main.async {
				self.imageView.image = temp
			}
		}
		self.workItem = workItem

		DispatchQueue.global(qos: .userInteractive).async(execute: workItem)
	}

	@objc
	func sliderChanged(_ sender: UISlider) {
		updateImage(blurAmount: sender.value)
	}

	var saveImageCancellable: AnyCancellable?

	@objc
	func saveImage(_ button: UIBarButtonItem) {
		button.isEnabled = false

		let HUD = JGProgressHUD(style: .dark)
		HUD.indicatorView = JGProgressHUDSuccessIndicatorView()
		HUD.animation = JGProgressHUDFadeZoomAnimation()
		HUD.vibrancyEnabled = true
		HUD.contentInsets = UIEdgeInsets(all: 30)

		saveImageCancellable = PHPhotoLibrary.save(
			image: scrollView.toImage(),
			toAlbum: "Blear"
		)
			.receive(on: DispatchQueue.main)
			.sink(receiveCompletion: { error in
				switch error {
				case .finished:
					HUD.show(in: self.view)
					HUD.dismiss(afterDelay: 0.8)

					button.isEnabled = true

					self.showWallpaperTipIfNeeded()
				case .failure(let error):
					HUD.indicatorView = JGProgressHUDErrorIndicatorView()
					HUD.textLabel.text = error.localizedDescription
					HUD.show(in: self.view)
					HUD.dismiss(afterDelay: 3)
				}

				button.isEnabled = true
			}, receiveValue: { _ in })
	}

	func changeImage(_ image: UIImage) {
		let temp = UIImageView(image: scrollView.toImage())
		view.insertSubview(temp, aboveSubview: scrollView)
		let imageViewSize = image.size.aspectFit(to: view.frame.size)
		scrollView.contentSize = imageViewSize
		scrollView.contentOffset = .zero
		imageView.frame = CGRect(origin: .zero, size: imageViewSize)
		imageView.image = image
		sourceImage = image.resized(to: CGSize(width: imageViewSize.width / 2, height: imageViewSize.height / 2))
		updateImage(blurAmount: slider.value)

		// The delay here is important so it has time to blur the image before we start fading.
		UIView.animate(
			withDuration: 0.6,
			delay: 0.3,
			options: .curveEaseInOut,
			animations: {
				temp.alpha = 0
			}, completion: { _ in
				temp.removeFromSuperview()
			}
		)
	}

	func randomImage() {
		changeImage(UIImage(contentsOf: randomImageIterator.next()!)!)
	}

	func previewScrollingToUser() {
		let x = scrollView.contentSize.width - scrollView.frame.size.width
		let y = scrollView.contentSize.height - scrollView.frame.size.height
		scrollView.setContentOffset(CGPoint(x: x, y: y), animated: true)

		delay(seconds: 1) {
			self.scrollView.setContentOffset(.zero, animated: true)
		}
	}

	func showShakeTipIfNeeded() {
		guard App.isFirstLaunch else {
			return
		}

		let alert = UIAlertController(
			title: "Tip",
			message: "Shake the device to get a random image.",
			preferredStyle: .alert
		)

		alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
			self.previewScrollingToUser()
		})

		present(alert, animated: true)
	}

	func showWallpaperTipIfNeeded() {
		guard App.isFirstLaunch else {
			return
		}

		delay(seconds: 1) {
			let alert = UIAlertController(
				title: "Changing Wallpaper",
				message: "In the Photos app, go to the wallpaper you just saved, tap the action button on the bottom left, and choose “Use as Wallpaper”.",
				preferredStyle: .alert
			)
			alert.addAction(UIAlertAction(title: "OK", style: .default))
			self.present(alert, animated: true)
		}
	}
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
		guard let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
			dismiss(animated: true, completion: nil)
			return
		}

		changeImage(chosenImage)
		dismiss(animated: true, completion: nil)
	}

	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		dismiss(animated: true, completion: nil)
	}
}
