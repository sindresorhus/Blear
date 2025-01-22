import SwiftUI

enum Constants {
	static let initialBlurAmount = 50.0
	static let buttonShadowRadius = 2.0

	@MainActor
	static let maxImagePixelSize = Int(UIScreen.main.bounds.size.longestSide / 2)
}

@MainActor
enum DeviceInfo {
	static let isPhone = UIDevice.current.userInterfaceIdiom == .phone
	static let isPad = UIDevice.current.userInterfaceIdiom == .pad
}

extension UIView {
	func blear_saveToPhotoLibrary(isSaving: Binding<Bool>) async throws {
		isSaving.wrappedValue = true

		defer {
			isSaving.wrappedValue = false
		}

		try? await Task.sleep(for: .seconds(0.2))

		try await toImage().saveToPhotosLibrary()
	}
}
