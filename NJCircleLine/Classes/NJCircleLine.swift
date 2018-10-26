import GoogleMaps

public struct NJCircleLineConfiguration {
    private static var defaultColor: UIColor {
        return UIColor(red: 0, green: 118.0/255.0, blue: 1.0, alpha: 1.0)
    }
    public var fillColor = NJCircleLineConfiguration.defaultColor
    public var strokeColor = NJCircleLineConfiguration.defaultColor
    public var strokeWidth: CGFloat = 0.0
    public var circleRadius: CGFloat = 7.0
    public var minimumInterval: Double = 5.0
    
    public init() {}
}

public class NJCircleLine {
    
    /**
     *  $0: path that needs to redraw the same route
     *  $1: painted circles
     *  $2: total distance for a given route returned by Google service. 0 for linear line.
     *  $3: total time for a given route returned by Google service. 0 for linear line.
     *  $4: error if any
     */
    public typealias DrawingCompletiton = (GMSPath?, [GMSCircle], Int, Int, NJCircleLineError?) -> ()
    
    
    public enum NJCircleLineError: Error {
        case invalidParameters
        case networkFailure
        case parseFailure
        case routeNotFound
        case polylineNotDrawable // This should be a google error if it happens
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
    
    public static func drawTravelLine(from start: CLLocationCoordinate2D,
                                      to destination: CLLocationCoordinate2D,
                                      on mapView: GMSMapView,
                                      travelMode: TravelMode = .walking,
                                      moveCamera: Bool = true,
                                      configuration: NJCircleLineConfiguration = NJCircleLineConfiguration(),
                                      apiKey: String,
                                      completion: DrawingCompletiton?) {
        let urlString = Constant.GMSDirectAPIBaseURL +
            "origin=\(start.latitude),\(start.longitude)" + "&" +
            "destination=\(destination.latitude),\(destination.longitude)" + "&" +
            "mode=\(travelMode.rawValue)"  + "&" +
            "key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion?(nil, [GMSCircle](), 0, 0, .networkFailure)
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
                completion?(nil, [GMSCircle](), 0, 0, .networkFailure)
                return
            }
            do {
                if let data = data {
                    let response = try JSONDecoder().decode(GoogleDirectionResponse.self, from: data)
                    let routes = response.routes
                    
                    if (routes.count > 0) {
                        let route = routes[0]
                        DispatchQueue.main.async {
                            if moveCamera {
                                moveCameraCenter(from: start, to: destination, on: mapView)
                            }
                            var pathError: NJCircleLineError? = nil
                            var gmsPath: GMSPath? = nil
                            var circles = [GMSCircle]()
                            if let path = GMSPath(fromEncodedPath: route.polyline.points) {
                                gmsPath = path
                                circles = drawDotLine(path: path, on: mapView, configuration: configuration)
                            } else {
                                pathError = NJCircleLineError.polylineNotDrawable
                            }
                            completion?(gmsPath,
                                        circles,
                                        route.totalDistanceAndDuration.0,
                                        route.totalDistanceAndDuration.1,
                                        pathError)
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            completion?(nil, [GMSCircle](), 0, 0, .routeNotFound)
                        }
                    }
                }
            }
            catch {
                print("Error in parsing: \(error)")
                DispatchQueue.main.async {
                    completion?(nil, [GMSCircle](), 0, 0, .unknown)
                }
            }
            }.resume()
    }
    
    public static func drawLinearLine(points: [CLLocationCoordinate2D],
                                      on mapView: GMSMapView,
                                      moveCamera: Bool = true,
                                      configuration: NJCircleLineConfiguration = NJCircleLineConfiguration(),
                                      completion: DrawingCompletiton?) {
        let path = GMSMutablePath()
        points.forEach { path.add($0) }
        if moveCamera {
            let lats = points.compactMap { $0.latitude }
            let minLat = lats.reduce(99999) { min($0, $1) }
            let maxLat = lats.reduce(0) { max($0, $1) }
            let lngs = points.compactMap { $0.longitude }
            let minLng = lngs.reduce(99999) { min($0, $1) }
            let maxLng = lngs.reduce(0) { max($0, $1) }
            moveCameraCenter(from: CLLocationCoordinate2D(latitude: minLat, longitude: minLng),
                             to: CLLocationCoordinate2D(latitude: maxLat, longitude: maxLng),
                             on: mapView)
        }
        let circles = drawDotLine(path: path, on: mapView, configuration: configuration)
        completion?(path, circles, 0, 0, nil)
        
    }
    
    private static func moveCameraCenter(from start: CLLocationCoordinate2D,
                                         to destination: CLLocationCoordinate2D,
                                         on mapView: GMSMapView) {
        let bounds = GMSCoordinateBounds(coordinate: start,
                                         coordinate: destination)
        let margine = Constant.defaultCameraMargine
        let update = GMSCameraUpdate.fit(bounds,
                                         with: UIEdgeInsets(top: margine,
                                                            left: margine,
                                                            bottom: margine,
                                                            right: margine))
        mapView.moveCamera(update)
    }
    
    @discardableResult
    public static func drawDotLine(path: GMSPath?,
                                   on mapView: GMSMapView,
                                   previousCircles: [GMSCircle]? = nil,
                                   configuration: NJCircleLineConfiguration = NJCircleLineConfiguration()) -> [GMSCircle] {
        guard let path = path, path.count() > 0 else {
            return [GMSCircle]()
        }
        
        // Clear previous circles from map
        previousCircles?.forEach() { $0.map = nil }
        
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
                    if previousCircle.radius * 2 + configuration.minimumInterval > circleDistance {
                        continue
                    }
                }
                let circle = GMSCircle(position: circleCoordinate, radius: calculateCircleRadius(mapView: mapView, circleRadius: configuration.circleRadius))
                circle.fillColor = configuration.fillColor
                circle.strokeColor = configuration.strokeColor
                circle.strokeWidth = configuration.strokeWidth
                circle.map = mapView
                addedCircles.append(circle)
                previousCircle = circle
            }
        }
        return addedCircles
    }
    
    private static func calculateCircleRadius(mapView: GMSMapView, circleRadius: CGFloat) -> CLLocationDistance {
        let metersForOnePoint = 1/mapView.projection.points(forMeters: 1, at: mapView.camera.target)
        return CLLocationDistance(metersForOnePoint * circleRadius)
    }
}
