import UIKit


enum Constants {
	static let initialBlurAmount = 50.0
	static let buttonShadowRadius = 2.0
	static let maxImageSize = UIScreen.main.bounds.size.longestSide / 2
}


enum DeviceInfo {
	static let isPhone = UIDevice.current.userInterfaceIdiom == .phone
	static let isPad = UIDevice.current.userInterfaceIdiom == .pad
}
