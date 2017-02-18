FDTake
================

[![CI Status](http://img.shields.io/travis/fulldecent/FDTake.svg?style=flat)](https://travis-ci.org/fulldecent/FDTake)
[![Version](https://img.shields.io/cocoapods/v/FDTake.svg?style=flat)](http://cocoadocs.org/docsets/FDTake)
[![License](https://img.shields.io/cocoapods/l/FDTake.svg?style=flat)](http://cocoadocs.org/docsets/FDTake)
[![Platform](https://img.shields.io/cocoapods/p/FDTake.svg?style=flat)](http://cocoadocs.org/docsets/FDTake)

`FDTake` helps you quickly have the user take or choose an existing photo or video.

<img src="https://i.imgur.com/SpSJzmS.png" alt="screenshot" height=400/>

Usage
----------------
To use it, add an `FDTake` to your view and call

    - (void)takePhotoOrChooseFromLibrary

then implement `FDTakeDelegate` to receive the photo with

    - (void)takeController:(FDTakeController *)controller 
                  gotPhoto:(UIImage *)photo 
                  withInfo:(NSDictionary *)info`

Other available options are documented at <a href="http://cocoadocs.org/docsets/FDTake/0.2.1/">CocoaDocs for FDTake</a>.

How it works
----------------
 1. See if device has camera
 2. Create action sheet with appropriate options ("Take Photo" or "Choose from Library"), as available
 3. Localize "Take Photo" and "Choose from Library" into user's language
 4. Wait for response
 5. Bring up image picker with selected image picking method
 6. Default to selfie mode if so configured
 7. Get response, extract image from a dictionary
 8. Dismiss picker, send image to delegate

Support
----------------
 * Supports iPhones, iPods and iPads
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
   - Please help translate <a href="https://github.com/fulldecent/FDTake/blob/master/FDTakeExample/en.lproj/FDTake.strings">`FDTake.strings`</a> to more languages
 * Supports ARC and iOS 5+
 * Includes unit tests which run successfully using Travis CI.
 
Installation
-----------------
  1. Add `pod 'FDTake'` to your <a href="https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking">Podfile</a>
  2. The the API documentation under "Class Reference" at http://cocoadocs.org/docsets/FDTake/
  3. Please add your project to "I USE THIS" at https://www.cocoacontrols.com/controls/fdtake if you support this project
