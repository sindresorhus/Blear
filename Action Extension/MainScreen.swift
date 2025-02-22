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

	var body: some View {
		VStack {
			if let image {
				EditorScreen(
					image: .constant(image),
					blurAmount: $blurAmount
				)
			}
		}
		.safeAreaInset(edge: .top) {
			if !isSaving {
				controls
					.safeAreaPadding(.top, 16)
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
			guard !isWallpaperTipPresented else {
				return
			}

			extensionContext.cancel()
		}
		.alert(error: $error)
		.accessHostingView {
			hostingView = $0
		}
	}

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
							.contentShape(.rect)
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
							.contentShape(.rect)
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

	private func getImage() async throws -> UIImage {
		// TODO: Switch to Transferable when targeting iOS 20.
		guard
			let itemProvider = (extensionContext.attachments.first { $0.hasItemConforming(to: .image) })
		else {
			throw "Did not receive any compatible image.".toError
		}

		// TODO: Force the following to execute in a background thread.
		do {
			return try await itemProvider.loadImage(maxPixelSize: Constants.maxImagePixelSize)
		} catch {
			SSApp.reportError(
				error,
				userInfo: [
					"registeredContentTypes": itemProvider.registeredContentTypes,
					"canLoadObject(UIImage)": itemProvider.canLoadObject(ofClass: UIImage.self),
					"underlyingErrors": (error as NSError).underlyingErrors
				]
			) // TODO: Remove at some point.

			throw error
		}
	}

	private func saveImage() async throws {
		try await hostingView?.highestAncestor?.blear_saveToPhotoLibrary(isSaving: $isSaving)

		guard SSApp.runOnceShouldRun(identifier: "wallpaperTip") else {
			extensionContext.cancel()
			return
		}

		try? await Task.sleep(for: .seconds(1))
		isWallpaperTipPresented = true
	}
}

//#Preview {
//	MainScreen()
//}

extension NSItemProvider: @retroactive @unchecked Sendable {}
