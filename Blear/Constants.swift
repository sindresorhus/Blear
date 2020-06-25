import Foundation

enum Constants {
	static let initialBlurAmount = 50.0
}

enum DeviceInfo {
	static let isPhone = UIDevice.current.userInterfaceIdiom == .phone
	static let isPad = UIDevice.current.userInterfaceIdiom == .pad
}
