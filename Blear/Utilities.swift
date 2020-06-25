import UIKit
import QuartzCore
import Photos
import Combine

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


func delay(seconds: TimeInterval, closure: @escaping () -> Void) {
	DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: closure)
}


// TODO: Move it to a SPM module
// TODO: Add this as note to module readme:
// > Your app’s Info.plist file must provide a value for the NSPhotoLibraryUsageDescription key that explains to the user why your app is requesting Photos access. Apps linked on or after iOS 10.0 will crash if this key is not present.
// Name: `PHPhotoLibraryExtras` or `PhotosExtras`. Probably the latter.
extension PHPhotoLibrary {
	enum Error: Swift.Error, LocalizedError {
		case noAccess

		var errorDescription: String? {
			switch self {
			case .noAccess:
				return "Could not access the photo library. Please allow access in Settings."
			}
		}
	}

	static func requestAuthorization() -> Future<PHAuthorizationStatus, Never> {
		Future { resolve in
			requestAuthorization { status in
				resolve(.success(status))
			}
		}
	}

	/// Checks authorization and fails with an error if not.
	static func checkAuthorization() -> AnyPublisher<Void, Swift.Error> {
		requestAuthorization()
			.tryMap {
				switch $0 {
				case .authorized:
					return
				default:
					throw Error.noAccess
				}
			}
			.eraseToAnyPublisher()
	}

	static func getAlbum(
		withTitle title: String
	) -> AnyPublisher<PHAssetCollection?, Swift.Error> {
		checkAuthorization()
			.map { _ in
				let fetchOptions = PHFetchOptions()
				fetchOptions.predicate = NSPredicate(format: "title = %@", title)

				let albums = PHAssetCollection.fetchAssetCollections(
					with: .album,
					subtype: .albumRegular,
					options: fetchOptions
				)

				return albums.firstObject
			}
			.eraseToAnyPublisher()
	}

	private static func performChanges<T>(_ changeBlock: @escaping () -> T) -> Future<T, Swift.Error> {
		Future { resolve in
			var returnValue: T!

			shared().performChanges({
				returnValue = changeBlock()
			}) { success, error in
				guard success else {
					resolve(.failure(error!))
					return
				}

				resolve(.success(returnValue))
			}
		}
	}

	static func createAlbum(
		withTitle title: String
	) -> AnyPublisher<PHAssetCollection, Swift.Error> {
		getAlbum(withTitle: title)
			.flatMap { album -> AnyPublisher<PHAssetCollection, Swift.Error> in
				if let album = album {
					return Just(album)
						.setFailureType(to: Swift.Error.self)
						.eraseToAnyPublisher()
				}

				return performChanges {
					PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title).placeholderForCreatedAssetCollection.localIdentifier
				}
					.tryMap { localIdentifier in
						let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localIdentifier], options: nil)

						guard let album = collections.firstObject else {
							// TODO: Look into why this happens on iOS 14.
							throw NSError.appError("Album does not exist even though we just successfully created it. This should not happen!")
						}

						return album
					}
					.eraseToAnyPublisher()
			}
			.eraseToAnyPublisher()
	}

	/// - Returns: The identifier for the album.
	static func save(
		image: UIImage,
		toAlbum album: String
	) -> AnyPublisher<String, Swift.Error> {
		createAlbum(withTitle: album)
			.flatMap { album -> AnyPublisher<String, Swift.Error> in
				performChanges {
					let placeholder = PHAssetChangeRequest.creationRequestForAsset(from: image).placeholderForCreatedAsset
					PHAssetCollectionChangeRequest(for: album)?.addAssets([placeholder as Any] as NSArray)
					return placeholder!.localIdentifier
				}
					.eraseToAnyPublisher()
			}
			.eraseToAnyPublisher()
	}
}


extension UIBarButtonItem {
	/**
	```
	toolbar.items = [
		someButton,
		.flexibleSpace
	]
	```
	*/
	static let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
	static let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)

	convenience init(image: UIImage?, target: Any?, action: Selector?, width: CGFloat = 0) {
		self.init(image: image, style: .plain, target: target, action: action)
		self.width = width
	}
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


extension UIViewController {
	var window: UIWindow { UIApplication.shared.windows.first! }
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
