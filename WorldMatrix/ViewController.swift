//
//  ViewController.swift
//  WorldMatrix
//
//  Created by Alexandre Joly on 12/10/15.
//  Copyright © 2015 KiloKilo GmbH. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {

    var displayScale:CGFloat = 1.0
    var displayOffset:CGPoint = CGPointZero


    @IBOutlet weak var worldImageView: UIImageView!


    var coordinateConverter: AJOCoordinateConverter?

    var dots = [UIView]()

    override func viewDidLoad() {
        super.viewDidLoad()


        let coordinateTopLeft:CLLocationCoordinate2D = CLLocationCoordinate2DMake(90, -180)
        let coordinateBottomRight: CLLocationCoordinate2D = CLLocationCoordinate2DMake(-90, 179.999)

        coordinateConverter = AJOCoordinateConverter(withCoordiantesTopLeft: coordinateTopLeft, bottomRight: coordinateBottomRight, imagesSize: worldImageView.image!.size)



        let matrix = Matrix<Int>(rows: 5, columns: 7, repeatedValue: 0)

        print(matrix.toString())
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        setScaleAndOffset()
        drawDots()
    }

    func setScaleAndOffset() {

        let planImageViewSize = worldImageView.frame.size
        let planImageSize = worldImageView.image!.size

        let widthRatio = planImageViewSize.width / planImageSize.width
        let heightRatio = planImageViewSize.height / planImageSize.height

        displayScale = min(widthRatio, heightRatio)



        if widthRatio < heightRatio {
            displayOffset = CGPointMake(0, (planImageViewSize.height - planImageSize.height * displayScale) / 2);
        } else {
            displayOffset = CGPointMake((planImageViewSize.width - planImageSize.width * displayScale) / 2, 0);
        }

    }

    func drawDots() {
        let nrOfDots:Int = 100
        let dotSize:CGFloat = worldImageView.image!.size.width / CGFloat(nrOfDots)
        let distanceDegreesLatitude:CGFloat = (90 - -90) / CGFloat(nrOfDots)
        let distanceDegreesLongitude:CGFloat = (180 - -180) / CGFloat(nrOfDots)


        var k:Double = 0

        for x in 0..<nrOfDots {
            for y in 0..<nrOfDots {
                let newLocation = CLLocationCoordinate2DMake(Double(-90 + CGFloat(y) * distanceDegreesLatitude), Double(-180.0 + (CGFloat(x) * distanceDegreesLongitude)))
                let newPoint = coordinateConverter!.pointFromCoordinate(newLocation)

                let dot = UIView()
                var dotFrame = CGRectZero
                dotFrame.origin.x = newPoint.x * displayScale + self.displayOffset.x
                dotFrame.origin.y = newPoint.y * displayScale + self.displayOffset.y
                dotFrame.size.width = dotSize
                dotFrame.size.height = dotSize
                dot.frame = dotFrame

                dot.layer.cornerRadius = dotSize/2.0
                dot.backgroundColor = UIColor.brownColor()

                let geoCoder = CLGeocoder()

                self.worldImageView.addSubview(dot)
                dots += [dot]

//                guard x > 10 else { continue }

                let delay = 1.5 * k++ * Double(NSEC_PER_SEC)
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                dispatch_after(time, dispatch_get_main_queue()) {
                    geoCoder.reverseGeocodeLocation(CLLocation(latitude: newLocation.latitude, longitude: newLocation.longitude), completionHandler: { (placemarks, error) -> Void in
                        guard let placemarks = placemarks else {
                            print("\(newLocation): no placemarks - \(error?.localizedDescription)")
                            return
                        }

                        for placemark in placemarks {
                            //                        print("\(placemark.name) - \(placemark.inlandWater) -- \(placemark.ocean)")

                            guard placemark.inlandWater != nil || placemark.ocean != nil else { continue }

                            dot.backgroundColor = UIColor.blueColor()
                            print("\(placemark.name) - \(placemark.inlandWater) -- \(placemark.ocean)")

                        }

                    })

                }

            }
        }
    }

}


typealias AJOGeoAnchor = (latitudeLongitude: CLLocationCoordinate2D, pixel: CGPoint)
typealias AJOGeoAnchorPair = (fromAnchor: AJOGeoAnchor, toAnchor: AJOGeoAnchor)

class AJOCoordinateConverter: NSObject {

    var pixelsPerMeter: CGFloat

    // MARK: - Private
    typealias AJOEastSouthDistance = (east: CLLocationDistance, south: CLLocationDistance)

    private var radiansRotated: Double
    private var fromAnchorMKPoint: MKMapPoint
    private var fromAnchorPlanPoint: CGPoint



    static func metersFromPoint(fromAnchorMKPoint from: MKMapPoint, toPoint to:MKMapPoint) -> AJOEastSouthDistance {
        let metersPerMapPoint = MKMetersPerMapPointAtLatitude(MKCoordinateForMapPoint(from).latitude)

        let eastSouthDistance: AJOEastSouthDistance = (
            east: (to.x - from.x) * metersPerMapPoint,
            south: (to.y - from.y) * metersPerMapPoint
        )

        return eastSouthDistance
    }


    convenience init(withCoordiantesTopLeft topLeft:CLLocationCoordinate2D, bottomRight:CLLocationCoordinate2D, imagesSize:CGSize) {
        let topLeftAnchor:AJOGeoAnchor = (
            latitudeLongitude: topLeft,
            pixel: CGPointZero
        )

        let bottomRightAnchor:AJOGeoAnchor = (
            latitudeLongitude: bottomRight,
            pixel: CGPointMake(imagesSize.width, imagesSize.height)
        )

        let anchorPair: AJOGeoAnchorPair = (
            fromAnchor: topLeftAnchor,
            toAnchor: bottomRightAnchor
        )

        self.init(anchors: anchorPair)
    }


    init(anchors:AJOGeoAnchorPair) {
        // To compute the distance between two geographical co-ordinates, we first need to
        // convert to MapKit co-ordinates...
        self.fromAnchorPlanPoint = anchors.fromAnchor.pixel
        self.fromAnchorMKPoint = MKMapPointForCoordinate(anchors.fromAnchor.latitudeLongitude)

        let toAnchorMKPoint:MKMapPoint = MKMapPointForCoordinate(anchors.toAnchor.latitudeLongitude);

        // ... so that we can use MapKit's helper function to compute distance.
        // this helper function takes into account the curvature of the earth.
        let xDistance:CGFloat = anchors.toAnchor.pixel.x - anchors.fromAnchor.pixel.x;
        let yDistance:CGFloat = anchors.toAnchor.pixel.y - anchors.fromAnchor.pixel.y;

        // Distance between two points in pixels (on the plan image)
        let distanceBetweenPointsMeters:CLLocationDistance = MKMetersBetweenMapPoints(fromAnchorMKPoint, toAnchorMKPoint);
        let distanceBetweenPointsPixels:CGFloat = CGFloat(hypotf(Float(xDistance), Float(yDistance)));

        // This gives us pixels/meter
        pixelsPerMeter = CGFloat(distanceBetweenPointsPixels) / CGFloat(distanceBetweenPointsMeters);

        // Get the 2nd anchor's eastward/southward distance in meters from the first anchor point.
        let hyp = AJOCoordinateConverter.metersFromPoint(fromAnchorMKPoint: fromAnchorMKPoint, toPoint: toAnchorMKPoint)

        // Angle of diagonal to east (in geographic)
        let angleFromEast = atan2(hyp.south, hyp.east);

        // Angle of diagonal horizontal (in plan)
        let angleFromHorizontal = atan2(yDistance, xDistance);

        // Rotation amount from the geographic anchor line segment
        // to the floorplan anchor line segment
        radiansRotated = Double(angleFromHorizontal) - Double(angleFromEast);

        super.init()

    }

    func pointFromCoordinate(coordinates: CLLocationCoordinate2D) -> CGPoint {
        let toFix: AJOEastSouthDistance = AJOCoordinateConverter.metersFromPoint(fromAnchorMKPoint: self.fromAnchorMKPoint, toPoint: MKMapPointForCoordinate(coordinates))

        let pixelsXYInEastSouth: CGPoint = CGPointApplyAffineTransform(CGPointMake(CGFloat(toFix.east), CGFloat(toFix.south)), CGAffineTransformMakeScale(self.pixelsPerMeter, self.pixelsPerMeter))
        var xy = CGPointApplyAffineTransform(pixelsXYInEastSouth, CGAffineTransformMakeRotation(CGFloat(self.radiansRotated)))

        xy.x += self.fromAnchorPlanPoint.x
        xy.y += self.fromAnchorPlanPoint.y
        return xy
    }

}

