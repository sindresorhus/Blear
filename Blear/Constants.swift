import UIKit


enum Constants {
	static let initialBlurAmount = 50.0
	static let buttonShadowRadius: CGFloat = 2
}


enum DeviceInfo {
	static let isPhone = UIDevice.current.userInterfaceIdiom == .phone
	static let isPad = UIDevice.current.userInterfaceIdiom == .pad
}


enum Utilities {
	static func resizeImage(_ image: UIImage) -> UIImage {
		image.resized(longestSide: Double(UIScreen.main.bounds.size.longestSide) / 2)
	}
}
