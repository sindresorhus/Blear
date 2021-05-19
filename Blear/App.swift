import SwiftUI

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
