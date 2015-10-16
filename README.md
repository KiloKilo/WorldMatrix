# WorldMatrix

[![Cocoapods Version](https://img.shields.io/cocoapods/v/WorldMatrix.svg)](https://github.com/KiloKilo/WorldMatrix)
[![Cocoapods Platform](https://img.shields.io/cocoapods/p/WorldMatrix.svg)](https://github.com/KiloKilo/WorldMatrix)
[![Analytics](https://ga-beacon.appspot.com/UA-63588420-2/WorldMatrix)](https://github.com/KiloKilo/WorldMatrix)

`WorldMatrix` is an iOS library writen in Swift 2 which allows you to draw a map with dots.

![Screenshot](https://raw.github.com/KiloKilo/WorldMatrix/master/screenshot.png)

## Installation
### CocoaPods
The easiest way to install `WorldMatrix` is using [CocoaPods](http://cocoapods.org/). Add the following dependency to your `Podfile` and run the `pod install` command via command line:

```bash
pod 'WorldMatrix', '~> 1.0.0'
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
pod 'WorldMatrix/Generator', '~> 1.0.0'
```

Generate a Matrix with you desired cutting

```swift
let generator = WorldMatrixGenerator()

// Set the number of columns per rows (Default: 100)
generator.columns = 20

// Set your desired map cutting (Default: .World)
// use .Custom(north, east, south, west) for a custom bounding
generator.mapCutting = .Europe

// Generates the world array
generator.generate()
```

## Demo
Clone this repository. Open the resulting xcode file. `Run` the the regarding build schema to start the demo app in the iPhone or iPad simulator.


## License

Copyright (c) 2015 KiloKilo GmbH

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

