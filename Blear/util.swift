import UIKit
import QuartzCore
import Photos

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


enum Result<Value> {
	case success(Value)
	case failure(Error)
}

// TODO: Move it to a SPM module
// TODO: Add this as note to module readme:
// > Your app’s Info.plist file must provide a value for the NSPhotoLibraryUsageDescription key that explains to the user why your app is requesting Photos access. Apps linked on or after iOS 10.0 will crash if this key is not present.
// Name: `PHPhotoLibraryExtras` or `PhotosExtras`. Probably the latter.
// Document that the handler is guaranteed to be executed in the main thread.
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

	static func runOrFail(completionHandler: @escaping (Result<Void>) -> Void) {
		PHPhotoLibrary.requestAuthorization { status in
			DispatchQueue.main.async {
				switch status {
				case .authorized:
					completionHandler(Result.success(()))
				default:
					completionHandler(Result.failure(Error.noAccess))
				}
			}
		}
	}

	static func getAlbum(withTitle title: String, completionHandler: @escaping (Result<PHAssetCollection?>) -> Void) {
		runOrFail { result in
			switch result {
			case .failure(let error):
				completionHandler(.failure(error))
			case .success:
				let fetchOptions = PHFetchOptions()
				fetchOptions.predicate = NSPredicate(format: "title = %@", title)
				let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
				completionHandler(.success(albums.firstObject))
			}
		}
	}

	static func createAlbum(withTitle title: String, completionHandler: @escaping (Result<PHAssetCollection>) -> Void) {
		getAlbum(withTitle: title) { result in
			switch result {
			case .failure(let error):
				completionHandler(.failure(error))
			case .success(let value):
				guard let album = value else {
					var localIdentifier: String!

					shared().performChanges({
						localIdentifier = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title).placeholderForCreatedAssetCollection.localIdentifier
					}, completionHandler: { success, error in
						// The `completionHandler` here could be executed on any queue, so we ensure
						// the user's handler is always executed on the main queue, for convenience
						DispatchQueue.main.async {
							guard success else {
								completionHandler(.failure(error!))
								return
							}

							let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localIdentifier], options: nil)

							guard let album = collections.firstObject else {
								fatalError("Album does not exist even though we just successfully created it. This should not happen!")
							}

							completionHandler(.success(album))
						}
					})
					return
				}

				completionHandler(.success(album))
			}
		}
	}

	static func save(image: UIImage, toAlbum album: String, completionHandler: @escaping (Result<String>) -> Void) {
		createAlbum(withTitle: album) { result in
			switch result {
			case .failure(let error):
				completionHandler(.failure(error))
			case .success(let album):
				var localIdentifier: String!

				self.shared().performChanges({
					let placeholder = PHAssetChangeRequest.creationRequestForAsset(from: image).placeholderForCreatedAsset
					PHAssetCollectionChangeRequest(for: album)?.addAssets([placeholder as Any] as NSArray)
					localIdentifier = placeholder?.localIdentifier
				}, completionHandler: { success, error in
					DispatchQueue.main.async {
						guard success else {
							completionHandler(.failure(error!))
							return
						}

						completionHandler(.success(localIdentifier))
					}
				})
			}
		}
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

extension Collection where Index == Int {
	func uniqueRandomElement() -> AnyIterator<Element> {
		var previousNumber: Int?

		return AnyIterator {
			var offset: Int
			repeat {
				offset = Int(arc4random_uniform(UInt32(self.count)))
			} while offset == previousNumber

			previousNumber = offset

			return self[offset]
		}
	}
}

extension UserDefaults {
	var isFirstLaunch: Bool {
		let key = "__hasLaunched__"

		if bool(forKey: key) {
			return false
		} else {
			set(true, forKey: key)
			return true
		}
	}
}

extension UIImage {
	/// Initialize with a URL
	/// AppKit.NSImage polyfill
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
}

extension UIView {
	/// The most efficient solution
	func toImage() -> UIImage {
		return UIGraphicsImageRenderer(size: bounds.size).image { _ in
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

	func inset(rect: CGRect) -> CGRect {
		return rect.inset(by: self)
	}
}

extension UIViewController {
	var window: UIWindow {
		return UIApplication.shared.windows.first!
	}
}
