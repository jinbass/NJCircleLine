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
    let line = NJCircleLine(directionAPIKey: Constant.DirectionKey)
    var circles = [GMSCircle]()
    var polyline = ""
    
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
        circles.forEach() { $0.map = nil }
        let startPoint = CLLocationCoordinate2D(latitude: 35.452006, longitude: 139.641474)
        let endPoint = CLLocationCoordinate2D(latitude: 35.446697, longitude: 139.647305)
        line.drawDotLine(from: startPoint,
                         to: endPoint,
                         on: mapView) { [weak self] (polyLine, circles, distance, time, error) in
                            self?.circles = circles
                            self?.polyline = polyLine
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
        circles.forEach() { $0.map = nil }
        circles = line.drawDotLineWithPolyString(polyStr: polyline, on: mapView)
    }
}


