//
//  ViewController.swift
//  NJCircleLine
//
//  Created by Jin Nagumo on 2018/10/25.
//  Copyright © 2018 Jinbass. All rights reserved.
//

import UIKit
import GoogleMaps
import NJCircleLine

class ViewController: UIViewController {
    
    var mapView: GMSMapView!
    var didDraw = false
    
    var travelCircles = [GMSCircle]()
    var travelPath: GMSPath? = nil
    
    var linearCircles = [GMSCircle]()
    var linearPath: GMSPath? = nil
    
    var linearConfig: NJCircleLineConfiguration {
        var config = NJCircleLineConfiguration()
        config.fillColor = UIColor.red
        config.strokeWidth = 2.0
        config.strokeColor = UIColor.white
        config.minimumInterval = 1.0
        config.circleRadius = 10.0
        return config
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGoogleMap()
    }
    
    private func setupGoogleMap() {
        let camera = GMSCameraPosition.camera(withLatitude: 35.451569,
                                              longitude: 139.644449,
                                              zoom: 14.5)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        mapView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        mapView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    func drawLine() {
        let startPoint = CLLocationCoordinate2D(latitude: 35.452006, longitude: 139.641474)
        let endPoint = CLLocationCoordinate2D(latitude: 35.446697, longitude: 139.647305)
        NJCircleLine.drawTravelLine(from: startPoint,
                                    to: endPoint,
                                    on: mapView,
                                    apiKey: Constant.DirectionKey) { [weak self] (path, circles, distance, time, error) in
                self?.travelCircles = circles
                self?.travelPath = path
        }
        
        let point1 = startPoint
        let point2 = endPoint
        
        NJCircleLine.drawLinearLine(points: [point1, point2],
                                    on: mapView,
                                    configuration: linearConfig) { [weak self] (path, circles, distance, time, error) in
            self?.linearCircles = circles
            self?.linearPath = path
        }
    }
}

extension ViewController: GMSMapViewDelegate {
    
    func mapViewDidFinishTileRendering(_ mapView: GMSMapView) {
        if didDraw == false {
            didDraw = true
            drawLine()
        }
    }
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        travelCircles = NJCircleLine.drawDotLine(path: travelPath, on: mapView, previousCircles: travelCircles)
        linearCircles = NJCircleLine.drawDotLine(path: linearPath, on: mapView, previousCircles: linearCircles, configuration: linearConfig)
    }
}


