import SwiftUI
import Combine
import MobileCoreServices
import PhotosUI
import StoreKit
import Sentry
import Defaults


func initSentry() {
	#if !DEBUG
	SentrySDK.start {
		$0.dsn = "https://56d71bf257f043f8ad95ce7b61d52b41@o844094.ingest.sentry.io/6398796"
		$0.enableSwizzling = false
	}
	#endif
}


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


extension Collection {
	/**
	Returns a infinite sequence with consecutively unique random elements from the collection.

	```
	let sequence = [1, 2, 3, 4].infiniteConsecutivelyUniqueRandomSequence()

	for element in sequence.prefix(3) {
		print(element)
	}
	//=> 3
	//=> 1
	//=> 2

	let iterator = sequence.makeIterator()

	iterator.next()
	//=> 4
	iterator.next()
	//=> 1
	```
	*/
	func infiniteConsecutivelyUniqueRandomSequence() -> AnySequence<Element> {
		AnySequence { () -> AnyIterator in
			var previousOffset: Int?

			return AnyIterator {
				var offset: Int
				repeat {
					offset = Int.random(in: 0..<count)
				} while offset == previousOffset
				previousOffset = offset

				return self[index(startIndex, offsetBy: offset)]
			}
		}
	}
}


extension UIImage {
	/**
	Initialize with a URL.

	`AppKit.NSImage` polyfill.
	*/
	convenience init?(contentsOf url: URL) {
		self.init(contentsOfFile: url.path)
	}

	convenience init(color: UIColor, size: CGSize) {
		let bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)

		let image = UIGraphicsImageRenderer(size: size).image { context in
			color.setFill()
			context.fill(bounds)
		}

		self.init(
			cgImage: image.cgImage!,
			scale: image.scale,
			orientation: image.imageOrientation
		)
	}

	/**
	Resize the image so the longest side is equal or less than `longestSide`.
	*/
	func resized(longestSide: Double) -> UIImage {
		let length = longestSide
		let width = size.width
		let height = size.height
		let ratio = width / height

		let newSize = width > height
			? CGSize(width: length, height: length / ratio)
			: CGSize(width: length * ratio, height: length)

		return resized(to: newSize)
	}

	func resized(to size: CGSize) -> UIImage {
		UIGraphicsImageRenderer(size: size).image { _ in
			draw(in: CGRect(origin: .zero, size: size))
		}
	}
}


extension UIView {
	/**
	The most efficient solution.
	*/
	@objc
	func toImage() -> UIImage {
		UIGraphicsImageRenderer(size: bounds.size).image { _ in
			drawHierarchy(in: bounds, afterScreenUpdates: true)
		}
	}
}


extension UIEdgeInsets {
	init(all: Double) {
		self.init(top: all, left: all, bottom: all, right: all)
	}

	init(horizontal: Double, vertical: Double) {
		self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
	}

	func inset(rect: CGRect) -> CGRect { rect.inset(by: self) }
}


extension UIScrollView {
	@objc
	override func toImage() -> UIImage {
		UIGraphicsImageRenderer(size: bounds.size).image { [self] _ in
			let newBounds = bounds.offsetBy(dx: -contentOffset.x, dy: -contentOffset.y)
			drawHierarchy(in: newBounds, afterScreenUpdates: true)
		}
	}
}


extension CGSize {
	func aspectFit(to size: Self) -> Self {
		let ratio = max(size.width / width, size.height / height)
		return Self(width: width * ratio, height: height * ratio)
	}
}


extension Bundle {
	/**
	Returns the current app's bundle whether it's called from the app or an app extension.
	*/
	static let app: Bundle = {
		var components = main.bundleURL.path.split(separator: "/")

		guard let index = (components.lastIndex { $0.hasSuffix(".app") }) else {
			return main
		}

		components.removeLast((components.count - 1) - index)
		return Bundle(path: components.joined(separator: "/")) ?? main
	}()
}


enum SSApp {
	static let idString = Bundle.main.bundleIdentifier!
	static let name = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String
	static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
	static let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
	static let versionWithBuild = "\(version) (\(build))"
	static let rootName = Bundle.app.object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String

	static let isFirstLaunch: Bool = {
		let key = "__hasLaunched__"

		if UserDefaults.standard.bool(forKey: key) {
			return false
		}

		UserDefaults.standard.set(true, forKey: key)
		return true
	}()
}


extension SSApp {
	/**
	- Note: Call this lazily only when actually needed as otherwise it won't get the live info.
	*/
	static func appFeedbackUrl() -> URL {
		let metadata =
			"""
			\(SSApp.name) \(SSApp.versionWithBuild)
			Bundle Identifier: \(SSApp.idString)
			OS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
			Model: \(Device.modelIdentifier)
			"""

		let info: [String: String] = [
			"product": SSApp.name,
			"metadata": metadata
		]

		return URL(string: "https://sindresorhus.com/feedback", query: info)!
	}
}

// Conforms to the informal `NSErrorRecoveryAttempting` protocol.
final class ErrorRecoveryAttempter: NSObject {
	struct Option {
		let title: String

		/**
		Return a boolean for whether the recovery was successful.
		*/
		let action: () -> Bool
	}

	private let recoveryOptions: [Option]

	override func attemptRecovery(
		fromError error: Error,
		optionIndex recoveryOptionIndex: Int,
		delegate: Any?,
		didRecoverSelector: Selector?,
		contextInfo: UnsafeMutableRawPointer?
	) {
		let didRecover = recoveryOptions[safe: recoveryOptionIndex]?.action() ?? false
		_ = (delegate as AnyObject?)?.perform(didRecoverSelector, with: didRecover, with: contextInfo)
	}

	override func attemptRecovery(
		fromError error: Error,
		optionIndex recoveryOptionIndex: Int
	) -> Bool {
		recoveryOptions[safe: recoveryOptionIndex]?.action() ?? false
	}

	fileprivate init(recoveryOptions: [Option]) {
		self.recoveryOptions = recoveryOptions
		super.init()
	}
}

struct GeneralError: LocalizedError, CustomNSError {
	// LocalizedError
	let errorDescription: String?
	let recoverySuggestion: String?
	let helpAnchor: String?

	// CustomNSError
	let errorUserInfo: [String: Any]
	// We don't define `errorDomain` as it will generate something like `AppName.GeneralError` by default.

	/**
	Use this for general app errors.

	- Note: Prefer using a specific enum-type error whenever possible.

	- Parameter description: The description of the error. This is shown as the first line in error dialogs.
	- Parameter recoverySuggestion: Explain how the user how they can recover from the error. For example, "Try choosing a different directory". This is usually shown as the second line in error dialogs.
	- Parameter userInfo: Metadata to add to the error. Can be a custom key or any of the `NSLocalizedDescriptionKey` keys except `NSLocalizedDescriptionKey` and `NSLocalizedRecoverySuggestionErrorKey`.
	*/
	init(
		_ description: String,
		recoverySuggestion: String? = nil,
		userInfo: [String: Any] = [:],
		url: URL? = nil,
		underlyingErrors: [Error] = [],
		recoveryOptions: [ErrorRecoveryAttempter.Option] = [],
		helpAnchor: String? = nil
	) {
		self.errorDescription = description
		self.recoverySuggestion = recoverySuggestion
		self.helpAnchor = helpAnchor

		self.errorUserInfo = {
			var userInfo = userInfo

			if !recoveryOptions.isEmpty {
				userInfo[NSLocalizedRecoveryOptionsErrorKey] = recoveryOptions.map(\.title)
				userInfo[NSRecoveryAttempterErrorKey] = ErrorRecoveryAttempter(recoveryOptions: recoveryOptions)
			}

			if !underlyingErrors.isEmpty {
				userInfo[NSMultipleUnderlyingErrorsKey] = underlyingErrors
			}

			if let url {
				userInfo[NSURLErrorKey] = url
			}

			return userInfo
		}()
	}
}

extension String {
	/**
	Convert a string into an error.
	*/
	var toError: some LocalizedError { GeneralError(self) }
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
		guard let superview else {
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


private struct FadeInAfterDelayModifier: ViewModifier {
	@State private var isShowingContent = false

	let delay: TimeInterval

	func body(content: Content) -> some View {
		content
			.disabled(!isShowingContent)
			.opacity(isShowingContent ? 1 : 0)
			.animation(
				.easeIn(duration: 0.5)
					.delay(delay),
				value: isShowingContent
			)
			.onAppear {
				isShowingContent = true
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
		private let continuation: CheckedContinuation<Void, Error>

		init(image: UIImage, continuation: CheckedContinuation<Void, Error>) {
			self.continuation = continuation
			super.init()

			UIImageWriteToSavedPhotosAlbum(image, self, #selector(handler), nil)
		}

		@objc
		private func handler(_ image: UIImage?, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer?) {
			if let error {
				continuation.resume(throwing: error)
				return
			}

			continuation.resume()
		}
	}

	/**
	Save the image to the user's photo library.

	The image will be saved to the “Camera Roll” album if the device has a camera or “Saved Photos” otherwise.
	*/
	func saveToPhotosLibrary() async throws {
		try await withCheckedThrowingContinuation { continuation in
			_ = ImageSaver(image: self, continuation: continuation)
		}

		guard PHPhotoLibrary.authorizationStatus(for: .addOnly) == .authorized else {
			#if APP_EXTENSION
			let recoverySuggestion = "You can manually grant access in “Settings › \(SSApp.rootName) › Photos”."
			let recoveryOptions = [ErrorRecoveryAttempter.Option]()
			#else
			let recoverySuggestion = "You can manually grant access in the “Settings”."
			let recoveryOptions = [
				ErrorRecoveryAttempter.Option(title: "Settings") {
					guard SSApp.canOpenSettings else {
						return false
					}

					SSApp.openSettings()
					return true
				}
			]
			#endif

			throw GeneralError(
				"“\(SSApp.rootName)” does not have access to add photos to your photo library.",
				recoverySuggestion: recoverySuggestion,
				recoveryOptions: recoveryOptions
			)
		}
	}
}


extension Binding {
	/**
	Converts the binding of an optional value to a binding to a boolean for whether the value is non-nil.

	You could use this in a `isPresent` parameter for a sheet, alert, etc, to have it show when the value is non-nil.
	*/
	func isPresent<Wrapped>() -> Binding<Bool> where Value == Wrapped? {
		.init(
			get: { wrappedValue != nil },
			set: { isPresented in
				if !isPresented {
					wrappedValue = nil
				}
			}
		)
	}
}


extension View {
	/**
	This allows multiple alerts on a single view, which `.alert()` doesn't.
	*/
	func alert2(
		_ title: Text,
		isPresented: Binding<Bool>,
		@ViewBuilder actions: () -> some View,
		@ViewBuilder message: () -> some View
	) -> some View {
		background(
			EmptyView()
				.alert(
					title,
					isPresented: isPresented,
					actions: actions,
					message: message
				)
		)
	}

	/**
	This allows multiple alerts on a single view, which `.alert()` doesn't.
	*/
	func alert2(
		_ title: String,
		isPresented: Binding<Bool>,
		@ViewBuilder actions: () -> some View,
		@ViewBuilder message: () -> some View
	) -> some View {
		alert2(
			Text(title),
			isPresented: isPresented,
			actions: actions,
			message: message
		)
	}

	/**
	This allows multiple alerts on a single view, which `.alert()` doesn't.
	*/
	func alert2(
		_ title: Text,
		message: String? = nil,
		isPresented: Binding<Bool>,
		@ViewBuilder actions: () -> some View
	) -> some View {
		// swiftlint:disable:next trailing_closure
		alert2(
			title,
			isPresented: isPresented,
			actions: actions,
			message: {
				if let message {
					Text(message)
				}
			}
		)
	}

	// This is a convenience method and does not exist natively.
	/**
	This allows multiple alerts on a single view, which `.alert()` doesn't.
	*/
	func alert2(
		_ title: String,
		message: String? = nil,
		isPresented: Binding<Bool>,
		@ViewBuilder actions: () -> some View
	) -> some View {
		// swiftlint:disable:next trailing_closure
		alert2(
			title,
			isPresented: isPresented,
			actions: actions,
			message: {
				if let message {
					Text(message)
				}
			}
		)
	}

	/**
	This allows multiple alerts on a single view, which `.alert()` doesn't.
	*/
	func alert2(
		_ title: Text,
		message: String? = nil,
		isPresented: Binding<Bool>
	) -> some View {
		// swiftlint:disable:next trailing_closure
		alert2(
			title,
			message: message,
			isPresented: isPresented,
			actions: {}
		)
	}

	// This is a convenience method and does not exist natively.
	/**
	This allows multiple alerts on a single view, which `.alert()` doesn't.
	*/
	func alert2(
		_ title: String,
		message: String? = nil,
		isPresented: Binding<Bool>
	) -> some View {
		// swiftlint:disable:next trailing_closure
		alert2(
			title,
			message: message,
			isPresented: isPresented,
			actions: {}
		)
	}
}


extension View {
	// This is a convenience method and does not exist natively.
	/**
	This allows multiple alerts on a single view, which `.alert()` doesn't.
	*/
	func alert2<T>(
		title: (T) -> Text,
		presenting data: Binding<T?>,
		@ViewBuilder actions: (T) -> some View,
		@ViewBuilder message: (T) -> some View
	) -> some View {
		background(
			EmptyView()
				.alert(
					data.wrappedValue.map(title) ?? Text(""),
					isPresented: data.isPresent(),
					presenting: data.wrappedValue,
					actions: actions,
					message: message
				)
		)
	}

	// This is a convenience method and does not exist natively.
	/**
	This allows multiple alerts on a single view, which `.alert()` doesn't.
	*/
	func alert2<T>(
		title: (T) -> Text,
		message: ((T) -> String?)? = nil,
		presenting data: Binding<T?>,
		@ViewBuilder actions: (T) -> some View
	) -> some View {
		alert2(
			title: { title($0) },
			presenting: data,
			actions: actions,
			message: {
				if let message = message?($0) {
					Text(message)
				}
			}
		)
	}

	// This is a convenience method and does not exist natively.
	/**
	This allows multiple alerts on a single view, which `.alert()` doesn't.
	*/
	func alert2<T>(
		title: (T) -> String,
		message: ((T) -> String?)? = nil,
		presenting data: Binding<T?>,
		@ViewBuilder actions: (T) -> some View
	) -> some View {
		alert2(
			title: { Text(title($0)) },
			message: message,
			presenting: data,
			actions: actions
		)
	}

	// This is a convenience method and does not exist natively.
	/**
	This allows multiple alerts on a single view, which `.alert()` doesn't.
	*/
	func alert2<T>(
		title: (T) -> Text,
		message: ((T) -> String?)? = nil,
		presenting data: Binding<T?>
	) -> some View {
		// swiftlint:disable:next trailing_closure
		alert2(
			title: title,
			message: message,
			presenting: data,
			actions: { _ in }
		)
	}

	// This is a convenience method and does not exist natively.
	/**
	This allows multiple alerts on a single view, which `.alert()` doesn't.
	*/
	func alert2<T>(
		title: (T) -> String,
		message: ((T) -> String?)? = nil,
		presenting data: Binding<T?>
	) -> some View {
		alert2(
			title: { Text(title($0)) },
			message: message,
			presenting: data
		)
	}
}


extension Dictionary {
	/**
	Adds the elements of the given dictionary to a copy of self and returns that.

	Identical keys in the given dictionary overwrites keys in the copy of self.

	- Note: This exists as an addition to `+` as Swift sometimes struggle to infer the type of `dict + dict`.
	*/
	func appending(_ dictionary: Self) -> Self {
		var newDictionary = self

		for (key, value) in dictionary {
			newDictionary[key] = value
		}

		return newDictionary
	}
}


extension NSObject {
	// Note: It's intentionally a getter to get the dynamic self.
	/**
	Returns the class name without module name.
	*/
	static var simpleClassName: String { String(describing: self) }

	/**
	Returns the class name of the instance without module name.
	*/
	var simpleClassName: String { Self.simpleClassName }
}


extension Error {
	/**
	Whether the error matches the given domain and code.
	*/
	func matches(domain: String, code: Int) -> Bool {
		let nsError = self as NSError
		return nsError.domain == domain && nsError.code == code
	}

	/**
	Whether the error or any of its underlying errors match the given domain and code.
	*/
	func matchesDeep(domain: String, code: Int) -> Bool {
		let nsError = self as NSError

		return matches(domain: domain, code: code)
			|| nsError.underlyingErrors.contains { $0.matches(domain: domain, code: code) }
	}
}


extension Error {
	/**
	Whether the error was originally created as an `NSError`.
	*/
	var isNSError: Bool {
		// This used to work before Swift 5.6:
		// `var isNsError: Bool { Self.self is NSError.Type }``
		(self as NSError).simpleClassName != "__SwiftNativeNSError"
	}
}

extension NSError {
	static func from(error: Error, userInfo: [String: Any] = [:]) -> NSError {
		let nsError = error as NSError

		// Since Error and NSError are often bridged between each other, we check if it was originally an NSError and then return that.
		guard !error.isNSError else {
			guard !userInfo.isEmpty else {
				return nsError
			}

			return nsError.appending(userInfo: userInfo)
		}

		var userInfo = nsError.userInfo.appending(userInfo)
		userInfo[NSLocalizedDescriptionKey] = error.localizedDescription

		let errorName = "\(error)".split(separator: "(").first ?? ""

		return .init(
			domain: "\(SSApp.idString) - \(nsError.domain)\(errorName.isEmpty ? "" : ".")\(errorName)",
			code: nsError.code,
			userInfo: userInfo
		)
	}

	/**
	Returns a new error with the user info appended.
	*/
	func appending(userInfo newUserInfo: [String: Any]) -> NSError {
		// Cannot use `Self` here: https://github.com/apple/swift/issues/58046
		NSError(
			domain: domain,
			code: code,
			userInfo: userInfo.appending(newUserInfo)
		)
	}
}


extension SSApp {
	/**
	Report an error to the chosen crash reporting solution.
	*/
	@inlinable
	static func reportError(
		_ error: Error,
		userInfo: [String: Any] = [:],
		file: String = #fileID,
		line: Int = #line
	) {
		guard !(error is CancellationError) else {
			#if DEBUG
			print("[\(file):\(line)] CancellationError:", error)
			#endif
			return
		}

		let userInfo = userInfo
			.appending([
				"file": file,
				"line": line
			])

		let error = NSError.from(
			error: error,
			userInfo: userInfo
		)

		#if DEBUG
		print("[\(file):\(line)] Reporting error:", error)
		#endif

		#if canImport(Sentry)
		SentrySDK.capture(error: error)
		#endif
	}

	/**
	Report an error message to the chosen crash reporting solution.
	*/
	@inlinable
	static func reportError(
		_ message: String,
		userInfo: [String: Any] = [:],
		file: String = #fileID,
		line: Int = #line
	) {
		reportError(
			message.toError,
			file: file,
			line: line
		)
	}
}


extension CGImage {
	static func from(_ data: Data, maxPixelSize: Int? = nil) throws -> CGImage {
		let sourceOptions: [CFString: Any] = [
			kCGImageSourceShouldCache: false
		]

		var thumbnailOptions: [CFString: Any] = [
			kCGImageSourceCreateThumbnailFromImageAlways: true,
			kCGImageSourceCreateThumbnailWithTransform: true,
			kCGImageSourceShouldCacheImmediately: true
		]

		if let maxPixelSize {
			thumbnailOptions[kCGImageSourceThumbnailMaxPixelSize] = maxPixelSize
		}

		guard
			let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary),
			let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary)
		else {
			throw "Could not load image from data.".toError
		}

		return image
	}
}


extension UIImage {
	static func from(_ data: Data, maxPixelSize: Int) throws -> Self {
		Self(cgImage: try .from(data, maxPixelSize: maxPixelSize))
	}
}


struct SinglePhotoPickerButton: View {
	@State private var isPresented = false
	@State private var selection: PhotosPickerItem?

	var title = "Choose Image"
	var iconName = "photo"
	var onCompletion: (PhotosPickerItem) -> Void

	var body: some View {
		Button(title, systemImage: iconName) {
			isPresented = true
		}
			.tint(.white)
			.photosPicker(
				isPresented: $isPresented,
				selection: $selection,
				matching: .images,
				preferredItemEncoding: .compatible
			)
			.tint(nil) // Prevent the white tint from affecting the picker.
			.onChange(of: selection) {
				guard let selection = $0 else {
					return
				}

				onCompletion(selection)
			}
	}
}


extension UIDevice {
	// TODO: Find out a way to do this without Combine.
	fileprivate static let didShakeSubject = PassthroughSubject<Void, Never>()

	var didShake: AnyAsyncSequence<Void> {
		Self.didShakeSubject.eraseToAnySequence()
	}
}

extension UIWindow {
	override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
		if motion == .motionShake {
			UIDevice.didShakeSubject.send()
		}

		super.motionEnded(motion, with: event)
	}
}

private struct DeviceShakeViewModifier: ViewModifier {
	let action: () -> Void

	func body(content: Content) -> some View {
		content
			.onAppear() // Shake doesn't work without this. (iOS 14.5)
			.task {
				for await _ in UIDevice.current.didShake {
					action()
				}
			}
	}
}

extension View {
	/**
	Perform an action when the device is shaked.
	*/
	func onDeviceShake(perform action: @escaping (() -> Void)) -> some View {
		modifier(DeviceShakeViewModifier(action: action))
	}
}


extension CGSize {
	var longestSide: Double { max(width, height) }
}


extension View {
	/**
	Conditionally modify the view. For example, apply modifiers, wrap the view, etc.

	```
	Text("Foo")
		.padding()
		.if(someCondition) {
			$0.foregroundColor(.pink)
		}
	```

	```
	VStack() {
		Text("Line 1")
		Text("Line 2")
	}
		.if(someCondition) { content in
			ScrollView(.vertical) { content }
		}
	```
	*/
	@ViewBuilder
	func `if`(
		_ condition: @autoclosure () -> Bool,
		modify: (Self) -> some View
	) -> some View {
		if condition() {
			modify(self)
		} else {
			self
		}
	}

	/**
	This overload makes it possible to preserve the type. For example, doing an `if` in a chain of `Text`-only modifiers.

	```
	Text("🦄")
		.if(isOn) {
			$0.fontWeight(.bold)
		}
		.kerning(10)
	```
	*/
	func `if`(
		_ condition: @autoclosure () -> Bool,
		modify: (Self) -> Self
	) -> Self {
		condition() ? modify(self) : self
	}
}


extension URL: ExpressibleByStringLiteral {
	/**
	Example:

	```
	let url: URL = "https://sindresorhus.com"
	```
	*/
	public init(stringLiteral value: StaticString) {
		self.init(string: "\(value)")!
	}
}

extension URL {
	/**
	Example:

	```
	URL("https://sindresorhus.com")
	```
	*/
	init(_ staticString: StaticString) {
		self.init(string: "\(staticString)")!
	}
}


struct SendFeedbackButton: View {
	var body: some View {
		Link("Feedback & Support", destination: SSApp.appFeedbackUrl())
	}
}


struct MoreAppsButton: View {
	var body: some View {
		Link("More Apps by Me", destination: "itms-apps://apps.apple.com/developer/id328077650")
	}
}


struct RateOnAppStoreButton: View {
	let appStoreID: String

	var body: some View {
		Link("Rate App", destination: URL(string: "itms-apps://apps.apple.com/app/id\(appStoreID)?action=write-review")!)
	}
}


typealias QueryDictionary = [String: String]

extension CharacterSet {
	/**
	Characters allowed to be unescaped in an URL.

	https://tools.ietf.org/html/rfc3986#section-2.3
	*/
	static let urlUnreservedRFC3986 = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
}

private func escapeQueryComponent(_ query: String) -> String {
	query.addingPercentEncoding(withAllowedCharacters: .urlUnreservedRFC3986)!
}

extension Dictionary where Key == String {
	/**
	This correctly escapes items. See `escapeQueryComponent`.
	*/
	var toQueryItems: [URLQueryItem] {
		map {
			URLQueryItem(
				name: escapeQueryComponent($0),
				value: escapeQueryComponent("\($1)")
			)
		}
	}
}

extension URLComponents {
	/**
	This correctly escapes items. See `escapeQueryComponent`.
	*/
	init?(string: String, query: QueryDictionary) {
		self.init(string: string)
		self.queryDictionary = query
	}

	/**
	This correctly escapes items. See `escapeQueryComponent`.
	*/
	var queryDictionary: QueryDictionary {
		get {
			queryItems?.toDictionary { ($0.name, $0.value) }.compactValues() ?? [:]
		}
		set {
			// Using `percentEncodedQueryItems` instead of `queryItems` since the query items are already custom-escaped. See `escapeQueryComponent`.
			percentEncodedQueryItems = newValue.toQueryItems
		}
	}
}


extension URL {
	init?(string: String, query: QueryDictionary) {
		guard let url = URLComponents(string: string, query: query)?.url else {
			return nil
		}

		self = url
	}
}


extension Dictionary {
	func compactValues<T>() -> [Key: T] where Value == T? {
		// TODO: Make this `compactMapValues(\.self)` when https://github.com/apple/swift/issues/55343 is fixed.
		compactMapValues { $0 }
	}
}


extension Sequence {
	/**
	Same as the above but supports returning optional values.

	```
	[(1, "a"), (nil, "b")].toDictionary { ($1, $0) }
	//=> ["a": 1, "b": nil]
	```
	*/
	func toDictionary<Key: Hashable, Value>(with pickKeyValue: (Element) -> (Key, Value?)) -> [Key: Value?] {
		var dictionary = [Key: Value?]()
		for element in self {
			let newElement = pickKeyValue(element)
			dictionary[newElement.0] = newElement.1
		}
		return dictionary
	}
}


enum Device {
	/**
	```
	Device.modelIdentifier
	//=> "iPhone12,8"
	```
	*/
	static let modelIdentifier: String = {
		#if targetEnvironment(simulator)
		return "Simulator"
		#else
		var systemInfo = utsname()
		uname(&systemInfo)
		let machineMirror = Mirror(reflecting: systemInfo.machine)

		return machineMirror.children.reduce(into: "") { identifier, element in
			guard
				let value = element.value as? Int8,
				value != 0
			else {
				return
			}

			identifier += String(UnicodeScalar(UInt8(value)))
		}
		#endif
	}()
}


/**
Store a value persistently in a `View` like with `@State`, but without updating the view on mutations.

You can use it for storing both value and reference types.
*/
@propertyWrapper
struct ViewStorage<Value>: DynamicProperty {
	private final class ValueBox {
		var value: Value

		init(_ value: Value) {
			self.value = value
		}
	}

	@State private var valueBox: ValueBox

	var wrappedValue: Value {
		get { valueBox.value }
		nonmutating set {
			valueBox.value = newValue
		}
	}

	var projectedValue: Binding<Value> {
		.init(
			get: { wrappedValue },
			set: {
				wrappedValue = $0
			}
		)
	}

	init(wrappedValue value: @autoclosure @escaping () -> Value) {
		self._valueBox = .init(wrappedValue: ValueBox(value()))
	}
}


private struct AccessHostingView: UIViewRepresentable {
	var callback: (UIView?) -> Void

	func makeUIView(context: Context) -> UIView { .init() }

	func updateUIView(_ uiView: UIView, context: Context) {
		callback(uiView)
	}
}

extension View {
	/**
	Access the native view hierarchy from SwiftUI.

	- Important: Don't assume the view is in the view hierarchy on the first callback invocation.
	*/
	func accessHostingView(_ callback: @escaping (UIView?) -> Void) -> some View {
		background {
			AccessHostingView(callback: callback)
		}
	}

	/**
	Access the window the view is contained in if any.
	*/
	func accessHostingWindow(_ callback: @escaping (UIWindow?) -> Void) -> some View {
		accessHostingView { uiView in
			guard let window = uiView?.window else {
				return
			}

			callback(window)
		}
	}

	/**
	Bind the native backing-window of a SwiftUI window to a property.
	*/
	func bindHostingWindow(_ window: Binding<UIWindow?>) -> some View {
		accessHostingWindow {
			window.wrappedValue = $0
		}
	}
}


extension Binding {
	/**
	Transform a binding.

	You can even change the type of the binding.

	```
	$foo.map(
		get: { $0.uppercased() },
		set: { $0.lowercased() }
	)
	```
	*/
	func map<Result>(
		get: @escaping (Value) -> Result,
		set: @escaping (Result) -> Value
	) -> Binding<Result> {
		.init(
			get: { get(wrappedValue) },
			set: { newValue in
				wrappedValue = set(newValue)
			}
		)
	}
}


/**
Useful in SwiftUI:

```
ForEach(persons.indexed(), id: \.1.id) { index, person in
	// …
}
```
*/
struct IndexedCollection<Base: RandomAccessCollection>: RandomAccessCollection {
	typealias Index = Base.Index
	typealias Element = (index: Index, element: Base.Element)

	let base: Base
	var startIndex: Index { base.startIndex }
	var endIndex: Index { base.endIndex }

	func index(after index: Index) -> Index {
		base.index(after: index)
	}

	func index(before index: Index) -> Index {
		base.index(before: index)
	}

	func index(_ index: Index, offsetBy distance: Int) -> Index {
		base.index(index, offsetBy: distance)
	}

	subscript(position: Index) -> Element {
		(index: position, element: base[position])
	}
}

extension RandomAccessCollection {
	/**
	Returns a sequence with a tuple of both the index and the element.
	*/
	func indexed() -> IndexedCollection<Self> {
		IndexedCollection(base: self)
	}
}


extension Sequence {
	/**
	Returns an array containing the non-nil elements.
	*/
	func compact<T>() -> [T] where Element == T? {
		// TODO: Make this `compactMap(\.self)` when https://github.com/apple/swift/issues/55343 is fixed.
		compactMap { $0 }
	}
}


extension NSError: Identifiable {
	public var id: String {
		"\(code)" + domain + localizedDescription + (localizedRecoverySuggestion ?? "")
	}
}


extension NSError {
	/**
	Use this for the second line in an alert.
	*/
	var localizedSecondaryDescription: String? {
		// The correct way to make a `LocalizedError` is to include the failure reason in the localized description too, but some errors do not correctly do this, so we try to get the failure reason if it's not part of the localized description.
		if
			let failureReason = localizedFailureReason,
			!localizedDescription.contains(failureReason)
		{
			return [
				failureReason,
				localizedRecoverySuggestion
			]
				.compact()
				.joined(separator: "\n\n")
		}

		return localizedRecoverySuggestion
	}
}


extension View {
	func alert(error: Binding<Error?>) -> some View {
		alert2(
			title: { ($0 as NSError).localizedDescription },
			message: { ($0 as NSError).localizedSecondaryDescription },
			presenting: error
		) {
			let nsError = $0 as NSError
			if
				let options = nsError.localizedRecoveryOptions,
				let recoveryAttempter = nsError.recoveryAttempter
			{
				// Alert only supports 3 buttons, so we limit it to 2 attempters, otherwise it would take over the cancel button.
				ForEach(options.prefix(2).indexed(), id: \.0) { index, option in
					Button(option) {
						// We use the old NSError mechanism for recovery attempt as recoverable NSError's are not bridged to RecoverableError.
						_ = (recoveryAttempter as AnyObject).attemptRecovery(fromError: nsError, optionIndex: index)
					}
				}
				Button("Cancel", role: .cancel) {}
			}
		}
	}
}


extension Sequence where Element: Sequence {
	func flatten() -> [Element.Element] {
		// TODO: Make this `flatMap(\.self)` when https://github.com/apple/swift/issues/55343 is fixed.
		flatMap { $0 }
	}
}


extension NSExtensionContext {
	func cancel() {
		completeRequest(returningItems: nil, completionHandler: nil)
	}
}


extension Collection {
	/**
	Returns the element at the specified index if it is within bounds, otherwise `nil`.
	*/
	subscript(safe index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
}


@available(iOSApplicationExtension, unavailable)
extension SSApp {
	private static var settingsUrl = URL(string: UIApplication.openSettingsURLString)!

	/**
	Whether the settings view in Settings for the current app exists and can be opened.
	*/
	static var canOpenSettings = UIApplication.shared.canOpenURL(settingsUrl)

	/**
	Open the settings view in Settings for the current app.

	- Important: Ensure you use `.canOpenSettings`.
	*/
	static func openSettings() {
		Task.detached { @MainActor in
			guard await UIApplication.shared.open(settingsUrl) else {
				// TODO: Present the error
				_ = "Failed to open settings for this app.".toError

				// TODO: Remove at some point.
				SSApp.reportError("Failed to open settings for this app.")
				return
			}
		}
	}
}


extension UIView {
	/**
	The highest ancestor superview.
	*/
	var highestAncestor: UIView? {
		var ancestor = superview

		while ancestor?.superview != nil {
			ancestor = ancestor?.superview
		}

		return ancestor
	}
}


extension EnvironmentValues {
	private struct ExtensionContext: EnvironmentKey {
		static var defaultValue: NSExtensionContext?
	}

	/**
	The `.extensionContext` of an app extension view controller.
	*/
	var extensionContext: NSExtensionContext? {
		get { self[ExtensionContext.self] }
		set {
			self[ExtensionContext.self] = newValue
		}
	}
}


extension NSExtensionContext {
	var inputItemsTyped: [NSExtensionItem] { inputItems as! [NSExtensionItem] }

	var attachments: [NSItemProvider] {
		inputItemsTyped.compactMap(\.attachments).flatten()
	}
}

// Strongly-typed versions of some of the methods.
extension NSItemProvider {
	func hasItemConforming(to contentType: UTType) -> Bool {
		hasItemConformingToTypeIdentifier(contentType.identifier)
	}

	func loadItem(
		for contentType: UTType,
		options: [AnyHashable: Any]? = nil // swiftlint:disable:this discouraged_optional_collection
	) async throws -> NSSecureCoding? {
		try await loadItem(
			forTypeIdentifier: contentType.identifier,
			options: options
		)
	}
}


extension SSApp {
	/**
	This is like `SSApp.runOnce()` but let's you have an else-statement too.

	```
	if SSApp.runOnceShouldRun(identifier: "foo") {
		// True only the first time and only once.
	} else {

	}
	```
	*/
	static func runOnceShouldRun(identifier: String) -> Bool {
		let key = "SS_App_runOnce__\(identifier)"

		guard !UserDefaults.standard.bool(forKey: key) else {
			return false
		}

		UserDefaults.standard.set(true, forKey: key)
		return true
	}

	/**
	Run a closure only once ever, even between relaunches of the app.
	*/
	static func runOnce(identifier: String, _ execute: () -> Void) {
		guard runOnceShouldRun(identifier: identifier) else {
			return
		}

		execute()
	}
}


extension View {
	@warn_unqualified_access
    func debugAction(_ closure: () -> Void) -> Self {
        //#if DEBUG
        closure()
        //#endif

        return self
    }
}

extension View {
	/**
	Print without inconvenience.

	```
	VStack {
		Text("Unicorns")
			.debugPrint("Something")
	}
	```
	*/
	@warn_unqualified_access
	func debugPrint(_ items: Any..., separator: String = " ") -> Self {
		self.debugAction {
			let item = items.map { "\($0)" }.joined(separator: separator)
			Swift.print(item)
		}
	}
}


extension Numeric {
	mutating func increment(by value: Self = 1) -> Self {
		self += value
		return self
	}

	mutating func decrement(by value: Self = 1) -> Self {
		self -= value
		return self
	}

	func incremented(by value: Self = 1) -> Self {
		self + value
	}

	func decremented(by value: Self = 1) -> Self {
		self - value
	}
}


extension Sequence {
	/**
	Returns the first non-`nil` result obtained from applying the given.
	*/
	public func firstNonNil<Result>(
		_ transform: (Element) throws -> Result?
	) rethrows -> Result? {
		for value in self {
			if let value = try transform(value) {
				return value
			}
		}
		return nil
	}
}


extension SSApp {
	@MainActor
	static var currentScene: UIWindowScene? {
		#if !APP_EXTENSION
		return UIApplication.shared
			.connectedScenes
			.filter { $0.activationState == .foregroundActive }
			.firstNonNil { $0 as? UIWindowScene }
				// If it's called early on in the launch, the scene might not be active yet, so we fall back to the inactive state.
				?? UIApplication.shared
					.connectedScenes
					.filter { $0.activationState == .foregroundInactive }
					.firstNonNil { $0 as? UIWindowScene }
		#else
		return nil
		#endif
	}
}


extension SSApp {
	private static let key = Defaults.Key<Int>("SSApp_requestReview", default: 0)

	/**
	Requests a review only after this method has been called the given amount of times.
	*/
	@MainActor
	static func requestReviewAfterBeingCalledThisManyTimes(_ counts: [Int]) {
		guard
			!SSApp.isFirstLaunch,
			counts.contains(Defaults[key].increment())
		else {
			return
		}

		Task { @MainActor in
			if let currentScene {
				SKStoreReviewController.requestReview(in: currentScene)
			}
		}
	}
}


struct AnyAsyncSequence<Element>: AsyncSequence {
	typealias AsyncIterator = AnyAsyncIterator<Element>

	struct AnyAsyncIterator<Element2>: AsyncIteratorProtocol {
		private let _next: () async -> Element2?

		init<I: AsyncIteratorProtocol>(_ asyncIterator: I) where I.Element == Element2 {
			var asyncIterator = asyncIterator
			self._next = {
				do {
					return try await asyncIterator.next()
				} catch {
					assertionFailure("AnyAsyncSequence should not throw.")
					return nil
				}
			}
		}

		mutating func next() async -> Element2? {
			await _next()
		}
	}

	private let _makeAsyncIterator: AsyncIterator

	init<S: AsyncSequence>(_ asyncSequence: S) where S.AsyncIterator.Element == AsyncIterator.Element {
		self._makeAsyncIterator = AnyAsyncIterator(asyncSequence.makeAsyncIterator())
	}

	func makeAsyncIterator() -> AsyncIterator {
		_makeAsyncIterator
	}
}

extension AsyncSequence {
	/**
	- Important: Only use this on non-throwing async sequences!
	*/
	func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> {
		AnyAsyncSequence(self)
	}
}

struct AnyThrowingAsyncSequence<Element>: AsyncSequence {
	typealias AsyncIterator = AnyAsyncIterator<Element>

	struct AnyAsyncIterator<Element2>: AsyncIteratorProtocol {
		private let _next: () async throws -> Element2?

		init<I: AsyncIteratorProtocol>(_ asyncIterator: I) where I.Element == Element2 {
			var asyncIterator = asyncIterator
			self._next = {
				try await asyncIterator.next()
			}
		}

		mutating func next() async throws -> Element2? {
			try await _next()
		}
	}

	private let _makeAsyncIterator: AsyncIterator

	init<S: AsyncSequence>(_ asyncSequence: S) where S.AsyncIterator.Element == AsyncIterator.Element {
		self._makeAsyncIterator = AnyAsyncIterator(asyncSequence.makeAsyncIterator())
	}

	func makeAsyncIterator() -> AsyncIterator {
		_makeAsyncIterator
	}
}

extension AsyncSequence {
	func eraseToAnyThrowingAsyncSequence() -> AnyThrowingAsyncSequence<Element> {
		AnyThrowingAsyncSequence(self)
	}
}

extension AsyncStream {
	@available(*, unavailable)
	func eraseToAnyThrowingAsyncSequence() -> AnyThrowingAsyncSequence<Element> {
		fatalError() // swiftlint:disable:this fatal_error_message
	}
}

extension AsyncThrowingStream {
	@available(*, unavailable)
	func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> {
		fatalError() // swiftlint:disable:this fatal_error_message
	}
}

extension Publisher {
	func eraseToAnySequence<Element>() -> AnyAsyncSequence<Element> where Output == Element, Failure == Never {
		AnyAsyncSequence(values)
	}

	func eraseToAnySequence<Element>() -> AnyThrowingAsyncSequence<Element> where Output == Element {
		AnyThrowingAsyncSequence(values)
	}
}


extension Shape where Self == Rectangle {
	static var rectangle: Self { Self() }
}


func tryOrAssign<T>(
	_ errorBinding: Binding<Error?>,
	doClosure: () throws -> T?
) -> T? {
	do {
		return try doClosure()
	} catch {
		errorBinding.wrappedValue = error
		return nil
	}
}

func tryOrAssign<T>(
	_ errorBinding: Binding<Error?>,
	doClosure: () async throws -> T?
) async -> T? {
	do {
		return try await doClosure()
	} catch {
		errorBinding.wrappedValue = error
		return nil
	}
}

extension View {
	@MainActor // Temporary sendable warning workaround.
	func taskOrAssign(
		_ errorBinding: Binding<Error?>,
		priority: TaskPriority = .userInitiated,
		_ action: @escaping @Sendable () async throws -> Void
	) -> some View {
		task(priority: priority) { @MainActor in
//			await tryOrAssign(errorBinding) {
//				try await action()
//			}

			// Temporary sendable warning workaround.
			do {
				try await action()
			} catch {
				errorBinding.wrappedValue = error
			}
		}
	}
}


extension Button<Label<Text, Image>> {
	init(
		_ title: String,
		systemImage: String,
		role: ButtonRole? = nil,
		action: @escaping () -> Void
	) {
		self.init(
			role: role,
			action: action
		) {
			Label(title, systemImage: systemImage)
		}
	}
}


extension Text {
	/**
	By default, `Text` only accepts Markdown when using a string literal or explicitly passing a `LocalizedStringKey`. That's a bit too magic and I prefer an explicit initializer.
	*/
	init(markdown: String) {
		self.init(LocalizedStringKey(markdown))
	}
}


extension View {
	/**
	Fills the frame.
	*/
	func fillFrame(
		_ axis: Axis.Set = [.horizontal, .vertical],
		alignment: Alignment = .center
	) -> some View {
		frame(
			maxWidth: axis.contains(.horizontal) ? .infinity : nil,
			maxHeight: axis.contains(.vertical) ? .infinity : nil,
			alignment: alignment
		)
	}
}


// We cannot use `loadTransferable(type: Image.self)`: https://developer.apple.com/forums/thread/709764
extension PhotosPickerItem {
	/**
	Loads an image from the item.
	*/
	func loadImage(maxPixelSize: Int) async throws -> UIImage {
		guard let data = try await loadTransferable(type: Data.self) else {
			throw "Failed to load image.".toError
		}

		return try UIImage.from(data, maxPixelSize: maxPixelSize)
	}
}


extension NSItemProvider {
	func loadTransferable<T: Transferable>(type transferableType: T.Type) async throws -> T {
		try await withCheckedThrowingContinuation { continuation in
			_ = loadTransferable(type: transferableType) {
				continuation.resume(with: $0)
			}
		}
	}
}


extension NSItemProvider {
	/**
	Loads an image from the item.
	*/
	func loadImage(maxPixelSize: Int) async throws -> UIImage {
		let data = try await loadTransferable(type: Data.self)
		return try UIImage.from(data, maxPixelSize: maxPixelSize)
	}
}


extension PrimitiveButtonStyle where Self == FormLinkButtonStyle {
	/**
	Makes buttons have a link icon after them. Should be used in a `Form`.

	- Note: This only does something on iOS.
	- Note: This does not override the existing button style.
	*/
	static var formLink: Self { .init() }
}

struct FormLinkButtonStyle: PrimitiveButtonStyle {
	@Environment(\.isEnabled) private var isEnabled

	func makeBody(configuration: Configuration) -> some View {
		#if os(iOS)
		LabeledContent {
			Image(systemName: "arrow.up.right")
				.imageScale(.small)
				.fontWeight(.semibold)
				.foregroundStyle(.tertiary)
				.opacity(isEnabled ? 1 : 0.5)
		} label: {
			Button(configuration)
		}
		#else
		Button(configuration)
		#endif
	}
}
