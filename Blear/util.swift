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


// TODO: Move it to a SPM module
// TODO: Test without permissions
// TODO: Add this as note to module readme:
// > Your app’s Info.plist file must provide a value for the NSPhotoLibraryUsageDescription key that explains to the user why your app is requesting Photos access. Apps linked on or after iOS 10.0 will crash if this key is not present.
// Name: `PHPhotoLibraryExtras` or `PhotosExtras`. Probably the latter.
extension PHPhotoLibrary {
	static func getAlbum(withTitle title: String) -> PHAssetCollection? {
		let fetchOptions = PHFetchOptions()
		fetchOptions.predicate = NSPredicate(format: "title = %@", title)
		let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
		return albums.firstObject
	}

	static func createAlbum(withTitle title: String, completionHandler: @escaping (PHAssetCollection?, Error?) -> Void) {
		if let album = getAlbum(withTitle: title) {
			DispatchQueue.main.async {
				completionHandler(album, nil)
			}
			return
		}

		var localIdentifier: String!

		shared().performChanges({
			localIdentifier = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title).placeholderForCreatedAssetCollection.localIdentifier
		}, completionHandler: { success, error in
			// The `completionHandler` here could be executed on any queue, so we ensure
			// the user's handler is always executed on the main queue, for convenience
			DispatchQueue.main.async {
				guard success else {
					completionHandler(nil, error)
					return
				}

				let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localIdentifier], options: nil)
				completionHandler(collections.firstObject, nil)
			}
		})
	}

	static func save(image: UIImage, toAlbum album: String, completionHandler: @escaping (String?, Error?) -> Void) {
		createAlbum(withTitle: album) { album, error in
			guard let album = album else {
				completionHandler(nil, error)
				return
			}

			var localIdentifier: String?

			self.shared().performChanges({
				let placeholder = PHAssetChangeRequest.creationRequestForAsset(from: image).placeholderForCreatedAsset
				PHAssetCollectionChangeRequest(for: album)?.addAssets([placeholder as Any] as NSArray)
				localIdentifier = placeholder?.localIdentifier
			}, completionHandler: { success, error in
				DispatchQueue.main.async {
					guard success else {
						completionHandler(nil, error)
						return
					}

					completionHandler(localIdentifier, nil)
				}
			})
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
		return UIEdgeInsetsInsetRect(rect, self)
	}
}
