import SwiftUI
import UniformTypeIdentifiers

struct MainScreen: View {
	@Environment(\.extensionContext) private var extensionContext: NSExtensionContext!
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@State private var image: UIImage?
	@State private var blurAmount = Constants.initialBlurAmount
	@State private var isSaving = false
	@State private var error: Error?
	@State private var isWallpaperTipPresented = false
	@ViewStorage private var hostingView: UIView?

	private var isPad: Bool { horizontalSizeClass == .regular }

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
			message: "Go to the most recent photo in the photo library, tap the action button at the \(isPad ? "top right" : "bottom left"), and choose “Use as Wallpaper”.",
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
				Button(role: .close) {
					extensionContext.cancel()
				}
				.scaleEffect(1.2) // Work around iOS 26 bug where the button is tiny.
				Spacer()
				Button(
					"Save image",
					systemImage: "square.and.arrow.down",
					role: .confirm
				) {
					Task {
						await tryOrAssign($error) {
							try await saveImage()
						}
					}
				}
			}
			.buttonStyle(.glass)
			.buttonBorderShape(.circle)
			.labelStyle(.iconOnly)
			.padding(.horizontal)
			Spacer()
			Slider(value: $blurAmount, in: 10...100)
				.tint(.white)
				.padding(.horizontal, isPad ? 60 : 30)
				.frame(maxWidth: 500)
		}
		.padding()
		.padding(.bottom, 40)
		.padding(.vertical)
	}

	private func getImage() async throws -> UIImage {
		guard
			let itemProvider = (extensionContext.attachments.first { $0.hasItemConforming(to: .image) })
		else {
			throw "Did not receive any compatible image.".toError
		}

		return try await itemProvider.loadImage(maxPixelSize: Constants.maxImagePixelSize)
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
