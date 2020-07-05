import SwiftUI
import MobileCoreServices


/**
Convenience function for initializing an object and modifying its properties

```
let label = with(NSTextField()) {
	$0.stringValue = "Foo"
	$0.textColor = .systemBlue
	view.addSubview($0)
}
```
*/
@discardableResult
func with<T>(_ item: T, update: (inout T) throws -> Void) rethrows -> T {
	var this = item
	try update(&this)
	return this
}


extension DispatchQueue {
	/**
	```
	DispatchQueue.main.asyncAfter(duration: 100.milliseconds) {
		print("100ms later")
	}
	```
	*/
	func asyncAfter(duration: TimeInterval, execute: @escaping () -> Void) {
		asyncAfter(deadline: .now() + duration, execute: execute)
	}
}


func delay(seconds: TimeInterval, closure: @escaping () -> Void) {
	DispatchQueue.main.asyncAfter(duration: seconds, execute: closure)
}


extension Collection {
	/**
	Returns a infinite sequence with consecutively unique random elements from the collection.

	```
	let x = [1, 2, 3].uniqueRandomElementIterator()

	x.next()
	//=> 2
	x.next()
	//=> 1

	for element in x.prefix(2) {
		print(element)
	}
	//=> 3
	//=> 1
	```
	*/
	func uniqueRandomElement() -> AnyIterator<Element> {
		var previousNumber: Int?

		return AnyIterator {
			var offset: Int
			repeat {
				offset = Int.random(in: 0..<self.count)
			} while offset == previousNumber
			previousNumber = offset

			let index = self.index(self.startIndex, offsetBy: offset)
			return self[index]
		}
	}
}


extension UIImage {
	/// Initialize with a URL.
	/// `AppKit.NSImage` polyfill.
	convenience init?(contentsOf url: URL) {
		self.init(contentsOfFile: url.path)
	}

	convenience init(color: UIColor, size: CGSize) {
		UIGraphicsBeginImageContextWithOptions(size, true, 0)
		color.setFill()
		UIRectFill(CGRect(origin: .zero, size: size))
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		self.init(cgImage: image!.cgImage!)
	}

	func resized(to size: CGSize) -> UIImage {
		UIGraphicsImageRenderer(size: size).image { _ in
			draw(in: CGRect(origin: .zero, size: size))
		}
	}
}


extension UIView {
	/// The most efficient solution.
	@objc
	func toImage() -> UIImage {
		UIGraphicsImageRenderer(size: bounds.size).image { _ in
			self.drawHierarchy(in: bounds, afterScreenUpdates: true)
		}
	}
}


extension UIEdgeInsets {
	init(all: CGFloat) {
		self.init(top: all, left: all, bottom: all, right: all)
	}

	init(horizontal: CGFloat, vertical: CGFloat) {
		self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
	}

	func inset(rect: CGRect) -> CGRect { rect.inset(by: self) }
}


extension UIScrollView {
	@objc
	override func toImage() -> UIImage {
		UIGraphicsImageRenderer(size: bounds.size).image { _ in
			let newBounds = bounds.offsetBy(dx: -contentOffset.x, dy: -contentOffset.y)
			self.drawHierarchy(in: newBounds, afterScreenUpdates: true)
		}
	}
}


extension CGSize {
	func aspectFit(to size: Self) -> Self {
		let ratio = max(size.width / width, size.height / height)
		return Self(width: width * CGFloat(ratio), height: height * CGFloat(ratio))
	}
}


enum App {
	static let id = Bundle.main.bundleIdentifier!
	static let name = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String

	static let isFirstLaunch: Bool = {
		let key = "__hasLaunched__"

		if UserDefaults.standard.bool(forKey: key) {
			return false
		} else {
			UserDefaults.standard.set(true, forKey: key)
			return true
		}
	}()
}


extension NSError {
	/**
	Use this for generic app errors.

	- Note: Prefer using a specific enum-type error whenever possible.

	- Parameter description: The description of the error. This is shown as the first line in error dialogs.
	- Parameter recoverySuggestion: Explain how the user how they can recover from the error. For example, "Try choosing a different directory". This is usually shown as the second line in error dialogs.
	- Parameter userInfo: Metadata to add to the error. Can be a custom key or any of the `NSLocalizedDescriptionKey` keys except `NSLocalizedDescriptionKey` and `NSLocalizedRecoverySuggestionErrorKey`.
	- Parameter domainPostfix: String to append to the `domain` to make it easier to identify the error. The domain is the app's bundle identifier.
	*/
	static func appError(
		_ description: String,
		recoverySuggestion: String? = nil,
		userInfo: [String: Any] = [:],
		domainPostfix: String? = nil
	) -> Self {
		var userInfo = userInfo
		userInfo[NSLocalizedDescriptionKey] = description

		if let recoverySuggestion = recoverySuggestion {
			userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion
		}

		return .init(
			domain: domainPostfix.map { "\(App.id) - \($0)" } ?? App.id,
			code: 1, // This is what Swift errors end up as.
			userInfo: userInfo
		)
	}
}


extension AppDelegate {
	// swiftlint:disable:next force_cast
	static let shared = UIApplication.shared.delegate as! AppDelegate
}


extension Binding where Value: Equatable {
	/**
	Get notified when the binding value changes to a different one.

	Can be useful to manually update non-reactive properties.

	```
	Toggle(
		"Foo",
		isOn: $foo.onChange {
			bar.isEnabled = $0
		}
	)
	```
	*/
	func onChange(_ action: @escaping (Value) -> Void) -> Self {
		.init(
			get: { self.wrappedValue },
			set: {
				let oldValue = self.wrappedValue
				self.wrappedValue = $0
				let newValue = self.wrappedValue
				if newValue != oldValue {
					action(newValue)
				}
			}
		)
	}
}


final class UIHostingView<Content: View>: UIView {
	private let rootViewHostingController: UIHostingController<Content>

	var rootView: Content {
		get { rootViewHostingController.rootView }
		set {
			rootViewHostingController.rootView = newValue
		}
	}

	required init(rootView: Content) {
		self.rootViewHostingController = UIHostingController(rootView: rootView)
		super.init(frame: .zero)
		rootViewHostingController.view.backgroundColor = .clear
		addSubview(rootViewHostingController.view)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		rootViewHostingController.view.frame = bounds
	}

	override func sizeToFit() {
		guard let superview = superview else {
			super.sizeToFit()
			return
		}

		frame.size = rootViewHostingController.sizeThatFits(in: superview.frame.size)
	}

	override func sizeThatFits(_ size: CGSize) -> CGSize {
		rootViewHostingController.sizeThatFits(in: size)
	}

	override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
		rootViewHostingController.sizeThatFits(in: targetSize)
	}

	override func systemLayoutSizeFitting(
		_ targetSize: CGSize,
		withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
		verticalFittingPriority: UILayoutPriority
	) -> CGSize {
		rootViewHostingController.sizeThatFits(in: targetSize)
	}
}


/// SwiftUI wrapper for the iOS image picker.
struct ImagePicker: UIViewControllerRepresentable {
	final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
		let parent: ImagePicker

		init(_ parent: ImagePicker) {
			self.parent = parent
		}

		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
			if let uiImage = info[.originalImage] as? UIImage {
				parent.image = uiImage
			}

			parent.presentationMode.wrappedValue.dismiss()
		}
	}

	@Environment(\.presentationMode) private var presentationMode

	var sourceType: UIImagePickerController.SourceType
	var mediaTypes = [kUTTypeImage as String]
	@Binding var image: UIImage?

	func makeCoordinator() -> Coordinator { .init(self) }

	func makeUIViewController(context: Context) -> UIImagePickerController {
		let picker = UIImagePickerController()
		picker.delegate = context.coordinator
		return picker
	}

	func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
		uiViewController.sourceType = sourceType
		uiViewController.mediaTypes = mediaTypes
	}
}


private struct FadeInAfterDelayModifier: ViewModifier {
	@State private var isShowingContent = false

	let delay: TimeInterval

	func body(content: Content) -> some View {
		content
			.disabled(!isShowingContent)
			.opacity(isShowingContent ? 1 : 0)
			.animation(
				Animation
					.easeIn(duration: 0.5)
					.delay(delay)
			)
			.onAppear {
				self.isShowingContent = true
			}
	}
}

extension View {
	/**
	Delay making a view visible. It still takes up space before it's shown.

	- Important: Must be placed last.

	- Note: If the view is conditionally shown, it will fade in each time it reappears. To prevent this, you can implement your own state:
	```
	if isLoading {
		LoadingView()
			.transition(.opacity)
			.animation(
				.easeIn(duration: 0.5)
				.delay(1)
			)
	}
	```
	*/
	func fadeInAfterDelay(_ delay: TimeInterval) -> some View {
		modifier(FadeInAfterDelayModifier(delay: delay))
	}
}


extension UIImage {
	private final class ImageSaver: NSObject {
		private let completion: (Error?) -> Void

		init(image: UIImage, completion: @escaping (Error?) -> Void) {
			self.completion = completion
			super.init()

			UIImageWriteToSavedPhotosAlbum(image, self, #selector(handler), nil)
		}

		@objc
		private func handler(_ image: UIImage?, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer?) {
			completion(error)
		}
	}

	/**
	Save the image to the user's photo library.

	The image will be saved to the “Camera Roll” album if the device has a camera or “Saved Photos” otherwise.
	*/
	func saveToPhotosLibrary(_ completion: @escaping (Error?) -> Void) {
		_ = ImageSaver(image: self, completion: completion)
	}
}
