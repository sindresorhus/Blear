import SwiftUI

struct ImagePickerButton: View {
	@State private var isShowingSheet = false
	@State private var isShowingImagePicker = false
	@State private var pickerType = UIImagePickerController.SourceType.photoLibrary
	@State private var image: UIImage?

	private var buttons: [ActionSheet.Button] {
		var buttons: [ActionSheet.Button] = [
			.default(Text("Take Photo")) {
				self.pickerType = .camera
				self.isShowingImagePicker = true
			},
			.default(Text("Photo Library")) {
				self.pickerType = .photoLibrary
				self.isShowingImagePicker = true
			},
			.cancel()
		]

		if !UIImagePickerController.isSourceTypeAvailable(.camera) {
			buttons.removeFirst()
		}

		return buttons
	}

	// TODO: I can drop this and use the `image` binding when the whole app is rewritten in SwiftUI.
	var onImage: (UIImage) -> Void

	var body: some View {
		Button(action: {
			self.isShowingSheet = true
		}) {
			Image(systemName: "camera")
		}
			.actionSheet(isPresented: $isShowingSheet) {
				ActionSheet(
					title: Text("Pick an Image"),
					buttons: buttons
				)
			}
			// TODO: It should ideally use a fullscreen modal when showing the camera, but that's not currently possible in SwiftUI.
			.sheet(isPresented: $isShowingImagePicker) {
				// TODO: Use `View#onChange` when targeting iOS 14.
				ImagePicker(sourceType: self.pickerType, image: self.$image.onChange {
					guard let image = $0 else {
						return
					}

					self.onImage(image)
				})
			}
	}
}
