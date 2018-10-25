public struct GoogleDirectionResponse: Codable{
    public let routes: [GoogleRoute]
}

public struct Polyline: Codable {
    public let points: String
}

public struct GoogleRoute: Codable {
    public let legs: [RouteLeg]
    public let polyline: Polyline
    
    enum CodingKeys: String, CodingKey {
        case polyline = "overview_polyline"
        case legs
    }
    
    public var totalDistanceAndDuration: (Int, Int) {
        var distance = 0
        var duration = 0
        for leg in legs {
            distance += leg.distance.value
            duration += leg.duration.value
        }
        return (distance, duration)
    }
}

public struct RouteLeg: Codable {
    public let distance: ValueText
    public let duration: ValueText
}

public struct ValueText: Codable {
    public let value: Int
    public let text: String
}
