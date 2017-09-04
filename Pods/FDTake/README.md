# FDTake

[![CI Status](http://img.shields.io/travis/fulldecent/FDTake.svg?style=flat)](https://travis-ci.org/fulldecent/FDTake)
[![Version](https://img.shields.io/cocoapods/v/FDTake.svg?style=flat)](http://cocoapods.org/pods/FDTake)
[![License](https://img.shields.io/cocoapods/l/FDTake.svg?style=flat)](http://cocoapods.org/pods/FDTake)
[![Platform](https://img.shields.io/cocoapods/p/FDTake.svg?style=flat)](http://cocoapods.org/pods/FDTake)
[![Readme Score](http://readme-score-api.herokuapp.com/score.svg?url=fulldecent/FDTake)](http://clayallsopp.github.io/readme-score?url=fulldecent/FDTake)


## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

To use it in your project, add an `FDTakeController` to your view controller and implement:

    fdTakeController.didGetPhoto = {
        (_ photo: UIImage, _ info: [AnyHashable : Any]) in
    }

then call:

    fdTakeController.present()

The full API is:

```swift
/// Public initializer
public override init()

/// Convenience method for getting a photo
open class func getPhotoWithCallback(getPhotoWithCallback callback: @escaping (_ photo: UIImage, _ info: [AnyHashable : Any]) -> Void) -> <<error type>>

/// Convenience method for getting a video
open class func getVideoWithCallback(getVideoWithCallback callback: @escaping (_ video: URL, _ info: [AnyHashable : Any]) -> Void)

/// Whether to allow selecting a photo
open var allowsPhoto: Bool

/// Whether to allow selecting a video
open var allowsVideo: Bool

/// Whether to allow capturing a photo/video with the camera
open var allowsTake: Bool

/// Whether to allow selecting existing media
open var allowsSelectFromLibrary: Bool

/// Whether to allow editing the media after capturing/selection
open var allowsEditing: Bool

/// Whether to use full screen camera preview on the iPad
open var iPadUsesFullScreenCamera: Bool

/// Enable selfie mode by default
open var defaultsToFrontCamera: Bool

/// The UIBarButtonItem to present from (may be replaced by a overloaded methods)
open var presentingBarButtonItem: UIBarButtonItem?

/// The UIView to present from (may be replaced by a overloaded methods)
open var presentingView: UIView?

/// The UIRect to present from (may be replaced by a overloaded methods)
open var presentingRect: CGRect?

/// The UITabBar to present from (may be replaced by a overloaded methods)
open var presentingTabBar: UITabBar?

/// The UIViewController to present from (may be replaced by a overloaded methods)
open lazy var presentingViewController: UIViewController { get set }

/// A photo was selected
open var didGetPhoto: ((_ photo: UIImage, _ info: [AnyHashable : Any]) -> Void)?

/// A video was selected
open var didGetVideo: ((_ video: URL, _ info: [AnyHashable : Any]) -> Void)?

/// The user selected did not attempt to select a photo
open var didDeny: (() -> Void)?

/// The user started selecting a photo or took a photo and then hit cancel
open var didCancel: (() -> Void)?

/// A photo or video was selected but the ImagePicker had NIL for EditedImage and OriginalImage
open var didFail: (() -> Void)?

/// Custom UI text (skips localization)
open var cancelText: String?

/// Custom UI text (skips localization)
open var chooseFromLibraryText: String?

/// Custom UI text (skips localization)
open var chooseFromPhotoRollText: String?

/// Custom UI text (skips localization)
open var noSourcesText: String?

/// Custom UI text (skips localization)
open var takePhotoText: String?

/// Custom UI text (skips localization)
open var takeVideoText: String?

/// Presents the user with an option to take a photo or choose a photo from the library
open func present()

/// Dismisses the displayed view. Especially handy if the sheet is displayed while suspending the app,
open func dismiss()
```

Other available options are documented at <a href="http://cocoadocs.org/docsets/FDTake/">CocoaDocs for FDTake</a>.


## How it works

 1. See if device has camera
 2. Create action sheet with appropriate options ("Take Photo" or "Choose from Library"), as available
 3. Localize "Take Photo" and "Choose from Library" into user's language
 4. Wait for response
 5. Bring up image picker with selected image picking method
 6. Default to selfie mode if so configured
 7. Get response, extract image from a dictionary
 8. Dismiss picker, send image to delegate


## Support

 * Supports iPhones, iPods, iPads and tvOS (but not tested)
 * Supported languages:
   - English
   - Chinese Simplified
   - Turkish (thanks Suleyman Melikoglu)
   - French (thanks Guillaume Algis)
   - Dutch (thanks Mathijs Kadijk)
   - Chinese Traditional (thanks Qing Ao)
   - German (thanks Lars Häuser)
   - Russian (thanks Alexander Zubkov)
   - Norwegian (thanks Sindre Sorhus)
   - Arabic (thanks HadiIOS)
   - Polish (thanks Jacek Kwiecień)
   - Spanish (thanks David Jorge)
   - Hebrew (thanks Asaf Siman-Tov)
   - Danish (thanks kaspernissen)
   - Sweedish (thanks Paul Peelen)
   - Portugese (thanks Natan Rolnik)
   - Greek (thanks Konstantinos)
   - Italian (thanks Giuseppe Filograno)
   - Hungarian (thanks Andras Kadar)
   - Please help translate <a href="https://github.com/fulldecent/FDTake/blob/master/FDTakeExample/en.lproj/FDTake.strings">`FDTake.strings`</a> to more languages
 * Pure Swift support and iOS 8+ required
 * Compile testing running on Travis CI
 * In progress: functional test cases ([please help](https://github.com/fulldecent/FDTake/issues/72))
 * In progress: UI test cases ([please help](https://github.com/fulldecent/FDTake/issues/72))
 * In progress: select last photo used ([please help](https://github.com/fulldecent/FDTake/issues/22))


## Installation

FDTake is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'FDTake'
```


## Author

William Entriken, github.com@phor.net


## License

FDTake is available under the MIT license. See the LICENSE file for more info.
