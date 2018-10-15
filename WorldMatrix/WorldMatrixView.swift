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
    case land
    case ocean
    case inlandWater
    case marker
    case unknown

    public var description: String {
        switch self {
        case .land:
            return "🔶"
        case .ocean:
            return "🔵"
        case .inlandWater:
            return "🔹"
        case .marker:
            return "⚫️"
        case .unknown:
            return "✖️"
        }
    }
}

typealias BoundingBox = (topLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D)

public enum MapCutting {
    case world //85.0,-180.0,-85.0,180.0
    case europe //82.7,-28.0,33.9,74.1
    case africa //37.96,-26.59,-37.53,60.56
    case northAmerica //85.42,177.15,5.57,-4.05
    case southAmerica //13.08,-93.98,-56.55,-32.59
    case australia //-9.22,112.92,-54.78,159.26
    case custom(north:Double, west:Double, south:Double, east:Double)

    func boundingCoordinates() -> BoundingBox {
        switch self {
        case .world:
            return MapCutting.custom(north: 85, west: -179.99, south: -85, east: 180).boundingCoordinates()
        case .europe:
            return MapCutting.custom(north: 82.7, west: -28.0, south: 33.9, east: 74.1).boundingCoordinates()
        case .africa:
            return MapCutting.custom(north: 37.96, west: -26.59, south: -37.53, east: 60.56).boundingCoordinates()
        case .northAmerica:
            return MapCutting.custom(north: 85.42, west: 177.15, south: 5.57, east: -4.05).boundingCoordinates()
        case .southAmerica:
            return MapCutting.custom(north: 13.08, west: -93.98, south: -56.55, east: -32.59).boundingCoordinates()
        case .australia:
            return MapCutting.custom(north: -9.22, west: 112.92, south: -54.78, east: 159.26).boundingCoordinates()
        case .custom(let north, let west, let south, let east):
            return (CLLocationCoordinate2DMake(north, west), CLLocationCoordinate2DMake(south, east))
        }

    }

}


open class WorldMatrixView: UIView {

    // MARK: - Public

    open var mapMatrix: Matrix<WorldCharacteristic>? {
        didSet {
            createMatrixFrames()
            saveMapPNGWithCpmpletionBlock(reloadMapImage)
        }
    }

    open var matrixGap:CGFloat = 1.0
    open var mapCutting:MapCutting?

    @objc dynamic open var oceanColor: UIColor = UIColor.clear
    @objc dynamic open var inlandWaterColor: UIColor = UIColor.white
    @objc dynamic open var landColor: UIColor = UIColor.white
    @objc dynamic open var markerColor: UIColor = UIColor.black


    // MARK: - Private

    fileprivate var dotMatrix: Matrix<CGRect>?

    fileprivate var mapImageView: UIImageView

    fileprivate let cachesURL = FileManager().urls(for: .cachesDirectory, in: .userDomainMask).first!
    var fileURL:URL {
        get {
            let scale = Int(UIScreen.main.scale)
            var fileName = "MapMatrix"
            if scale > 1 { fileName += "@\(scale)x" }
            fileName += ".png"

            return cachesURL.appendingPathComponent(fileName)
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

    override open func layoutSubviews() {
        super.layoutSubviews()

        mapImageView.backgroundColor = UIColor.clear
        mapImageView.frame = self.bounds
        mapImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapImageView.contentMode = .scaleAspectFit

        reloadMapImage()

    }

    fileprivate func reloadMapImage() {
        if FileManager().fileExists(atPath: fileURL.path) {
            DispatchQueue.main.async {
                self.mapImageView.image = UIImage(contentsOfFile: self.fileURL.path)
            }
        }
    }


    fileprivate func saveMapPNGWithCpmpletionBlock(_ completionBlock: @escaping (() -> Void)) {
        guard let dotMatrix = dotMatrix else { return }

        let lastFrame = dotMatrix.last()!
        let size = CGSize(width: lastFrame.maxX + matrixGap, height: lastFrame.maxY + matrixGap)
        let scale = UIScreen.main.scale
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {

            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            let context = UIGraphicsGetCurrentContext()!

            defer { UIGraphicsEndImageContext() }

            for (row, column, frame) in dotMatrix {
                var color = UIColor.clear

                switch self.mapMatrix![row, column] {
                case .ocean:
                    color = self.oceanColor
                case .inlandWater:
                    color = self.inlandWaterColor
                case .land:
                    color = self.landColor
                case .marker:
                    color = self.markerColor
                default:
                    color = UIColor.clear

                }
                context.setFillColor(color.cgColor)
                context.fillEllipse(in: frame)
            }


            do {
                let mapImg = UIGraphicsGetImageFromCurrentImageContext()
                let mapData = mapImg!.pngData()

                try mapData!.write(to: self.fileURL, options: .atomicWrite)

                completionBlock()
            } catch {
                print(error)
            }

        })

    }

    fileprivate func createMatrixFrames() {

        guard let mapMatrix = mapMatrix else { return }

        dotMatrix = Matrix<CGRect>(rows: mapMatrix.rows, columns: mapMatrix.columns, repeatedValue: CGRect.zero)

        let dotSize:CGFloat = self.frame.width / CGFloat(mapMatrix.columns) - matrixGap

        for (row, column, _) in mapMatrix {

            var frame = CGRect.zero
            frame.origin.x = CGFloat(column) * (dotSize + matrixGap)
            frame.origin.y = CGFloat(row) * (dotSize + matrixGap)
            frame.size.width = dotSize
            frame.size.height = dotSize

            dotMatrix![row, column] = frame
        }

    }

    open func setCharacteristic(_ characteristic:WorldCharacteristic, forCoordinates coordinates:[CLLocationCoordinate2D]) {
        guard let mapCutting = mapCutting else {
            assertionFailure("mapCutting cannot be nil")
            return
        }

        guard let mapMatrix = mapMatrix else {
            assertionFailure("mapMatrix cannot be nil")
            return
        }


        let bottomRightPoint = MKMapPoint.init(mapCutting.boundingCoordinates().bottomRight)
        let topLeftPoint = MKMapPoint.init(mapCutting.boundingCoordinates().topLeft)
        var newMapMatrix = mapMatrix

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
                width += MKMapPoint.init(CLLocationCoordinate2DMake(mapCutting.boundingCoordinates().topLeft.latitude, 180)).x
            }

            let matrixFieldSize = Double(width) / Double(mapMatrix.columns)

            let pointToChange = MKMapPoint.init(coordinate)
            let columnToChange = Int((pointToChange.x - topLeftPoint.x) / matrixFieldSize)
            let rowToChange = Int((pointToChange.y - topLeftPoint.y) / matrixFieldSize)

            newMapMatrix[rowToChange, columnToChange] = characteristic
        }

        self.mapMatrix = newMapMatrix

        saveMapPNGWithCpmpletionBlock(reloadMapImage)

    }

    open func setCharacteristic(_ characteristic:WorldCharacteristic, forCoordinate coordinate:CLLocationCoordinate2D) {
        setCharacteristic(characteristic, forCoordinates: [coordinate])
    }

}
