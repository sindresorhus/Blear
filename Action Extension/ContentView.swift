import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
	@Environment(\.extensionContext) private var extensionContext: NSExtensionContext!
	@State private var image: UIImage?
	@State private var blurAmount = Constants.initialBlurAmount
	@State private var isSaving = false
	@State private var loadError: Error?
	@State private var saveError: Error?
	@State private var isShowingWallpaperTip = false
	@ViewStorage private var uiView: UIView?

	private var controls: some View {
		VStack {
			HStack {
				Group {
					Button {
						extensionContext.cancel()
					} label: {
						Image(systemName: "xmark.circle")
							.imageScale(.large)
					}
						.accessibility(label: Text("Cancel"))
					Spacer()
					Button {
						saveImage()
					} label: {
						Image(systemName: "square.and.arrow.down")
							.imageScale(.large)
					}
						.accessibility(label: Text("Save Image"))
				}
					.shadow(radius: Constants.buttonShadowRadius)
					.accentColor(.white)
					.padding(.horizontal)
			}
			Spacer()
			Slider(value: $blurAmount, in: 10...100)
				.padding(.horizontal, DeviceInfo.isPad ? 60 : 30)
				.frame(maxWidth: 500)
				.accentColor(.white)
		}
			.padding()
			.padding(.bottom, 40)
			.padding(.vertical)
	}

    var body: some View {
		ZStack {
			if let image = image {
				EditorView(
					image: .constant(image),
					blurAmount: $blurAmount
				)
			}
			if !isSaving {
				controls
			}
		}
			.onAppear {
				loadImage()
			}
			.alert2(isPresented: $isShowingWallpaperTip) {
				Alert(
					title: Text("How to Change Wallpaper"),
					message: Text("Go to the most recent photo in the photo library, tap the action button at the \(DeviceInfo.isPad ? "top right" : "bottom left"), and choose “Use as Wallpaper”.")
				)
			}
			.onChange(of: isShowingWallpaperTip) {
				guard !$0 else {
					return
				}

				extensionContext.cancel()
			}
			.alert(error: $saveError)
			.accessNativeView {
				uiView = $0
			}
    }

	private func loadImage() {
		guard
			let attachment = extensionContext.attachments.first,
			attachment.hasItemConformingTo(.image)
		else {
			extensionContext.cancel()
			return
		}

		attachment.loadItem(forType: .image) { item, error in
			guard
				let imageURL = item as? URL,
				let pickedImage = UIImage(contentsOf: imageURL)
			else {
				loadError = error
				return
			}

			image = Utilities.resizeImage(pickedImage)
		}
	}

	private func saveImage() {
		isSaving = true

		delay(seconds: 0.2) {
			guard let image = uiView?.highestAncestor?.toImage() else {
				saveError = NSError.appError(
					"Failed to generate the image.",
					// TODO: Report this to AppCenter when it supports non-crash reports.
					recoverySuggestion: "Please report this problem to the developer."
				)
				return
			}

			image.saveToPhotosLibrary { error in
				if let error = error {
					isSaving = false
					saveError = error
					return
				}

				if SSApp.runOnceShouldRun(identifier: "wallpaperTip") {
					isShowingWallpaperTip = true
					return
				}

				extensionContext.cancel()
			}
		}
	}
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
