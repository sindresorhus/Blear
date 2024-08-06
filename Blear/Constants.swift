import UIKit


enum Constants {
	static let initialBlurAmount = 50.0
	static let buttonShadowRadius = 2.0

	@MainActor
	static let maxImagePixelSize = Int(UIScreen.main.bounds.size.longestSide / 2)
}

@MainActor
enum DeviceInfo {
	static let isPhone = UIDevice.current.userInterfaceIdiom == .phone
	static let isPad = UIDevice.current.userInterfaceIdiom == .pad
}
