import SwiftUI
import Combine
import Photos
import JGProgressHUD

struct ContentView: View {
	private let buttonShadowRadius: CGFloat = 4
	@State private var cancellables = Set<AnyCancellable>() // TODO: Any better way to do this?
	@State private var blurAmount = 0.0
	@State private var isShowingShakeTip = false
	@State private var isShowingWallpaperTip = false

	let onSliderChange: (Double) -> Void
	let onImage: (UIImage) -> Void

	var body: some View {
		VStack {
			Spacer()
			HStack {
				ImagePickerButton {
					self.onImage($0)
				}
					.shadow(radius: buttonShadowRadius)
				Spacer()
				// TODO: Use a custom slider like the iOS brightness control.
				// TODO: Use `View#onChange` when targeting iOS 14.
				Slider(value: $blurAmount.onChange(onSliderChange), in: 10...100)
					.padding(.horizontal, DeviceInfo.isPad ? 60 : 30)
					.frame(maxWidth: 500)
				Spacer()
				Button(action: {
					self.saveImage()
				}) {
					Image(systemName: "square.and.arrow.down")
				}
					.shadow(radius: buttonShadowRadius)
			}
				.imageScale(.large)
				.fadeInAfterDelay(0.5)
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
					// TODO: Check if it's possible to have multiple alerts on a single element in iOS 14.
					.alert(isPresented: $isShowingWallpaperTip) {
						Alert(
							title: Text("Changing Wallpaper"),
							message: Text("In the Photos app, go to the image you just saved, tap the action button at the bottom left, and choose “Use as Wallpaper”.")
						)
					}
			)
			.onAppear {
				self.showShakeTipIfNeeded()
			}
	}

	private func saveImage() {
		// TODO: Replace `JGProgressHUD` with a custom SwiftUI view using `View#fullscreenCover()`.
		let HUD = JGProgressHUD(style: .dark)
		HUD.indicatorView = JGProgressHUDSuccessIndicatorView()
		HUD.animation = JGProgressHUDFadeZoomAnimation()
		HUD.vibrancyEnabled = true
		HUD.contentInsets = UIEdgeInsets(all: 30)

		let view = ViewController.shared.view!
		let image = ViewController.shared.scrollView.toImage()

		PHPhotoLibrary.save(
			image: image,
			toAlbum: "Blear"
		)
			.receive(on: DispatchQueue.main)
			.sink(receiveCompletion: { error in
				switch error {
				case .finished:
					HUD.show(in: view)
					HUD.dismiss(afterDelay: 0.8)

					self.showWallpaperTipIfNeeded()
				case .failure(let error):
					HUD.indicatorView = JGProgressHUDErrorIndicatorView()
					HUD.textLabel.text = error.localizedDescription
					HUD.show(in: view)
					HUD.dismiss(afterDelay: 3)
				}
			}, receiveValue: { _ in })
			.store(in: &cancellables)
	}

	private func showShakeTipIfNeeded() {
		guard App.isFirstLaunch else {
			return
		}

		delay(seconds: 1.5) {
			self.isShowingShakeTip = true
		}
	}

	private func showWallpaperTipIfNeeded() {
		guard App.isFirstLaunch else {
			return
		}

		delay(seconds: 1) {
			self.isShowingWallpaperTip = true
		}
	}
}
