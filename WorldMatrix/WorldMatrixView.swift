//
//  mapMatrixViewController.swift
//  mapMatrix
//
//  Created by Alexandre Joly on 14/10/15.
//  Copyright © 2015 KiloKilo GmbH. All rights reserved.
//

import UIKit
import MapKit

enum WorldCharacteristic: CustomStringConvertible {
    case Land
    case Ocean
    case InlandWater
    case Marker
    case Unknown

    var description: String {
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

class WorldMatrixView: UIView {

    var mapMatrix: Matrix<WorldCharacteristic>? {
        didSet {
            createMatrixViews()
            setNeedsLayout()
        }
    }
    private var viewMatrix: Matrix<WorldDotView>?

    var matrixGap:CGFloat = 1.0
    var topLeftCoordinate = CLLocationCoordinate2DMake(86, -179.999)
    var bottomRightCoordinate = CLLocationCoordinate2DMake(-82, 180)


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

    override func layoutSubviews() {
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
        // TODO
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
            case .InlandWater, .Ocean:
                self.backgroundColor = UIColor.clearColor()
            case .Land:
                self.backgroundColor = UIColor.whiteColor()
            case .Marker:
                self.backgroundColor = UIColor.blackColor()
            default:
                self.backgroundColor = UIColor.clearColor()
            }

        }
    }

}

class WorldMatrixGenerator: NSObject {

    var columns:Int = 100 {
        didSet {
            computeValues()
        }
    }

    private var rows:Int = 1

    var topLeftCoordinate = CLLocationCoordinate2DMake(86, -179.999)
    var bottomRightCoordinate = CLLocationCoordinate2DMake(-82, 180)

    private var topLeftPoint:MKMapPoint {
        get {
            return MKMapPointForCoordinate(topLeftCoordinate)
        }
    }

    private var bottomRightPoint:MKMapPoint {
        get {
            return MKMapPointForCoordinate(bottomRightCoordinate)
        }
    }

    private var matrixFieldSize: Double = 100

    private var mapMatrix: Matrix<WorldCharacteristic>?


    override init() {
        super.init()

        computeValues()
    }

    private func computeValues() {
        let width = bottomRightPoint.x - topLeftPoint.x
        let height = bottomRightPoint.y - topLeftPoint.y

        matrixFieldSize = Double(width) / Double(columns)
        rows = Int(Double(height) / matrixFieldSize)
        mapMatrix = Matrix<WorldCharacteristic>(rows: rows, columns: columns, repeatedValue: .Unknown)
    }


    func generate() {

        var i = 0
        for (row, column, _) in mapMatrix! {

            let delay = 1.5 * Double(i) * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.reverseGeocodeLocationForRow(row, andColumn: column)
            }

            i++
            
        }

        let d = 1.55 * Double(i) * Double(NSEC_PER_SEC)
        let t = dispatch_time(DISPATCH_TIME_NOW, Int64(d))
        dispatch_after(t, dispatch_get_main_queue()) {
            self.export()
            
        }
    }


    // TODO: move to NSOperation
    func reverseGeocodeLocationForRow(row:Int, andColumn column:Int) {
        let mapPoint = MKMapPointMake(topLeftPoint.x + (Double(column) * matrixFieldSize) + (matrixFieldSize/2.0), topLeftPoint.y + (Double(row) * matrixFieldSize) + (matrixFieldSize/2.0))
        let coordinate = MKCoordinateForMapPoint(mapPoint)


        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), completionHandler: { (placemarks, error) -> Void in

            if column == 0 { print("") }

            if let _ = error {
                self.mapMatrix![row, column] = .Unknown
                print("x", separator: "", terminator: "")

                let delay = 2 * Double(NSEC_PER_SEC)
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                dispatch_after(time, dispatch_get_main_queue()) {
                    self.reverseGeocodeLocationForRow(row, andColumn: column)
                }

                return
            }

            guard let placemarks = placemarks else { return }

            if placemarks[0].inlandWater != nil {
                self.mapMatrix![row, column] = .InlandWater
                print("-", separator: "", terminator: "")
            } else if placemarks[0].ocean != nil {
                self.mapMatrix![row, column] = .Ocean
                print("~", separator: "", terminator: "")
            } else {
                self.mapMatrix![row, column] = .Land
                print(".", separator: "", terminator: "")
            }

        })

    }

    func export() {
        print("")
        print("var mapMatrix = []")

        for (_, column, cell) in self.mapMatrix! {

            if column == 0 {
                print("\tmapMatrix += [", separator: "", terminator: "")
            }

            print("\(cell)", separator: "", terminator: "")

            if column < (self.mapMatrix!.columns - 1) {
                print(",", separator: "", terminator: "")
            } else if column == (self.mapMatrix!.columns - 1) {
                print("]")
            }

        }


//        print(self.mapMatrix!.toString())
    }
    
    
}
