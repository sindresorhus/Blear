import SwiftUI

struct AboutScreen: View {
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		NavigationStack {
			Form {
				Section {} // For padding
				Section {
					SendFeedbackButton()
					Link("Website", destination: "https://sindresorhus.com/blear")
					RateOnAppStoreButton(appStoreID: "994182280")
					MoreAppsButton()
				} footer: {
					Text(markdown: "\n\n**\(SSApp.name) \(SSApp.version)**\n\nMade with ♥ by Sindre Sorhus\nan indie app developer from Norway\n\n.·:*¨༺ ༻¨*:·.\n\nIf you enjoy using this app, please consider leaving a review on the App Store. It helps more than you can imagine.")
						.multilineTextAlignment(.center)
						.frame(maxWidth: 370) // Make it look good on iPad.
						.fillFrame(.horizontal)
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
