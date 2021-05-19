import SwiftUI

struct AboutScreen: View {
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		NavigationView {
			Form {
				Section(
					header: Text("\(SSApp.name) \(SSApp.version)"),
					footer: Text("\n\(SSApp.name) was made with ♥ by Sindre Sorhus, an indie app developer from Norway.\n\nIf you enjoy using this app, please consider leaving a review on the App Store. It helps more than you can imagine.")
				) {
					SendFeedbackButton()
					Link("Website", destination: "https://sindresorhus.com/blear")
					RateOnAppStoreButton(appStoreID: "994182280")
					MoreAppsButton()
				}
			}
				.navigationTitle("About")
				.toolbar {
					ToolbarItem(placement: .confirmationAction) {
						Button("Done") {
							dismiss()
						}
					}
				}
		}
	}
}

struct AboutScreen_Previews: PreviewProvider {
	static var previews: some View {
		AboutScreen()
	}
}
