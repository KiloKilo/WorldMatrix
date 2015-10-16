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

    public var mapMatrix: Matrix<WorldCharacteristic>? {
        didSet {
            createMatrixViews()
            setNeedsLayout()
        }
    }
    private var viewMatrix: Matrix<WorldDotView>?

    public var matrixGap:CGFloat = 1.0
    public var mapCutting:MapCutting?


    private func createMatrixViews() {

        if viewMatrix?.count > 0 {
            for (_, _, view) in viewMatrix! {
                view.removeFromSuperview()
            }
        }

        guard let mapMatrix = mapMatrix else { return }

        viewMatrix = Matrix<WorldDotView>(rows: mapMatrix.rows, columns: mapMatrix.columns, repeatedValue: WorldDotView())

        for (row, column, worldCharacteristic) in mapMatrix {

            let view = WorldDotView()
            viewMatrix![row, column] = view
            view.characteristic = worldCharacteristic

            self.addSubview(view)

        }

    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        guard let viewMatrix = viewMatrix else { return }

        let dotSize:CGFloat = min(CGRectGetHeight(self.frame), CGRectGetWidth(self.frame)) / CGFloat(viewMatrix.columns) - matrixGap

        for (row, column, view) in viewMatrix {
            var frame = CGRectZero
            frame.origin.x = CGFloat(column) * (dotSize + matrixGap)
            frame.origin.y = CGFloat(row) * (dotSize + matrixGap)
            frame.size.width = dotSize
            frame.size.height = dotSize

            view.frame = frame
        }

    }

    func setCharacteristic(characteristic:WorldCharacteristic, forCoordinate coordinate:CLLocationCoordinate2D) {

        guard let mapCutting = mapCutting else {
            assertionFailure("mapCutting cannot be nil")
            return
        }

        guard let viewMatrix = viewMatrix else {
            assertionFailure("viewMatrix cannot be nil")
            return
        }


        let bottomRightPoint = MKMapPointForCoordinate(mapCutting.boundingCoordinates().bottomRight)
        let topLeftPoint = MKMapPointForCoordinate(mapCutting.boundingCoordinates().topLeft)

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

        let matrixFieldSize = Double(width) / Double(viewMatrix.columns)

        let pointToChange = MKMapPointForCoordinate(coordinate)
        let columnToChange = Int((pointToChange.x - topLeftPoint.x) / matrixFieldSize)
        let rowToChange = Int((pointToChange.y - topLeftPoint.y) / matrixFieldSize)

        viewMatrix[rowToChange, columnToChange].characteristic = characteristic
    }


    // MARK: - Default world dots

    class WorldDotView: UIView {
        var characteristic: WorldCharacteristic = .Ocean {
            didSet {
                setNeedsLayout()
            }
        }

        override func layoutSubviews() {
            self.layer.cornerRadius = CGRectGetHeight(self.frame) / 2.0

            switch characteristic {
            case .Ocean:
                self.backgroundColor = UIColor.clearColor()
            case .Land, .InlandWater:
                self.backgroundColor = UIColor.whiteColor()
            case .Marker:
                self.backgroundColor = UIColor.blackColor()
            default:
                self.backgroundColor = UIColor.clearColor()
            }

        }
    }

}
