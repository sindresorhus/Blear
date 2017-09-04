import UIKit
import QuartzCore

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
	convenience init?(url: URL) {
		self.init(contentsOfFile: url.path)
	}

	convenience init(view: UIView) {
		UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0)
		view.layer.render(in: UIGraphicsGetCurrentContext()!)
		let image = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		self.init(cgImage: image.cgImage!)
	}
}

struct Util {
	static func delay(seconds: Double, execute: @escaping () -> Void) {
		DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: execute)
	}
}
