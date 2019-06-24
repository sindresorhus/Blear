import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
	let window = UIWindow(frame: UIScreen.main.bounds)

	func applicationDidFinishLaunching(_ application: UIApplication) {
		window.rootViewController = ViewController()
		window.makeKeyAndVisible()
	}
}
