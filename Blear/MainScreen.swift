import SwiftUI

struct MainScreen: View {
	private static let stockImages = Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: "Bundled Photos")!
	private static let randomImageIterator = stockImages.infiniteConsecutivelyUniqueRandomSequence().makeIterator()

	private static func getRandomImage() -> UIImage {
		UIImage(contentsOf: randomImageIterator.next()!)!
	}

	// For testing individual bundled images.
	// @State private var image = stockImages.first { $0.path.contains("stock6.jpg") }.map { UIImage(contentsOf: $0)! } ?? UIImage()

	@Environment(\.sizeCategory) private var sizeCategory
	@State private var image = Self.getRandomImage()
	@State private var blurAmount = Constants.initialBlurAmount
	@State private var isShakeTipPresented = false
	@State private var isWallpaperTipPresented = false
	@State private var isAboutScreenPresented = false
	@State private var isSaving = false
	@State private var error: Error?
	@ViewStorage private var nativeWindow: UIWindow?

	var body: some View {
		NavigationStack {
			ZStack {
				EditorScreen(
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
				.alert2(
					"Tip",
					message: "Double-tap the image or shake the device to get another random image.",
					isPresented: $isShakeTipPresented
				)
				.alert2(
					"How to Change Wallpaper",
					message: "In the Photos app, go to the image you just saved, tap the action button at the \(DeviceInfo.isPad ? "top right" : "bottom left"), and choose “Use as Wallpaper”.",
					isPresented: $isWallpaperTipPresented
				)
				.alert(error: $error)
				.sheet(isPresented: $isAboutScreenPresented) {
					AboutScreen()
				}
				.task {
					await showShakeTipIfNeeded()
				}
				.onDeviceShake {
					image = Self.getRandomImage()
				}
				.bindNativeWindow($nativeWindow)
//				.toolbar {
//					ToolbarItem(placement: .bottomBar) {
//						Button("DD", systemImage: "circle.fill") {}
//							.tint(.white)
//					}
//				}
//				.toolbarBackground(.hidden, for: .automatic)
				// TODO: The above does not actually remove the background. (iOS 16.1)
		}
	}

	private var controls: some View {
		VStack {
			HStack {
				Spacer()
				moreButton
			}
				.padding(.top) // TODO: Remove this when the homebutton type phones are no longer supported.
			Spacer()
			HStack {
				SinglePhotoPickerButton { pickedImage in
					Task {
						await tryOrAssign($error) {
							image = try await pickedImage.loadImage(maxPixelSize: Constants.maxImagePixelSize)
						}
					}
				}
					.labelStyle(.iconOnly)
					.shadow(radius: Constants.buttonShadowRadius)
					// Increase tap area
					.padding(8)
					.contentShape(.rectangle)
					.padding(.horizontal, -8)
				Spacer()
				// TODO: Use a custom slider like the iOS brightness control.
				Slider(value: $blurAmount, in: 10...100)
					.padding(.horizontal, DeviceInfo.isPad ? 60 : 30)
					.frame(minWidth: 180, maxWidth: 500)
					.scaleEffect(sizeCategory.isAccessibilityCategory ? 1.5 : 1)
					.padding(.horizontal, sizeCategory.isAccessibilityCategory ? 10 : 0)
				Spacer()
				Button {
					Task {
						await tryOrAssign($error) {
							try await saveImage()
						}
					}
				} label: {
					Image(systemName: "square.and.arrow.down")
						// Increase tap area
						.padding(8)
						.contentShape(.rectangle)
				}
					.help("Save image")
					.shadow(radius: Constants.buttonShadowRadius)
					.padding(.horizontal, -8)
			}
				.imageScale(.large)
				.tint(.white)
		}
			// TODO: Fix
//			.ignoresSafeArea(.top)
			.padding(.horizontal, DeviceInfo.isPad ? 50 : 30)
			.padding(.bottom, DeviceInfo.isPad ? 50 : 30)
			.fadeInAfterDelay(0.4)
	}

	private var moreButton: some View {
		Menu {
			Button("Random Image", systemImage: "photo") {
				randomImage()
			}
			Divider()
			Button("About", systemImage: "info.circle") {
				isAboutScreenPresented = true
			}
		} label: {
			Label("More", systemImage: "ellipsis.circle")
				// TODO: Workaround for iOS 15.4 where the tap target is tiny.
				.imageScale(.large)
				.padding(.trailing, 2)
				// Increase tap area
				.padding(8)
				.contentShape(.rectangle)
				//
				.shadow(radius: Constants.buttonShadowRadius)
				.tint(.white)
				.labelStyle(.iconOnly)
				.offset(y: -8)
		}
	}

	private func randomImage() {
		image = Self.getRandomImage()
	}

	private func saveImage() async throws {
		try await _saveImage()

		await showWallpaperTipIfNeeded()

		await SSApp.requestReviewAfterBeingCalledThisManyTimes([3, 50, 200, 500, 1000])
	}

	private func _saveImage() async throws {
		isSaving = true

		defer {
			isSaving = false
		}

		try? await Task.sleep(for: .seconds(0.2))

		guard let image = await nativeWindow?.rootViewController?.view?.toImage() else {
			SSApp.reportError("Failed to generate the image.")

			throw GeneralError(
				"Failed to generate the image.",
				recoverySuggestion: "Please report this problem to the developer (sindresorhus@gmail.com)."
			)
		}

		try await image.saveToPhotosLibrary()
	}

	private func showShakeTipIfNeeded() async {
		guard SSApp.isFirstLaunch else {
			return
		}

		try? await Task.sleep(for: .seconds(1.5))
		isShakeTipPresented = true
	}

	private func showWallpaperTipIfNeeded() async {
		guard SSApp.isFirstLaunch else {
			return
		}

		try? await Task.sleep(for: .seconds(1))
		isWallpaperTipPresented = true
	}
}
