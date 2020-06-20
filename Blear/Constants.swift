import Foundation

let IS_IPAD = UIDevice.current.userInterfaceIdiom == .pad
let IS_IPHONE = UIDevice.current.userInterfaceIdiom == .phone
let SCREEN_WIDTH = UIScreen.main.bounds.size.width
let SCREEN_HEIGHT = UIScreen.main.bounds.size.height
let IS_LARGE_SCREEN = IS_IPHONE && max(SCREEN_WIDTH, SCREEN_HEIGHT) >= 736.0

enum Constants {
	static let initialBlurAmount = 50.0
}
