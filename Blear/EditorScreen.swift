import SwiftUI

// TODO: Move to an ObservableObject that handles the blurring. Or maybe Actor?

struct EditorScreen: View {
	private static let updateImageQueue = DispatchQueue(label: "\(SSApp.idString).updateImage", qos: .userInteractive)

	@ViewStorage private var workItem: DispatchWorkItem?
	@State private var blurredImage: UIImage?

	@Binding var image: UIImage // Binding is required here, even if not needed, as the view doesn't properly update otherwise. (iOS 14.1)
	@Binding var blurAmount: Double

    var body: some View {
		VStack {
			GeometryReader { proxy in
				ScrollView(.horizontal, showsIndicators: false) {
					Image(uiImage: blurredImage ?? image)
						.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(minWidth: proxy.size.width)
				}
			}
				.fillFrame()
		}
			.ignoresSafeArea()
			.onChange(of: image) { _ in
				updateImage(blurAmount: blurAmount)
			}
			.onChange(of: blurAmount) {
				updateImage(blurAmount: $0)
			}
			.task {
				UIScrollView.appearance().bounces = false
				updateImage(blurAmount: blurAmount)
			}
    }

	private func blurImage(_ blurAmount: Double) -> UIImage {
		UIImageEffects.imageByApplyingBlur(
			to: image,
			withRadius: blurAmount * 0.8,
			tintColor: UIColor(white: 1, alpha: max(0, min(0.25, blurAmount * 0.004))),
			saturationDeltaFactor: max(1, min(2.8, blurAmount * (DeviceInfo.isPad ? 0.035 : 0.045))),
			maskImage: nil
		)
	}

	private func updateImage(blurAmount: Double) {
		if let workItem {
			workItem.cancel()
		}

		let workItem = DispatchWorkItem {
			blurredImage = blurImage(blurAmount)
		}
		self.workItem = workItem

		Self.updateImageQueue.async(execute: workItem)
	}
}

//struct EditorScreen_Previews: PreviewProvider {
//    static var previews: some View {
//        EditorScreen()
//    }
//}
