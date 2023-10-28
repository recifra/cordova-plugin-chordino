Build for iOS
```sh
xcodebuild archive \
    -project Chordino.xcodeproj \
    -scheme Chordino \
    -destination "generic/platform=iOS" \
    -archivePath "build/archives/Chordino-iOS" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES
```

Build for iOS Simulator
```sh
xcodebuild archive \
    -project Chordino.xcodeproj \
    -scheme Chordino \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "build/archives/Chordino-iOS_Simulator" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES
```

Build for iOS Simulator
```sh
xcodebuild -create-xcframework \
    -archive build/archives/Chordino-iOS.xcarchive -framework Chordino.framework \
    -archive build/archives/Chordino-iOS_Simulator.xcarchive -framework Chordino.framework \
    -output ../../../../libs/ios/Chordino.xcframework
```
