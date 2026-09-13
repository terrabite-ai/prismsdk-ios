# Day-to-day commands. Mirrors what CI will run, so a green `make test` here
# means a green check there.
#
#   make test        run the mapping tests on a simulator
#   make build       build the wrapper against the vendored engine
#   make lint        validate the podspec (builds the pod for a simulator)
#   make xcframework rebuild Frameworks/LocalSDKCore.xcframework from the engine

# Any iPhone whose runtime is installed. Override on a machine that has a
# different set: make test DESTINATION="platform=iOS Simulator,name=iPhone 16"
DESTINATION ?= platform=iOS Simulator,name=iPhone 17 Pro
WORKSPACE   := prismsdk-ios.xcworkspace
# The shared scheme in .swiftpm/xcode/xcshareddata/xcschemes — it is what
# carries the test action.
SCHEME      := PrismSDK
XC_ARGS     := -workspace $(WORKSPACE) -scheme $(SCHEME) -destination "$(DESTINATION)"

# Path to a checkout of localsdk-ios-core. Required by `make xcframework`.
ENGINE ?=

.PHONY: build test lint clean xcframework

build:
	xcodebuild $(XC_ARGS) build

test:
	xcodebuild $(XC_ARGS) test

clean:
	xcodebuild $(XC_ARGS) clean

# CocoaPods needs a UTF-8 locale or it refuses to run.
lint:
	LANG=en_US.UTF-8 pod lib lint PrismSDK.podspec

# The engine's own script does the archiving, module install and
# -create-xcframework dance; this target only points it at our Frameworks/.
# Build from a clean export of the engine, not its working tree, so what ships
# is what is committed.
xcframework:
	@test -n "$(ENGINE)" || { echo "usage: make xcframework ENGINE=/path/to/localsdk-ios-core"; exit 1; }
	@set -e; \
	  tmp=$$(mktemp -d); \
	  git -C "$(ENGINE)" archive HEAD | tar -x -C "$$tmp"; \
	  cp "$(ENGINE)/Package.resolved" "$$tmp/" 2>/dev/null || true; \
	  ( cd "$$tmp" && bash Scripts/build-xcframework.sh LocalSDKCore "$$tmp/out" ); \
	  rm -rf Frameworks/LocalSDKCore.xcframework; \
	  cp -R "$$tmp/out/LocalSDKCore.xcframework" Frameworks/; \
	  rm -rf "$$tmp"; \
	  echo "Frameworks/LocalSDKCore.xcframework refreshed from $$(git -C "$(ENGINE)" rev-parse --short HEAD)"
