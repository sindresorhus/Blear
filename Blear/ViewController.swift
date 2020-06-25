import Combine
import SwiftUI

final class ViewController: UIViewController {
	// Awful, but makes the SwiftUI transition easier.
	static let shared = AppDelegate.shared.window?.rootViewController as! ViewController

	override var canBecomeFirstResponder: Bool { true }
	override var prefersStatusBarHidden: Bool { true }

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

	let stockImages = Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: "Bundled Photos")!
	lazy var randomImageIterator: AnyIterator<URL> = self.stockImages.uniqueRandomElement()

	var lastBlurAmount = Float(Constants.initialBlurAmount)
	var sourceImage: UIImage?
	var workItem: DispatchWorkItem?

	override func viewDidLoad() {
		super.viewDidLoad()

		view.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(scrollView)
		scrollView.addSubview(imageView)

		setUpContentView()

		// Important that this is here at the end for the fading to work.
		randomImage()
	}

	override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
		if motion == .motionShake {
			randomImage()
		}
	}

	func setUpContentView() {
		let contentView = ContentView(
			onSliderChange: {
				self.lastBlurAmount = Float($0)
				self.updateImage(blurAmount: Float($0))
			},
			onImage: {
				self.changeImage($0)
			}
		)
		let hostingView = UIHostingView(rootView: contentView)
		hostingView.translatesAutoresizingMaskIntoConstraints = false
		hostingView.tintColor = .white
		view.addSubview(hostingView)
		// We cannot constrain to the top anchor as SwiftUI doesn't pass touch event through to the scrollview. Instead, we set a fixed height.
		// hostingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
		hostingView.heightAnchor.constraint(equalToConstant: 80).isActive = true
		hostingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
		hostingView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
		hostingView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
	}

	func blurImage(_ blurAmount: Float) -> UIImage {
		UIImageEffects.imageByApplyingBlur(
			to: sourceImage,
			withRadius: CGFloat(blurAmount * 0.8),
			tintColor: UIColor(white: 1, alpha: CGFloat(max(0, min(0.25, blurAmount * 0.004)))),
			saturationDeltaFactor: CGFloat(max(1, min(2.8, blurAmount * (DeviceInfo.isPad ? 0.035 : 0.045)))),
			maskImage: nil
		)
	}

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

	func changeImage(_ image: UIImage) {
		let temp = UIImageView(image: scrollView.toImage())
		view.insertSubview(temp, aboveSubview: scrollView)
		let imageViewSize = image.size.aspectFit(to: view.frame.size)
		scrollView.contentSize = imageViewSize
		scrollView.contentOffset = .zero
		imageView.frame = CGRect(origin: .zero, size: imageViewSize)
		imageView.image = image
		sourceImage = image.resized(to: CGSize(width: imageViewSize.width / 2, height: imageViewSize.height / 2))
		updateImage(blurAmount: lastBlurAmount)

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
}
