import SwiftUI

struct ContentView: View {
	private static let stockImages = Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: "Bundled Photos")!
	private static let randomImageIterator = stockImages.uniqueRandomElement()

	private static func getRandomImage() -> UIImage {
		UIImage(contentsOf: randomImageIterator.next()!)!
	}

	// For testing individual bundled images.
	// @State private var image = stockImages.first { $0.path.contains("stock6.jpg") }.map { UIImage(contentsOf: $0)! } ?? UIImage()

	@State private var image = Self.getRandomImage()
	@State private var blurAmount = Constants.initialBlurAmount
	@State private var isShowingShakeTip = false
	@State private var isShowingWallpaperTip = false
	@State private var isShowingAboutSheet = false
	@State private var isSaving = false
	@State private var saveError: Error?
	@ViewStorage private var window: UIWindow?

	private var controls: some View {
		VStack {
			HStack {
				Spacer()
				Menu {
					Button {
						randomImage()
					} label: {
						Label("Random Image", systemImage: "photo")
					}
					Divider()
					Button {
						isShowingAboutSheet = true
					} label: {
						Label("About", systemImage: "info.circle")
					}
				} label: {
					Image(systemName: "ellipsis.circle")
						.accessibility(label: Text("More"))
						// TODO: Workaround for iOS 14.1 where the tap target is tiny.
						.imageScale(.large)
						.padding(.trailing, 2)
						.contentShape(Rectangle())
						//
						.shadow(radius: Constants.buttonShadowRadius)
						.accentColor(.white)
				}
			}
				.padding(.top)
			Spacer()
			HStack {
				SinglePhotoPickerButton { pickedImage in
					image = Utilities.resizeImage(pickedImage)
				}
					.accessibility(label: Text("Pick Image"))
					.shadow(radius: Constants.buttonShadowRadius)
				Spacer()
				// TODO: Use a custom slider like the iOS brightness control.
				Slider(value: $blurAmount, in: 10...100)
					.padding(.horizontal, DeviceInfo.isPad ? 60 : 30)
					.frame(maxWidth: 500)
				Spacer()
				Button {
					saveImage()
				} label: {
					Image(systemName: "square.and.arrow.down")
				}
					.accessibility(label: Text("Save Image"))
					.shadow(radius: Constants.buttonShadowRadius)
			}
				.imageScale(.large)
				.accentColor(.white)
		}
			.edgesIgnoringSafeArea(.top)
			.padding(.horizontal, DeviceInfo.isPad ? 50 : 30)
			.padding(.bottom, DeviceInfo.isPad ? 50 : 30)
			.fadeInAfterDelay(0.4)
	}

	var body: some View {
		ZStack {
			EditorView(
				image: $image,
				blurAmount: $blurAmount
			)
				.onTapGesture(count: 2) {
					randomImage()
				}
			if !isSaving {
				controls
			}
		}
			.statusBar(hidden: true)
			.alert2(isPresented: $isShowingShakeTip) {
				Alert(
					title: Text("Tip"),
					message: Text("Double-tap the image or shake the device to get another random image.")
				)
			}
			.alert2(isPresented: $isShowingWallpaperTip) {
				Alert(
					title: Text("How to Change Wallpaper"),
					message: Text("In the Photos app, go to the image you just saved, tap the action button at the \(DeviceInfo.isPad ? "top right" : "bottom left"), and choose “Use as Wallpaper”.")
				)
			}
			.alert(error: $saveError)
			.sheet2(isPresented: $isShowingAboutSheet) {
				AboutView()
			}
			.onAppear {
				showShakeTipIfNeeded()
			}
			.onReceive(UIDevice.current.didShakePublisher) { _ in
				image = Self.getRandomImage()
			}
			.accessNativeWindow {
				window = $0
			}
	}

	private func randomImage() {
		image = Self.getRandomImage()
	}

	private func saveImage() {
		isSaving = true

		delay(seconds: 0.2) {
			guard let image = window?.rootViewController?.view?.toImage() else {
				saveError = NSError.appError(
					"Failed to generate the image.",
					recoverySuggestion: "Please report this problem to the developer."
				)
				return
			}

			image.saveToPhotosLibrary { error in
				isSaving = false

				if let error = error {
					saveError = error
					return
				}

				showWallpaperTipIfNeeded()
			}
		}
	}

	private func showShakeTipIfNeeded() {
		guard SSApp.isFirstLaunch else {
			return
		}

		delay(seconds: 1.5) {
			isShowingShakeTip = true
		}
	}

	private func showWallpaperTipIfNeeded() {
		guard SSApp.isFirstLaunch else {
			return
		}

		delay(seconds: 1) {
			isShowingWallpaperTip = true
		}
	}
}
