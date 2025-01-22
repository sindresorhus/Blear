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
	@Environment(\.requestReview) private var requestReview
	@State private var image = Self.getRandomImage()
	@State private var blurAmount = Constants.initialBlurAmount
	@State private var isShakeTipPresented = false
	@State private var isWallpaperTipPresented = false
	@State private var isSaving = false
	@State private var error: Error?
	@ViewStorage private var hostingWindow: UIWindow?

	var body: some View {
		NavigationStack {
			EditorScreen(
				image: $image,
				blurAmount: $blurAmount
			)
			.statusBarHidden()
			.onTapGesture(count: 2) {
				randomImage()
			}
			.overlay {
				if !isSaving {
					controls
				}
			}
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
			.task {
				await showShakeTipIfNeeded()
			}
			.onDeviceShake {
				image = Self.getRandomImage()
			}
			.bindHostingWindow($hostingWindow)
//			.toolbar {
//				ToolbarItem(placement: .bottomBar) {
//					Button("DD", systemImage: "circle.fill") {}
//						.tint(.white)
//				}
//			}
//			.toolbarBackground(.hidden, for: .bottomBar)
			// TODO: The above does not actually remove the background. (iOS 17.0)
		}
	}

	private var controls: some View {
		VStack {
			HStack {
				Spacer()
				actionButton
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
						.contentShape(.rect)
				}
				.help("Save image")
				.shadow(radius: Constants.buttonShadowRadius)
				.padding(.horizontal, -8)
			}
			.imageScale(.large)
			.tint(.white)
		}
			// TODO: Fix
//		.ignoresSafeArea(.top)
		.padding(.horizontal, DeviceInfo.isPad ? 50 : 30)
		.padding(.bottom, DeviceInfo.isPad ? 50 : 30)
		.compositingGroup()
		.transition(.opacity)
		// TODO: Fix
//		.fadeInAfterDelay(0.4)
	}

	private var actionButton: some View {
		Menu {
			Button("Random Image", systemImage: "photo") {
				randomImage()
			}
			Divider()
			SendFeedbackButton()
			Link("Website", systemImage: "safari", destination: "https://sindresorhus.com/blear")
			RateOnAppStoreButton(appStoreID: "994182280")
			ShareAppButton(appStoreID: "994182280")
			MoreAppsButton()
		} label: {
			Label("Action", systemImage: "ellipsis.circle")
				// TODO: Workaround for iOS 15.4 where the tap target is tiny.
				.imageScale(.large)
				.padding(.trailing, 2)
				// Increase tap area
				.padding(8)
				.contentShape(.rect)
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
		try await hostingWindow?.rootViewController?.view?.blear_saveToPhotoLibrary(isSaving: $isSaving)

		await showWallpaperTipIfNeeded()

		SSApp.requestReviewAfterBeingCalledThisManyTimes([3, 50, 200, 500, 1000], requestReview: requestReview)
	}

	private func showShakeTipIfNeeded() async {
		guard SSApp.isFirstLaunch else {
			return
		}

		try? await Task.sleep(for: .seconds(1.5))
		isShakeTipPresented = true
	}

	private func showWallpaperTipIfNeeded() async {
		guard SSApp.runOnceShouldRun(identifier: "showWallpaperTip") else {
			return
		}

		try? await Task.sleep(for: .seconds(1))
		isWallpaperTipPresented = true
	}
}
