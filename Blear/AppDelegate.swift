import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?

	func applicationDidFinishLaunching(_ application: UIApplication) {
		window = UIWindow(frame: UIScreen.main.bounds)
		window?.rootViewController = ViewController()
		window?.makeKeyAndVisible()

		if UserDefaults.standard.isFirstLaunch {
			let alert = UIAlertController(
				title: "Tip",
				message: "Shake the device to get a random image.",
				preferredStyle: .alert
			)
			alert.addAction(UIAlertAction(title: "OK", style: .default))
			window?.rootViewController?.present(alert, animated: true)
		}
	}
}
