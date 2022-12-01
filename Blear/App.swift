import SwiftUI

/**
TODO:
- Use vector icon for the action extension icon.
- Set `URL.itemCreator` on the exported file.
- Unsplash support: https://github.com/unsplash/unsplash-photopicker-ios
- Add tip about the action extension: For example, download images from the Unsplash app and bring into the app.
- Add ability to zoom in.
*/

@main
struct AppMain: App {
	@StateObject private var appState = AppState()

	init() {
		initSentry()
	}

	var body: some Scene {
		WindowGroup {
			MainScreen()
				.environmentObject(appState)
		}
	}
}
