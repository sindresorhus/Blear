import SwiftUI

struct AboutView: View {
	@Environment(\.presentationMode) private var presentationMode

	var body: some View {
		NavigationView {
			Form {
				Section(
					header: Text("\(SSApp.name) \(SSApp.version)"),
					footer: Text("\n\(SSApp.name) was made with ♥ by Sindre Sorhus, an indie app developer from Norway.\n\nIf you enjoy using this app, please consider leaving a review in the App Store. It helps more than you can imagine.")
				) {
					SendFeedbackButton()
					Link("Website", destination: "https://sindresorhus.com/blear")
					RateOnAppStoreButton(appStoreID: "994182280")
					MoreAppsButton()
				}
			}
				.navigationTitle("About")
				.navigationBarTitleDisplayMode(.inline)
				.toolbar {
					ToolbarItem(placement: .confirmationAction) {
						Button("Done") {
							presentationMode.wrappedValue.dismiss()
						}
					}
				}
		}
	}
}

struct AboutView_Previews: PreviewProvider {
	static var previews: some View {
		AboutView()
	}
}
