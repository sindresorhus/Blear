import UIKit
import AppCenter
import AppCenterCrashes

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?

	func applicationDidFinishLaunching(_ application: UIApplication) {
		MSAppCenter.start(
			"266f557d-902a-44d4-8d0e-65b3fd19ae16",
			withServices: [
				MSCrashes.self
			]
		)

		window = UIWindow(frame: UIScreen.main.bounds)
		window?.rootViewController = ViewController()
		window?.makeKeyAndVisible()
	}
}
