//
//  mapMatrixViewController.swift
//  mapMatrix
//
//  Created by Alexandre Joly on 14/10/15.
//  Copyright © 2015 KiloKilo GmbH. All rights reserved.
//

import UIKit
import MapKit

public enum WorldCharacteristic: CustomStringConvertible {
    case Land
    case Ocean
    case InlandWater
    case Marker
    case Unknown

    public var description: String {
        switch self {
        case Land:
            return "🔶"
        case Ocean:
            return "🔵"
        case InlandWater:
            return "🔹"
        case Marker:
            return "⚫️"
        case Unknown:
            return "✖️"
        }
    }
}

typealias BoundingBox = (topLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D)

public enum MapCutting {
    case World //85.0,-180.0,-85.0,180.0
    case Europe //82.7,-28.0,33.9,74.1
    case Africa //37.96,-26.59,-37.53,60.56
    case NorthAmerica //85.42,177.15,5.57,-4.05
    case SouthAmerica //13.08,-93.98,-56.55,-32.59
    case Australia //-9.22,112.92,-54.78,159.26
    case Custom(north:Double, west:Double, south:Double, east:Double)

    func boundingCoordinates() -> BoundingBox {
        switch self {
        case World:
            return MapCutting.Custom(north: 85, west: -179.99, south: -85, east: 180).boundingCoordinates()
        case Europe:
            return MapCutting.Custom(north: 82.7, west: -28.0, south: 33.9, east: 74.1).boundingCoordinates()
        case Africa:
            return MapCutting.Custom(north: 37.96, west: -26.59, south: -37.53, east: 60.56).boundingCoordinates()
        case NorthAmerica:
            return MapCutting.Custom(north: 85.42, west: 177.15, south: 5.57, east: -4.05).boundingCoordinates()
        case SouthAmerica:
            return MapCutting.Custom(north: 13.08, west: -93.98, south: -56.55, east: -32.59).boundingCoordinates()
        case Australia:
            return MapCutting.Custom(north: -9.22, west: 112.92, south: -54.78, east: 159.26).boundingCoordinates()
        case Custom(let north, let west, let south, let east):
            return (CLLocationCoordinate2DMake(north, west), CLLocationCoordinate2DMake(south, east))
        }

    }

}


public class WorldMatrixView: UIView {

    // MARK: - Public

    public var mapMatrix: Matrix<WorldCharacteristic>? {
        didSet {
            createMatrixFrames()
            saveMapPNGWithCpmpletionBlock(reloadMapImage)
        }
    }

    public var matrixGap:CGFloat = 1.0
    public var mapCutting:MapCutting?

    dynamic public var oceanColor: UIColor = UIColor.clearColor()
    dynamic public var inlandWaterColor: UIColor = UIColor.whiteColor()
    dynamic public var landColor: UIColor = UIColor.whiteColor()
    dynamic public var markerColor: UIColor = UIColor.blackColor()


    // MARK: - Private

    private var dotMatrix: Matrix<CGRect>?

    private var mapImageView: UIImageView

    private let cachesURL = NSFileManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first!
    var fileURL:NSURL {
        get {
            let scale = Int(UIScreen.mainScreen().scale)
            var fileName = "MapMatrix"
            if scale > 1 { fileName += "@\(scale)x" }
            fileName += ".png"

            return cachesURL.URLByAppendingPathComponent(fileName)
        }
    }

    public override init(frame: CGRect) {
        mapImageView = UIImageView()

        super.init(frame: frame)

        self.addSubview(mapImageView)

    }

    required public init?(coder aDecoder: NSCoder) {
        mapImageView = UIImageView()

        super.init(coder: aDecoder)

        self.addSubview(mapImageView)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        mapImageView.backgroundColor = UIColor.clearColor()
        mapImageView.frame = self.bounds
        mapImageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        mapImageView.contentMode = .ScaleAspectFit

        reloadMapImage()

    }

    private func reloadMapImage() {
        if NSFileManager().fileExistsAtPath(fileURL.path!) {
            dispatch_async(dispatch_get_main_queue()) {
                self.mapImageView.image = UIImage(contentsOfFile: self.fileURL.path!)
            }
        }
    }


    private func saveMapPNGWithCpmpletionBlock(completionBlock: (() -> Void)) {
        guard let dotMatrix = dotMatrix else { return }

        let lastFrame = dotMatrix.last()!
        let size = CGSizeMake(CGRectGetMaxX(lastFrame) + matrixGap, CGRectGetMaxY(lastFrame) + matrixGap)
        let scale = UIScreen.mainScreen().scale

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {


            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            let context = UIGraphicsGetCurrentContext()

            defer { UIGraphicsEndImageContext() }

            for (row, column, frame) in dotMatrix {
                var color = UIColor.clearColor()

                switch self.mapMatrix![row, column] {
                case .Ocean:
                    color = self.oceanColor
                case .InlandWater:
                    color = self.inlandWaterColor
                case .Land:
                    color = self.landColor
                case .Marker:
                    color = self.markerColor
                default:
                    color = UIColor.clearColor()

                }
                CGContextSetFillColorWithColor(context, color.CGColor)
                CGContextFillEllipseInRect(context, frame)
            }


            do {
                let mapImg = UIGraphicsGetImageFromCurrentImageContext()
                let mapData = UIImagePNGRepresentation(mapImg)

                try mapData!.writeToURL(self.fileURL, options: .AtomicWrite)

                completionBlock()
            } catch {
                print(error)
            }

        })
        
    }
    
    private func createMatrixFrames() {
        
        guard let mapMatrix = mapMatrix else { return }

        dotMatrix = Matrix<CGRect>(rows: mapMatrix.rows, columns: mapMatrix.columns, repeatedValue: CGRectZero)

        let dotSize:CGFloat = CGRectGetWidth(self.frame) / CGFloat(mapMatrix.columns) - matrixGap

        for (row, column, _) in mapMatrix {

            var frame = CGRectZero
            frame.origin.x = CGFloat(column) * (dotSize + matrixGap)
            frame.origin.y = CGFloat(row) * (dotSize + matrixGap)
            frame.size.width = dotSize
            frame.size.height = dotSize

            dotMatrix![row, column] = frame
        }

    }

    public func setCharacteristic(characteristic:WorldCharacteristic, forCoordinates coordinates:[CLLocationCoordinate2D]) {
        guard let mapCutting = mapCutting else {
            assertionFailure("mapCutting cannot be nil")
            return
        }

        guard let mapMatrix = mapMatrix else {
            assertionFailure("mapMatrix cannot be nil")
            return
        }


        let bottomRightPoint = MKMapPointForCoordinate(mapCutting.boundingCoordinates().bottomRight)
        let topLeftPoint = MKMapPointForCoordinate(mapCutting.boundingCoordinates().topLeft)

        for coordinate in coordinates {

            guard coordinate.latitude <= mapCutting.boundingCoordinates().topLeft.latitude &&
                coordinate.latitude >= mapCutting.boundingCoordinates().bottomRight.latitude &&
                coordinate.longitude >= mapCutting.boundingCoordinates().topLeft.longitude &&
                coordinate.longitude <= mapCutting.boundingCoordinates().bottomRight.longitude else {
                    assertionFailure("coordinate must be within your map cutting")
                    return
            }

            var width:Double = bottomRightPoint.x - topLeftPoint.x

            if topLeftPoint.x > bottomRightPoint.x {
                width += MKMapPointForCoordinate(CLLocationCoordinate2DMake(mapCutting.boundingCoordinates().topLeft.latitude, 180)).x
            }

            let matrixFieldSize = Double(width) / Double(mapMatrix.columns)

            let pointToChange = MKMapPointForCoordinate(coordinate)
            let columnToChange = Int((pointToChange.x - topLeftPoint.x) / matrixFieldSize)
            let rowToChange = Int((pointToChange.y - topLeftPoint.y) / matrixFieldSize)
            
            self.mapMatrix![rowToChange, columnToChange] = characteristic
        }

        saveMapPNGWithCpmpletionBlock(reloadMapImage)

    }

    public func setCharacteristic(characteristic:WorldCharacteristic, forCoordinate coordinate:CLLocationCoordinate2D) {
        setCharacteristic(characteristic, forCoordinates: [coordinate])
    }

}
