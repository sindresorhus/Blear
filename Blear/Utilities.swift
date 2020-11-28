import SwiftUI
import Combine
import MobileCoreServices
import PhotosUI
import AppCenter
import AppCenterCrashes


func initAppCenter() {
	AppCenter.start(
		withAppSecret: "266f557d-902a-44d4-8d0e-65b3fd19ae16",
		services: [
			Crashes.self
		]
	)
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
				offset = Int.random(in: 0..<count)
			} while offset == previousNumber
			previousNumber = offset

			return self[index(startIndex, offsetBy: offset)]
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

	/// Resize the image so the longest side is equal or less than `longestSide`.
	func resized(longestSide: Double) -> UIImage {
		let longestSide = CGFloat(longestSide)
		let width = size.width
		let height = size.height
		let ratio = width / height

		let newSize = width > height
			? CGSize(width: longestSide, height: longestSide / ratio)
			: CGSize(width: longestSide * ratio, height: longestSide)

		return resized(to: newSize)
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
			drawHierarchy(in: bounds, afterScreenUpdates: true)
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
		UIGraphicsImageRenderer(size: bounds.size).image { [self] _ in
			let newBounds = bounds.offsetBy(dx: -contentOffset.x, dy: -contentOffset.y)
			drawHierarchy(in: newBounds, afterScreenUpdates: true)
		}
	}
}


extension CGSize {
	func aspectFit(to size: Self) -> Self {
		let ratio = max(size.width / width, size.height / height)
		return Self(width: width * CGFloat(ratio), height: height * CGFloat(ratio))
	}
}


extension Bundle {
	/// Returns the current app's bundle whether it's called from the app or an app extension.
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
	static let id = Bundle.main.bundleIdentifier!
	static let name = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String
	static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
	static let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
	static let versionWithBuild = "\(version) (\(build))"
	static let rootName = Bundle.app.object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String

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


extension SSApp {
	/// - Note: Call this lazily only when actually needed as otherwise it won't get the live info.
	static func appFeedbackUrl() -> URL {
		let metadata =
			"""
			\(SSApp.name) \(SSApp.versionWithBuild)
			Bundle Identifier: \(SSApp.id)
			OS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
			Model: \(Device.modelIdentifier)
			"""

		let info: [String: String] = [
			"product": SSApp.name,
			"metadata": metadata
		]

		return URL(string: "https://sindresorhus.com/feedback/", query: info)!
	}
}

// Conforms to the informal `NSErrorRecoveryAttempting` protocol.
final class ErrorRecoveryAttempter: NSObject {
	struct Option {
		let title: String

		/// Return a boolean for whether the recovery was successful.
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

extension NSError {
	// TODO: I should probably include failure reason too. https://stackoverflow.com/questions/37160801/setting-nslocalizedrecoveryoptionserrorkey-as-nserror-userinfo-doesnt-provide-a https://github.com/CharlesJS/CSErrors/blob/1847537713809cd6176a34b2912756544ad9139e/Sources/CSErrors/Utils.swift
	/**
	Use this for generic app errors.

	- Note: Prefer using a specific enum-type error whenever possible.

	- Parameter description: The description of the error. This is shown as the first line in error dialogs. Corresponds to `NSLocalizedDescriptionKey` in the `userInfo` dictionary.
	- Parameter recoverySuggestion: Explain how the user how they can recover from the error. For example, "Try choosing a different directory". This is usually shown as the second line in error dialogs. Corresponds to `NSLocalizedRecoverySuggestionErrorKey` in the `userInfo` dictionary.
	- Parameter recoveryOptions: Add recovery options to the error. These will be presented as buttons in the error dialog. You do not need to add a `Cancel` option.
	- Parameter underlyingError: The original error if this error wrap another one. Corresponds to `NSUnderlyingErrorKey` in the `userInfo` dictionary.
	- Parameter userInfo: Metadata to add to the error. Can be a custom key or any of the `NSLocalizedDescriptionKey` keys except `NSLocalizedDescriptionKey` and `NSLocalizedRecoverySuggestionErrorKey`.
	- Parameter domainPostfix: String to append to the `domain` to make it easier to identify the error. The domain is the app's bundle identifier.
	*/
	static func appError(
		_ description: String,
		recoverySuggestion: String? = nil,
		recoveryOptions: [ErrorRecoveryAttempter.Option] = [],
		userInfo: [String: Any] = [:],
		domainPostfix: String? = nil,
		underlyingError: Error? = nil
	) -> Self {
		var userInfo = userInfo
		userInfo[NSLocalizedDescriptionKey] = description

		if let recoverySuggestion = recoverySuggestion {
			userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion
		}

		if !recoveryOptions.isEmpty {
			userInfo[NSLocalizedRecoveryOptionsErrorKey] = recoveryOptions.map(\.title)
			userInfo[NSRecoveryAttempterErrorKey] = ErrorRecoveryAttempter(recoveryOptions: recoveryOptions)
		}

		if let underlyingError = underlyingError {
			userInfo[NSUnderlyingErrorKey] = underlyingError
		}

		return .init(
			domain: domainPostfix.map { "\(SSApp.id) - \($0)" } ?? SSApp.id,
			code: 1, // This is what Swift errors end up as.
			userInfo: userInfo
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
		_ = ImageSaver(image: self) { error in
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

				let error = NSError.appError(
					"“\(SSApp.rootName)” does not have access to add photos to your photo library.",
					recoverySuggestion: recoverySuggestion,
					recoveryOptions: recoveryOptions
				)

				completion(error)
				return
			}

			completion(error)
		}
	}
}


extension View {
	/// This allows multiple alerts on a single view, which `.alert()` doesn't.
	func alert2(
		isPresented: Binding<Bool>,
		content: @escaping () -> Alert
	) -> some View {
		background(
			EmptyView().alert(
				isPresented: isPresented,
				content: content
			)
		)
	}
}


/// Let the user pick photos and videos from their library.
struct PhotoVideoPicker: UIViewControllerRepresentable {
	final class Coordinator: PHPickerViewControllerDelegate {
		private let parent: PhotoVideoPicker

		init(_ parent: PhotoVideoPicker) {
			self.parent = parent
		}

		func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
			// This is important as otherwise it causes weird problems like `@State` not updating. (iOS 14)
			picker.dismiss(animated: true)

			parent.presentationMode.wrappedValue.dismiss()

			// Give the sheet time to close.
			DispatchQueue.main.async { [self] in
				parent.onPick(results)
			}
		}
	}

	@Environment(\.presentationMode) private var presentationMode

	var filter: PHPickerFilter
	var selectionLimit = 1
	let onPick: ([PHPickerResult]) -> Void

	func makeCoordinator() -> Coordinator { .init(self) }

	func makeUIViewController(context: Context) -> PHPickerViewController {
		var configuration = PHPickerConfiguration()
		configuration.filter = filter
		configuration.selectionLimit = selectionLimit

		let controller = PHPickerViewController(configuration: configuration)
		controller.delegate = context.coordinator

		return controller
	}

	func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
}


/// Let the user pick a single photo from their library.
struct SinglePhotoPicker: View {
	var onPick: (UIImage?) -> Void

	var body: some View {
		PhotoVideoPicker(filter: .images) { results in
			guard
				let itemProvider = results.first?.itemProvider,
				itemProvider.canLoadObject(ofClass: UIImage.self)
			else {
				onPick(nil)
				return
			}

			itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
				guard let image = image as? UIImage else {
					onPick(nil)
					return
				}

				onPick(image)
			}
		}
	}
}


struct SinglePhotoPickerButton: View {
	@State private var isShowingPhotoPicker = false

	var iconName = "photo"
	var onImage: (UIImage) -> Void

	var body: some View {
		Button {
			isShowingPhotoPicker = true
		} label: {
			Image(systemName: iconName)
		}
			.sheet(isPresented: $isShowingPhotoPicker) {
				SinglePhotoPicker {
					guard let image = $0 else {
						return
					}

					onImage(image)
				}
					.ignoresSafeArea()
			}
	}
}


extension UIDevice {
	fileprivate static let _didShakePublisher = PassthroughSubject<Void, Never>()

	var didShakePublisher: AnyPublisher<Void, Never> {
		Self._didShakePublisher.eraseToAnyPublisher()
	}
}

extension UIWindow {
	override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
		if motion == .motionShake {
			UIDevice._didShakePublisher.send()
		}

		super.motionEnded(motion, with: event)
	}
}

private struct DeviceShakeViewModifier: ViewModifier {
	let action: (() -> Void)

	func body(content: Content) -> some View {
		content
			.onAppear() // Shake doesn't work without this. (iOS 14.5)
			.onReceive(UIDevice.current.didShakePublisher) { _ in
				action()
			}
	}
}

extension View {
	/// Perform sn ction when the device is shaked.
	func onDeviceShake(perform action: @escaping (() -> Void)) -> some View {
		modifier(DeviceShakeViewModifier(action: action))
	}
}


extension CGSize {
	var longestSide: CGFloat { max(width, height) }
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
	func `if`<Content: View>(
		_ condition: @autoclosure () -> Bool,
		modify: (Self) -> Content
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
		Link("Rate on the App Store", destination: URL(string: "itms-apps://apps.apple.com/app/id\(appStoreID)?action=write-review")!)
	}
}


typealias QueryDictionary = [String: String]

extension CharacterSet {
	/// Characters allowed to be unescaped in an URL
	/// https://tools.ietf.org/html/rfc3986#section-2.3
	static let urlUnreservedRFC3986 = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
}

private func escapeQueryComponent(_ query: String) -> String {
	query.addingPercentEncoding(withAllowedCharacters: .urlUnreservedRFC3986)!
}

extension Dictionary where Key == String {
	/// This correctly escapes items. See `escapeQueryComponent`.
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
	/// This correctly escapes items. See `escapeQueryComponent`.
	init?(string: String, query: QueryDictionary) {
		self.init(string: string)
		self.queryDictionary = query
	}

	/// This correctly escapes items. See `escapeQueryComponent`.
	var queryDictionary: QueryDictionary {
		get {
			queryItems?.toDictionary { ($0.name, $0.value) }.compactValues() ?? [:]
		}
		set {
			/// Using `percentEncodedQueryItems` instead of `queryItems` since the query items are already custom-escaped. See `escapeQueryComponent`.
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
		// TODO: Make this `compactMapValues(\.self)` when https://bugs.swift.org/browse/SR-12897 is fixed.
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
	private final class ValueBox: ObservableObject {
		let objectWillChange = Empty<Never, Never>(completeImmediately: false)
		var value: Value

		init(_ value: Value) {
			self.value = value
		}
	}

	@StateObject private var valueBox: ValueBox

	var wrappedValue: Value {
		get { valueBox.value }
		nonmutating set {
			valueBox.value = newValue
		}
	}

	init(wrappedValue value: @autoclosure @escaping () -> Value) {
		self._valueBox = StateObject(wrappedValue: .init(value()))
	}
}


private struct AccessNativeView: UIViewRepresentable {
	var callback: (UIView?) -> Void

	func makeUIView(context: Context) -> UIView { .init() }

	func updateUIView(_ uiView: UIView, context: Context) {
		callback(uiView)
	}
}

extension View {
	/// Access the native view hierarchy from SwiftUI.
	/// - Important: Don't assume the view is in the view hierarchy on the first callback invocation.
	func accessNativeView(_ callback: @escaping (UIView?) -> Void) -> some View {
		background(AccessNativeView(callback: callback))
	}

	/// Access the window the view is contained in if any.
	func accessNativeWindow(_ callback: @escaping (UIWindow?) -> Void) -> some View {
		accessNativeView { uiView in
			guard let window = uiView?.window else {
				return
			}

			callback(window)
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


extension NSError: Identifiable {
	public var id: String {
		"\(code)" + domain + localizedDescription + (localizedRecoverySuggestion ?? "")
	}
}


extension View {
	/**
	Present an error as an alert.

	If you set it multiple times, the alert will only change if the error is different.

	```
	struct ContentView: View {
		@State private var convertError: Error?

		var body: some View {
			VStack {
				Button("Convert") {
					do {
						try convert()
					} catch {
						convertError = error
					}
				}
			}
				.alert(error: $convertError)
		}
	}
	```
	*/
	func alert(error: Binding<Error?>) -> some View {
		background(
			EmptyView().alert(item: error.map(
				get: { $0 as NSError? },
				set: { $0 as Error? }
			)) { nsError in
				if
					let options = nsError.localizedRecoveryOptions,
					let firstOption = options.first,
					let recoveryAttempter = nsError.recoveryAttempter
				{
					// There could be multiple recovery options, but we can only support one as `Alert` in SwiftUI can only add one extra button.
					return Alert(
						title: Text(nsError.localizedDescription),
						message: nsError.localizedRecoverySuggestion.map { Text($0) },
						primaryButton: .default(Text(firstOption)) {
							_ = (recoveryAttempter as AnyObject).attemptRecovery(fromError: nsError, optionIndex: 0)
						},
						secondaryButton: .cancel()
					)
				}

				return Alert(
					title: Text(nsError.localizedDescription),
					// Note that we don't also use `localizedFailureReason` as the `NSError#localizedDescription` docs says it's already being included there.
					message: nsError.localizedRecoverySuggestion.map { Text($0) }
				)
			}
		)
	}
}


extension Sequence where Element: Sequence {
	func flatten() -> [Element.Element] {
		// TODO: Make this `flatMap(\.self)` when https://bugs.swift.org/browse/SR-12897 is fixed.
		flatMap { $0 }
	}
}


extension NSExtensionContext {
	func cancel() {
		completeRequest(returningItems: nil, completionHandler: nil)
	}
}


extension Collection {
	/// Returns the element at the specified index if it is within bounds, otherwise nil.
	subscript(safe index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
}


@available(iOSApplicationExtension, unavailable)
extension SSApp {
	private static var settingsUrl = URL(string: UIApplication.openSettingsURLString)!

	/// Whether the settings view in Settings for the current app exists and can be opened.
	static var canOpenSettings = UIApplication.shared.canOpenURL(settingsUrl)

	/// Open the settings view in Settings for the current app.
	/// - Important: Ensure you use `.canOpenSettings`.
	static func openSettings() {
		UIApplication.shared.open(settingsUrl) { _ in }
	}
}


extension UIView {
	/// The highest ancestor superview.
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

	/// The `.extensionContext` of an app extension view controller.
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
	func hasItemConformingTo(_ type: UTType) -> Bool {
		hasItemConformingToTypeIdentifier(type.identifier)
	}

	func loadItem(
		forType type: UTType,
		options: [AnyHashable: Any]? = nil, // swiftlint:disable:this discouraged_optional_collection
		completionHandler: NSItemProvider.CompletionHandler? = nil
	) {
		loadItem(
			forTypeIdentifier: type.identifier,
			options: options,
			completionHandler: completionHandler
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

	/// Run a closure only once ever, even between relaunches of the app.
	static func runOnce(identifier: String, _ execute: () -> Void) {
		guard runOnceShouldRun(identifier: identifier) else {
			return
		}

		execute()
	}
}
