import GoogleMaps

public class NJCircleLine {
    
    let directionAPIKey: String
    var circleColor = UIColor.blue
    
    public init(directionAPIKey: String) {
        self.directionAPIKey = directionAPIKey
    }
    
    public enum DirectionError: Error {
        case invalidParameters
        case networkFailure
        case parseFailure
        case routeNotFound
        case unknown
    }
    
    public enum TravelMode: String {
        case walking = "walking"
        case driving = "driving"
        case bicycling = "bicycling"
    }
    
    struct Constant {
        static let GMSDirectAPIBaseURL = "https://maps.googleapis.com/maps/api/directions/json?"
        static let defaultCameraMargine: CGFloat = 50.0
    }
    
    public func drawDotLine(from source: CLLocationCoordinate2D,
                           to destination: CLLocationCoordinate2D,
                           on mapView: GMSMapView,
                           mode: TravelMode = .walking,
                           moveCamera: Bool = true,
                           completion: ((String, [GMSCircle], Int, Int, DirectionError?) -> ())?) {
        
        let urlString = Constant.GMSDirectAPIBaseURL +
            "origin=\(source.latitude),\(source.longitude)" + "&" +
            "destination=\(destination.latitude),\(destination.longitude)" + "&" +
            "mode=\(mode.rawValue)"  + "&" +
            "key=\(directionAPIKey)"
        
        guard let url = URL(string: urlString) else {
            completion?("", [GMSCircle](), 0, 0, .networkFailure)
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
                completion?("", [GMSCircle](), 0, 0, .networkFailure)
                return
            }
            do {
                if let data = data {
                    let response = try JSONDecoder().decode(GoogleDirectionResponse.self, from: data)
                    let routes = response.routes
                    
                    if (routes.count > 0) {
                        let route = routes[0]
                        DispatchQueue.main.async { [weak self] in
                            if let self = self {
                                let polyLine = route.polyline.points
                                let circles = self.drawDotLineWithPolyString(polyStr: polyLine, on: mapView)
                                if moveCamera {
                                    let bounds = GMSCoordinateBounds(coordinate: source,
                                                                     coordinate: destination)
                                    let margine = Constant.defaultCameraMargine
                                    let update = GMSCameraUpdate.fit(bounds,
                                                                     with: UIEdgeInsets(top: margine,
                                                                                        left: margine,
                                                                                        bottom: margine,
                                                                                        right: margine))
                                    mapView.moveCamera(update)
                                }
                                completion?(polyLine,
                                            circles,
                                            route.totalDistanceAndDuration.0,
                                            route.totalDistanceAndDuration.1,
                                            nil)
                            }
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            completion?("", [GMSCircle](), 0, 0, .routeNotFound)
                        }
                    }
                }
            }
            catch {
                print("Error in parsing: \(error)")
                DispatchQueue.main.async {
                    completion?("", [GMSCircle](), 0, 0, .unknown)
                }
            }
        }.resume()
    }
    
    @discardableResult
    public func drawDotLineWithPolyString(polyStr :String, on mapView: GMSMapView) -> [GMSCircle] {
        guard let path = GMSPath(fromEncodedPath: polyStr) else {
            return [GMSCircle]()
        }
        return paintDotLine(path: path, on: mapView)
    }
    
    @discardableResult
    private func paintDotLine(path: GMSPath, on mapView: GMSMapView) -> [GMSCircle] {
        guard path.count() > 0 else {
            return [GMSCircle]()
        }
        
        // minimum distance that should be between 2 circles
        let intervalDistanceIncrement: Double = 5.0
        var previousCircle: GMSCircle?
        var addedCircles = [GMSCircle]()
        
        // Traverse each path
        for i in 0 ..< path.count() - 1 {
            let start = path.coordinate(at: i)
            let end = path.coordinate(at: i + 1)
            let startLocation = CLLocation(latitude: start.latitude,
                                           longitude: start.longitude)
            let endLocation = CLLocation(latitude: end.latitude,
                                         longitude: end.longitude)
            let pathDistance = endLocation.distance(from: startLocation)
            // Difference between 2 points in each meter
            let intervalLatIncrement = (end.latitude - start.latitude) / pathDistance
            let intervalLngIncrement = (end.longitude - start.longitude) / pathDistance
            
            // Traverse distance between a path
            for intervalDistance in 0 ..< Int(pathDistance) {
                let intervalLat = startLocation.coordinate.latitude + (intervalLatIncrement * Double(intervalDistance))
                let intervalLng = startLocation.coordinate.longitude + (intervalLngIncrement * Double(intervalDistance))
                let circleCoordinate = CLLocationCoordinate2D(latitude: intervalLat, longitude: intervalLng)
                
                if let previousCircle = previousCircle {
                    let circleLocation = CLLocation(latitude: circleCoordinate.latitude,
                                                    longitude: circleCoordinate.longitude)
                    let previousCircleLocation = CLLocation(latitude: previousCircle.position.latitude,
                                                            longitude: previousCircle.position.longitude)
                    let circleDistance = circleLocation.distance(from: previousCircleLocation)
                    if previousCircle.radius * 2 + intervalDistanceIncrement > circleDistance {
                        continue
                    }
                }
                let circle = GMSCircle(position: circleCoordinate, radius: NJCircleLine.calculateCircleRadius(mapView: mapView))
                circle.fillColor = circleColor
                circle.strokeColor = circleColor
                circle.map = mapView
                addedCircles.append(circle)
                previousCircle = circle
            }
        }
        return addedCircles
    }
    
    private static func calculateCircleRadius(mapView: GMSMapView) -> CLLocationDistance {
        let radius = 3 * CLLocationDistance(1/mapView.projection.points(forMeters: 1, at: mapView.camera.target))
        return max(1, radius)
    }
}
