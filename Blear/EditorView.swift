import SwiftUI

struct EditorView: View {
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
				.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
			.edgesIgnoringSafeArea(.all)
			.onChange(of: image) { _ in
				updateImage(blurAmount: blurAmount)
			}
			.onChange(of: blurAmount) {
				updateImage(blurAmount: $0)
			}
			.onAppear {
				UIScrollView.appearance().bounces = false
				updateImage(blurAmount: blurAmount)
			}
    }

	private func blurImage(_ blurAmount: Double) -> UIImage {
		UIImageEffects.imageByApplyingBlur(
			to: image,
			withRadius: CGFloat(blurAmount * 0.8),
			tintColor: UIColor(white: 1, alpha: CGFloat(max(0, min(0.25, blurAmount * 0.004)))),
			saturationDeltaFactor: CGFloat(max(1, min(2.8, blurAmount * (DeviceInfo.isPad ? 0.035 : 0.045)))),
			maskImage: nil
		)
	}

	private func updateImage(blurAmount: Double) {
		if let workItem = self.workItem {
			workItem.cancel()
		}

		let workItem = DispatchWorkItem {
			blurredImage = blurImage(blurAmount)
		}
		self.workItem = workItem

		DispatchQueue.global(qos: .userInteractive).async(execute: workItem)
	}
}

//struct EditorView_Previews: PreviewProvider {
//    static var previews: some View {
//        EditorView()
//    }
//}
