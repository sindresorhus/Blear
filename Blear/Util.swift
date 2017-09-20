import UIKit
import QuartzCore

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

// TODO: Drop the `where Index == Int` part in Swift 4
extension Collection where Index == Int {
	func uniqueRandomElement() -> AnyIterator<Iterator.Element> {
		var previousNumber: Int?

		return AnyIterator {
			var offset: Int
			repeat {
				offset = numericCast(arc4random_uniform(numericCast(self.count)))
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
			self.drawHierarchy(in: CGRect(origin: .zero, size: bounds.size), afterScreenUpdates: true)
		}
	}
}

struct Util {
	static func delay(seconds: Double, execute: @escaping () -> Void) {
		DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: execute)
	}
}
