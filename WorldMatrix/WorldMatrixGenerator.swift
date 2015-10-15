//
//  WorldMatrixGenerator.swift
//  WorldMatrix
//
//  Created by Alexandre Joly on 15/10/15.
//  Copyright © 2015 KiloKilo GmbH. All rights reserved.
//

import UIKit
import MapKit

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

