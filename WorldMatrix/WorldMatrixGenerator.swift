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

    var mapCutting:MapCutting = .World {
        didSet {
            computeValues()
        }
    }

    private var topLeftPoint:MKMapPoint {
        get {
            return MKMapPointForCoordinate(mapCutting.boundingCoordinates().topLeft)
        }
    }

    private var bottomRightPoint:MKMapPoint {
        get {
            return MKMapPointForCoordinate(mapCutting.boundingCoordinates().bottomRight)
        }
    }

    private var matrixFieldSize: Double = 100

    private var mapMatrix: Matrix<WorldCharacteristic>?


    let queue = NSOperationQueue()


    override init() {
        super.init()

        computeValues()
    }

    private func computeValues() {

        var width:Double = bottomRightPoint.x - topLeftPoint.x
        let height = bottomRightPoint.y - topLeftPoint.y

        if topLeftPoint.x > bottomRightPoint.x {
            width += MKMapPointForCoordinate(CLLocationCoordinate2DMake(mapCutting.boundingCoordinates().topLeft.latitude, 180)).x
        }


        matrixFieldSize = Double(width) / Double(columns)
        rows = Int(Double(height) / matrixFieldSize)
        mapMatrix = Matrix<WorldCharacteristic>(rows: rows, columns: columns, repeatedValue: .Unknown)
    }

    func generate() {

        queue.maxConcurrentOperationCount = 1

        let exportOp = NSBlockOperation { () -> Void in
            self.export()
        }


        for (row, column, _) in mapMatrix! {

            let mapPoint = MKMapPointMake(topLeftPoint.x + (Double(column) * matrixFieldSize) + (matrixFieldSize/2.0), topLeftPoint.y + (Double(row) * matrixFieldSize) + (matrixFieldSize/2.0))
            let coordinate = MKCoordinateForMapPoint(mapPoint)

            let op = ReverseGeoCodeOperation(location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), completionHandler: { (placemarks, error) -> Void in

                if column == 0 { print("") }

                if let _ = error {
                    self.mapMatrix![row, column] = .Unknown
                    print("x", separator: "", terminator: "")

                    // TODO: Redo the operation
                    sleep(10) //wait and try to minimize the errors

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

            exportOp.addDependency(op)
            self.queue.addOperation(op)
        }

        queue.addOperation(exportOp)

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
        
    }


    class ReverseGeoCodeOperation: NSOperation {

        let location:CLLocation
        let completionHandler:CLGeocodeCompletionHandler

        var isComplete: Bool = false


        init(location: CLLocation, completionHandler: CLGeocodeCompletionHandler) {
            self.location = location
            self.completionHandler = completionHandler

            super.init()

            name = "ReverseGeoCodeOperation"
        }

        override func main() {
            if self.cancelled {
                return
            }

//            sleep(1) // Slow down the requests, otherwise we will get to much errors

            let geoCoder = CLGeocoder()
            geoCoder.reverseGeocodeLocation(self.location) { (placemarks, error) -> Void in
                self.completionHandler(placemarks, error)
                self.isComplete = true
            }

            // yeah I know ... I'm sorry for that
            while !self.isComplete { sleep(1) }
        }

    }
    
    
}

