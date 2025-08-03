# TextToBand Configuration

To build TextToBand, you need to configure your development team settings:

1. Copy `Config.xcconfig` to `LocalConfig.xcconfig`
2. Open `LocalConfig.xcconfig` and set your `DEVELOPMENT_TEAM` ID
3. You can find your team ID in Xcode under your Apple Developer account

Example:
```
DEVELOPMENT_TEAM = ABC123XYZ4
```

## Gitignore

The `LocalConfig.xcconfig` file is already included in `.gitignore` to keep your team ID private.
