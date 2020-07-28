import SwiftUI
import Combine
import Photos
import JGProgressHUD

struct ContentView: View {
	private let buttonShadowRadius: CGFloat = 4
	@State private var cancellables = Set<AnyCancellable>()
	@State private var blurAmount = Constants.initialBlurAmount
	@State private var isShowingShakeTip = false
	@State private var isShowingWallpaperTip = false

	let onSliderChange: (Double) -> Void
	let onImage: (UIImage) -> Void

	var body: some View {
		VStack {
			Spacer()
			HStack {
				ImagePickerButton(onImage: onImage)
					.shadow(radius: buttonShadowRadius)
				Spacer()
				// TODO: Use a custom slider like the iOS brightness control.
				Slider(value: $blurAmount, in: 10...100)
					.padding(.horizontal, DeviceInfo.isPad ? 60 : 30)
					.frame(maxWidth: 500)
					.onChange(of: blurAmount, perform: onSliderChange)
				Spacer()
				Button(action: {
					saveImage()
				}) {
					Image(systemName: "square.and.arrow.down")
				}
					.shadow(radius: buttonShadowRadius)
			}
				.imageScale(.large)
				.fadeInAfterDelay(0.4)
		}
			.padding(.horizontal, DeviceInfo.isPad ? 50 : 30)
			.padding(.bottom, DeviceInfo.isPad ? 50 : 30)
			.alert(isPresented: $isShowingShakeTip) {
				Alert(
					title: Text("Tip"),
					message: Text("Shake the device to get a random image.")
				)
			}
			.background(
				EmptyView()
					// This is not at the top-level because of a SwiftUI bug.
					// TODO: Check if it's possible to have multiple alerts on a single element in iOS 15.
					.alert(isPresented: $isShowingWallpaperTip) {
						Alert(
							title: Text("Changing Wallpaper"),
							message: Text("In the Photos app, go to the image you just saved, tap the action button at the bottom left, and choose “Use as Wallpaper”.")
						)
					}
			)
			.onAppear {
				showShakeTipIfNeeded()
			}
	}

	private func saveImage() {
		// TODO: Replace `JGProgressHUD` with a custom SwiftUI view.
		let HUD = JGProgressHUD(style: .dark)
		HUD.indicatorView = JGProgressHUDSuccessIndicatorView()
		HUD.animation = JGProgressHUDFadeZoomAnimation()
		HUD.vibrancyEnabled = true
		HUD.contentInsets = UIEdgeInsets(all: 30)

		let view = ViewController.shared.view!
		let image = ViewController.shared.scrollView.toImage()

		image.saveToPhotosLibrary {
			if let error = $0 {
				// TODO: Improve the error message when the user did not allow access. Currently, iOS just returns "Data unavilable", which is not very user-friendly.
				HUD.indicatorView = JGProgressHUDErrorIndicatorView()
				HUD.textLabel.text = error.localizedDescription
				HUD.show(in: view)
				HUD.dismiss(afterDelay: 3)
				return
			}

			HUD.show(in: view)
			HUD.dismiss(afterDelay: 0.8)

			showWallpaperTipIfNeeded()
		}
	}

	private func showShakeTipIfNeeded() {
		guard App.isFirstLaunch else {
			return
		}

		delay(seconds: 1.5) {
			isShowingShakeTip = true
		}
	}

	private func showWallpaperTipIfNeeded() {
		guard App.isFirstLaunch else {
			return
		}

		delay(seconds: 1) {
			isShowingWallpaperTip = true
		}
	}
}
