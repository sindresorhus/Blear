import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
	let window = UIWindow(frame: UIScreen.main.bounds)

	func applicationDidFinishLaunching(_ application: UIApplication) {
		window.rootViewController = ViewController()
		window.makeKeyAndVisible()

		if UserDefaults.standard.isFirstLaunch {
			let alert = UIAlertController(
				title: "Tip",
				message: "Shake the device to get a random image.",
				preferredStyle: .alert
			)
			alert.addAction(UIAlertAction(title: "OK", style: .default))
			window.rootViewController?.present(alert, animated: true)
		}
	}
}
