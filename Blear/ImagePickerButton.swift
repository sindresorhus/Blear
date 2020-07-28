import SwiftUI

struct ImagePickerButton: View {
	@State private var isShowingImagePicker = false
	@State private var image: UIImage?

	// TODO: I can drop this and use the `image` binding when the whole app is rewritten in SwiftUI.
	var onImage: (UIImage) -> Void

	var body: some View {
		Button(action: {
			isShowingImagePicker = true
		}) {
			Image(systemName: "photo.on.rectangle")
		}
			// TODO: It should ideally use a fullscreen modal when showing the camera, but that's not currently possible in SwiftUI.
			.sheet(isPresented: $isShowingImagePicker) {
				ImagePicker(sourceType: .photoLibrary, image: $image)
			}
			.onChange(of: image) {
				guard let image = $0 else {
					return
				}

				onImage(image)
			}
	}
}
