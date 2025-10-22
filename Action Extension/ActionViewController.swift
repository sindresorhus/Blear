import SwiftUI

final class ActionViewController: UIViewController {
	override var prefersStatusBarHidden: Bool { true }

	override func viewDidLoad() {
		super.viewDidLoad()

		let contentView = MainScreen()
			.environment(\.extensionContext, extensionContext)

		view = UIHostingView(rootView: contentView)
		view.isOpaque = true
		view.backgroundColor = .white
	}
}
