import SwiftUI
import UniformTypeIdentifiers

struct MainScreen: View {
	@Environment(\.extensionContext) private var extensionContext: NSExtensionContext!
	@State private var image: UIImage?
	@State private var blurAmount = Constants.initialBlurAmount
	@State private var isSaving = false
	@State private var error: Error?
	@State private var isWallpaperTipPresented = false
	@ViewStorage private var hostingView: UIView?

	private var controls: some View {
		VStack {
			HStack {
				Group {
					// TODO: Use `CloseOrClearButton`.
					Button {
						extensionContext.cancel()
					} label: {
						Image(systemName: "xmark.circle")
							.imageScale(.large)
							// Increase tap area
							.padding(8)
							.contentShape(.rectangle)
					}
						.padding(.horizontal, -8)
						// TOOD: use label instead
						.help("Cancel")
					Spacer()
					Button {
						Task {
							await tryOrAssign($error) {
								try await saveImage()
							}
						}
					} label: {
						Image(systemName: "square.and.arrow.down")
							.imageScale(.large)
							// Increase tap area
							.padding(8)
							.contentShape(.rectangle)
					}
						.padding(.horizontal, -8)
						// TOOD: Use label instead
						.help("Save image")
				}
					.shadow(radius: Constants.buttonShadowRadius)
					.tint(.white)
					.padding(.horizontal)
			}
			Spacer()
			Slider(value: $blurAmount, in: 10...100)
				.padding(.horizontal, DeviceInfo.isPad ? 60 : 30)
				.frame(maxWidth: 500)
				.tint(.white)
		}
			.padding()
			.padding(.bottom, 40)
			.padding(.vertical)
	}

    var body: some View {
		ZStack {
			if let image {
				EditorScreen(
					image: .constant(image),
					blurAmount: $blurAmount
				)
			}
			if !isSaving {
				controls
			}
		}
			.taskOrAssign($error) {
				image = try await getImage()
			}
			.alert2(
				"How to Change Wallpaper",
				message: "Go to the most recent photo in the photo library, tap the action button at the \(DeviceInfo.isPad ? "top right" : "bottom left"), and choose “Use as Wallpaper”.",
				isPresented: $isWallpaperTipPresented
			)
			.onChange(of: isWallpaperTipPresented) {
				guard !$0 else {
					return
				}

				extensionContext.cancel()
			}
			.alert(error: $error)
			.accessNativeView {
				hostingView = $0
			}
    }

	private func getImage() async throws -> UIImage {
		guard
			let itemProvider = (extensionContext.attachments.first { $0.hasItemConforming(to: .image) })
		else {
			throw NSError.appError("Did not receive any compatible image.")
		}

		// TODO: Force the following to execute in a background thread.
		do {
			return try await itemProvider.getImage(maxPixelSize: Constants.maxImagePixelSize)
		} catch {
			SSApp.reportError(
				error,
				userInfo: [
					"registeredTypeIdentifiers": itemProvider.registeredTypeIdentifiers,
					"canLoadObject(UIImage)": itemProvider.canLoadObject(ofClass: UIImage.self),
					"underlyingErrors": (error as NSError).underlyingErrors
				]
			) // TODO: Remove at some point.

			throw error
		}
	}

	private func saveImage() async throws {
		try await _saveImage()

		guard SSApp.runOnceShouldRun(identifier: "wallpaperTip") else {
			extensionContext.cancel()
			return
		}

		try? await Task.sleep(seconds: 1)
		isWallpaperTipPresented = true
	}

	// TODO: Unify this from the main app.
	private func _saveImage() async throws {
		isSaving = true

		defer {
			isSaving = false
		}

		try? await Task.sleep(seconds: 0.2)

		guard let image = await hostingView?.highestAncestor?.toImage() else {
			SSApp.reportError("Failed to generate the image.")

			throw NSError.appError(
				"Failed to generate the image.",
				recoverySuggestion: "Please report this problem to the developer (sindresorhus@gmail.com)."
			)
		}

		try await image.saveToPhotosLibrary()
	}
}

//struct MainScreen_Previews: PreviewProvider {
//    static var previews: some View {
//        MainScreen()
//    }
//}
