#
# Prism SDK for iOS.
#
# A source pod over a vendored binary: the wrapper under Sources/ compiles into
# the `PrismSDK` module, and the engine ships as an XCFramework it links. Same
# shape as Package.swift, so an integrator gets the same two modules whichever
# way they install.
#
# The framework is vendored from the checkout, which is what lets a `:git`
# source work: CocoaPods requires every `vendored_frameworks` path to exist in
# the checkout. Once the repository is public, an `:http` source pointing at a
# release zip keeps the binary out of git history. That waits for visibility to
# change, because a release asset behind auth is a plain download CocoaPods
# cannot authenticate.
#
# Not published to CocoaPods trunk. Trunk stops accepting new pods and versions
# on 2 December 2026, and discovery by name is worth little for an SDK whose
# integrators arrive with a key we issued. React Native reads a podspec out of
# node_modules, and native callers can point straight at this file:
#
#   pod 'PrismSDK', :git => 'https://github.com/terrabite-ai/prismsdk-ios.git', :tag => '0.1.0'
#
Pod::Spec.new do |spec|
  spec.name         = 'PrismSDK'
  spec.version      = '0.1.0'
  spec.summary      = 'Battery-aware background location tracking for iOS.'
  spec.description  = <<~DESC
    Add Prism to your app and receive your users' locations, in the foreground
    and the background, with the battery cost you choose. Use it to log routes,
    confirm visits to a place, or react when a user arrives somewhere.
  DESC

  spec.homepage     = 'https://github.com/terrabite-ai/prismsdk-ios'
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }
  spec.author       = { 'Terrabite AI' => 'support@terrabite.ai' }

  spec.platform              = :ios
  spec.ios.deployment_target = '15.0'
  # Matches Package.swift's tools version and the compiler mode the engine's
  # .swiftinterface was emitted for.
  spec.swift_versions        = ['5.9']

  spec.source = {
    :git => 'https://github.com/terrabite-ai/prismsdk-ios.git',
    :tag => spec.version.to_s
  }

  # The wrapper. Same files as the SwiftPM target.
  spec.source_files = 'Sources/PrismSDK/**/*.swift'

  # The engine. Same framework as the SwiftPM binaryTarget.
  spec.vendored_frameworks = 'Frameworks/LocalSDKCore.xcframework'

  # `PrismSDK`, not the pod's default of the same name by accident: the module
  # name is what an integrator types after `import`, so it is pinned.
  spec.module_name  = 'PrismSDK'
  spec.requires_arc = true

  # System frameworks the engine links. Listed so an app that has not already
  # linked them does not fail at the link step with undefined symbols.
  spec.frameworks = 'CoreLocation', 'UIKit', 'Network', 'Security'

  # Emits a module map for the pod, which is what lets Objective-C and mixed
  # projects `@import PrismSDK` and use the generated `PrismSDK-Swift.h`.
  spec.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
