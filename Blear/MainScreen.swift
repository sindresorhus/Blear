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
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@State private var image = Self.getRandomImage()
	@State private var blurAmount = Constants.initialBlurAmount
	@State private var isShakeTipPresented = false
	@State private var isWallpaperTipPresented = false
	@State private var isSaving = false
	@State private var error: Error?
	@ViewStorage private var hostingWindow: UIWindow?

	private var isPad: Bool { horizontalSizeClass == .regular }

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
			// We intentionally don't use `safeAreaBar` as it creates some shadow.
			.safeAreaInset(edge: .top) {
				if !isSaving {
					actionButton
				}
			}
			.safeAreaInset(edge: .bottom) {
				if !isSaving {
					bottomControls
						.transition(.opacity)
				}
			}
			.alert2(
				"Tip",
				message: "Double-tap the image or shake the device to get another random image.",
				isPresented: $isShakeTipPresented
			)
			.alert2(
				"How to Change Wallpaper",
				message: "In the Photos app, go to the image you just saved, tap the action button at the \(isPad ? "top right" : "bottom left"), and choose “Use as Wallpaper”.",
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
		}
	}

	private var bottomControls: some View {
		HStack {
			SinglePhotoPickerButton { pickedImage in
				Task {
					await tryOrAssign($error) {
						image = try await pickedImage.loadImage(maxPixelSize: Constants.maxImagePixelSize)
					}
				}
			}
			.buttonStyle(.glass)
			.labelStyle(.iconOnly)
			Spacer()
			Slider(value: $blurAmount, in: 10...100)
				.tint(.white)
				.padding(.horizontal, isPad ? 60 : 30)
				.frame(minWidth: 180, maxWidth: 500)
				.scaleEffect(sizeCategory.isAccessibilityCategory ? 1.5 : 1)
				.padding(.horizontal, sizeCategory.isAccessibilityCategory ? 10 : 0)
			Spacer()
			Button("Save image", systemImage: "square.and.arrow.down") {
				Task {
					await tryOrAssign($error) {
						try await saveImage()
					}
				}
			}
			.buttonStyle(.glass)
			.labelStyle(.iconOnly)
		}
		.imageScale(.large)
		.padding(.horizontal, isPad ? 50 : 30)
		.padding(.vertical)
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
			Label("Action", systemImage: "ellipsis")
				.labelStyle(.iconOnly)
		}
		.buttonStyle(.glass)
		.buttonBorderShape(.capsule)
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
