import SwiftUI

final class ActionViewController: UIViewController {
	override var prefersStatusBarHidden: Bool { true }

	override func viewDidLoad() {
		super.viewDidLoad()

		initAppCenter()

		let contentView = ContentView()
			.environment(\.extensionContext, extensionContext)

		view = UIHostingView(rootView: contentView)
		view.isOpaque = true
		view.backgroundColor = .white
	}
}
