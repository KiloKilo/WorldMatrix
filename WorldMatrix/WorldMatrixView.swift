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
