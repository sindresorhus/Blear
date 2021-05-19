import SwiftUI

final class ActionViewController: UIViewController {
	override var prefersStatusBarHidden: Bool { true }

	override func viewDidLoad() {
		super.viewDidLoad()

		initSentry()

		let contentView = MainScreen()
			.environment(\.extensionContext, extensionContext)

		view = UIHostingView(rootView: contentView)
		view.isOpaque = true
		view.backgroundColor = .white
	}
}
