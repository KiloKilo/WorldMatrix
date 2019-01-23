//
//  WorldMatrixGenerator.swift
//  WorldMatrix
//
//  Created by Alexandre Joly on 15/10/15.
//  Copyright © 2015 KiloKilo GmbH. All rights reserved.
//

import UIKit
import MapKit

public enum ExportType {
    case `enum`
    case ascii
    case emoji
}

open class WorldMatrixGenerator: NSObject {

    open var columns:Int = 100 {
        didSet {
            computeValues()
        }
    }

    fileprivate var rows:Int = 1

    open var mapCutting:MapCutting = .world {
        didSet {
            computeValues()
        }
    }

    fileprivate var topLeftPoint:MKMapPoint {
        get {
            return MKMapPoint.init(mapCutting.boundingCoordinates().topLeft)
        }
    }

    fileprivate var bottomRightPoint:MKMapPoint {
        get {
            return MKMapPoint.init(mapCutting.boundingCoordinates().bottomRight)
        }
    }

    fileprivate var matrixFieldSize: Double = 100

    fileprivate var mapMatrix: Matrix<WorldCharacteristic>?

    open var exportType: ExportType = .enum


    let queue = OperationQueue()


    override public init() {
        super.init()

        computeValues()
    }

    fileprivate func computeValues() {

        var width:Double = bottomRightPoint.x - topLeftPoint.x
        let height = bottomRightPoint.y - topLeftPoint.y

        if topLeftPoint.x > bottomRightPoint.x {
            width += MKMapPoint.init(CLLocationCoordinate2DMake(mapCutting.boundingCoordinates().topLeft.latitude, 180)).x
        }


        matrixFieldSize = Double(width) / Double(columns)
        rows = Int(Double(height) / matrixFieldSize)
        mapMatrix = Matrix<WorldCharacteristic>(rows: rows, columns: columns, repeatedValue: .unknown)
    }

    open func generate() {

        queue.maxConcurrentOperationCount = 1

        let exportOp = BlockOperation { () -> Void in
            self.export()
        }


        for (row, column, _) in mapMatrix! {

            // it looks like we cannot make more than 50 requests per minutes
            // so we wait until the time is up, and thereby reduce the number of errors
            if (row * column + column) % 51 == 1 {
                let waitOperation = BlockOperation(block: { () -> Void in
                    sleep(10)
                })

                queue.addOperation(waitOperation)
            }


            let mapPoint = MKMapPoint.init(x: topLeftPoint.x + (Double(column) * matrixFieldSize) + (matrixFieldSize/2.0), y: topLeftPoint.y + (Double(row) * matrixFieldSize) + (matrixFieldSize/2.0))
            let coordinate = mapPoint.coordinate

            let op = ReverseGeoCodeOperation(location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), completionHandler: { (placemarks, error) -> Void in

                if column == 0 { print("") }

                if let _ = error {
                    self.mapMatrix![row, column] = .unknown
                    print(self.mapMatrix![row, column].ascii(), separator: "", terminator: "")

                    // TODO: Redo the operation
                    sleep(10) //wait and try to minimize the errors

                    return
                }

                guard let placemarks = placemarks else { return }

                if placemarks[0].inlandWater != nil {
                    self.mapMatrix![row, column] = .inlandWater
                } else if placemarks[0].ocean != nil {
                    self.mapMatrix![row, column] = .ocean
                } else {
                    self.mapMatrix![row, column] = .land
                }
                print(self.mapMatrix![row, column].ascii(), separator: "", terminator: "")

                
            })

            exportOp.addDependency(op)
            self.queue.addOperation(op)
        }

        queue.addOperation(exportOp)

    }

    fileprivate func export() {
        print("")
        print("var mapMatrix = []")

        for (_, column, cell) in self.mapMatrix! {

            if column == 0 {
                print("\tmapMatrix += [", separator: "", terminator: "")
            }

            switch self.exportType {
            case .enum:
                print(".\(cell)", separator: "", terminator: "")
            case .ascii:
                print(cell.ascii(), separator: "", terminator: "")
            case .emoji:
                print(cell.emoji(), separator: "", terminator: "")
            }
            
            if column < (self.mapMatrix!.columns - 1) {
                print(",", separator: "", terminator: "")
            } else if column == (self.mapMatrix!.columns - 1) {
                print("]")
            }
            
        }
        
    }


    class ReverseGeoCodeOperation: Operation {

        let location:CLLocation
        let completionHandler:CLGeocodeCompletionHandler

        var isComplete: Bool = false


        init(location: CLLocation, completionHandler: @escaping CLGeocodeCompletionHandler) {
            self.location = location
            self.completionHandler = completionHandler

            super.init()

            name = "ReverseGeoCodeOperation"
        }

        override func main() {
            if self.isCancelled {
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

