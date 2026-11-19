# FxCore SDK Examples

Sample plug-ins for FxCore built with the FxCore SDK.

## Description

Learn various techniques to better create your own plug-ins for FxCore:
- How to render content using Metal
- How to wrap custom Core Image kernels in a plug-in
- How to support new file formats

## Getting Started

### Dependencies

* macOS 15.6
* Xcode 26 (Xcode 27.2 recommended)
* FxCore SDK

### Installing

* Download the FxCore installer directly from its landing page: https://fxfactory.com/info/fxcore/
* ...or install FxFactory first, then download FxCore from its catalog: https://fxfactory.com/download/

### Debugging

While the project is set up to launch the FxCore.app, Xcode won't be able to attach to that process because the app initially lacks the entitlements that would make it debuggable. This can be addressed by:
1. Extracting the app’s current entitlements.
2. Adding entitlements to make the app debuggable.
3. Codesigning the app, with its new entitlements, to run locally.

In Terminal:
```
codesign --display --entitlements entitlements.plist --xml /Applications/FxCore.app
plutil -replace com\\.apple\\.security\\.cs\\.disable-library-validation -bool true entitlements.plist
plutil -replace com\\.apple\\.security\\.cs\\.allow-unsigned-executable-memory -bool true entitlements.plist
plutil -replace com\\.apple\\.security\\.get-task-allow -bool true entitlements.plist
plutil -replace com\\.apple\\.security\\.cs\\.allow-dyld-environment-variables -bool true entitlements.plist
sudo codesign --force --options runtime --sign - --entitlements entitlements.plist /Applications/FxCore.app
rm -Rf entitlements.plist
```

## Authors

Gabriele de Simone  
[@gds](https://x.com/gds)

## Version History

* 1.0
	* Initial Release

## Acknowledgments

FxCore and its SDK are heavily inspired by Quartz Composer, a now-deprecated graphics framework and development tool included by Apple with macOS.
