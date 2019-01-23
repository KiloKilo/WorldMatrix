# WorldMatrix

[![Cocoapods Version](https://img.shields.io/cocoapods/v/WorldMatrix.svg)](https://github.com/KiloKilo/WorldMatrix)
[![Cocoapods Platform](https://img.shields.io/cocoapods/p/WorldMatrix.svg)](https://github.com/KiloKilo/WorldMatrix)
[![Analytics](https://ga-beacon.appspot.com/UA-63588420-2/WorldMatrix)](https://github.com/KiloKilo/WorldMatrix)

`WorldMatrix` is an iOS library writen in Swift 4.2 which allows you to draw a map with dots.

![Screenshot](https://raw.github.com/KiloKilo/WorldMatrix/master/screenshot.png)

## Installation

### CocoaPods

The easiest way to install `WorldMatrix` is using [CocoaPods](http://cocoapods.org/). Add the following dependency to your `Podfile` and run the `pod install` command via command line:

```bash
pod 'WorldMatrix', '~> 4.2.0'
```

## Usage

```swift
// worldArray can be generated with the generator (see `Generate a map)
var worldArray:Array<WorldCharacteristic> = []

let matrix = Matrix<WorldCharacteristic>(columns: 100, array: worldArray)
    worldMatrixView.mapMatrix = matrix

```

### Generate a map

Add the generator to your `Podfile`

```bash
pod 'WorldMatrix/Generator', '~> 4.2.0'
```

Generate a Matrix with you desired cutting

```swift
let generator = WorldMatrixGenerator()

// Set the number of columns per rows (Default: 100)
generator.columns = 20

// Set your desired map cutting (Default: .world)
// use .custom(north, east, south, west) for a custom bounding
generator.mapCutting = .europe

// Set the output type (.enum, .ascii, .emoji) (Default: .enum)
generator.exportType = .enum

// Generates the world array
generator.generate()
```

## Demo

Clone this repository. Open the resulting xcode file. `Run` the the regarding build schema to start the demo app in the iPhone or iPad simulator.

## TODO

-   [ ] Handle reverse geo code errors

## License

See the [LICENSE](LICENSE.md) file for license rights and limitations (MIT).
