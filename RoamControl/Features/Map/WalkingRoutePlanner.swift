import CoreLocation
import MapKit
import Observation

@MainActor
@Observable
final class WalkingRoutePlanner {
    private(set) var route: MKRoute?
    private(set) var destination: LocationTarget?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private var directions: MKDirections?

    func preview(to target: LocationTarget, from source: LocationTarget? = nil) async -> MKRoute? {
        directions?.cancel()
        route = nil
        destination = target
        errorMessage = nil
        isLoading = true

        let request = MKDirections.Request()
        if let source {
            request.source = MKMapItem(
                location: CLLocation(latitude: source.latitude, longitude: source.longitude),
                address: nil
            )
        } else {
            request.source = .forCurrentLocation()
        }
        request.destination = MKMapItem(
            location: CLLocation(latitude: target.latitude, longitude: target.longitude),
            address: nil
        )
        request.transportType = .walking
        request.requestsAlternateRoutes = false

        let calculation = MKDirections(request: request)
        directions = calculation

        defer {
            if directions === calculation {
                directions = nil
                isLoading = false
            }
        }

        do {
            let response = try await calculation.calculate()
            guard directions === calculation else { return nil }
            guard let preferredRoute = response.routes.first else {
                errorMessage = "未找到前往此目的地的步行路线。"
                return nil
            }

            route = preferredRoute
            return preferredRoute
        } catch is CancellationError {
            return nil
        } catch {
            guard directions === calculation else { return nil }
            errorMessage = "步行路线不可用。请检查定位权限和网络连接，然后重试。"
            return nil
        }
    }

    func clear() {
        directions?.cancel()
        directions = nil
        route = nil
        destination = nil
        isLoading = false
        errorMessage = nil
    }

    func retargetExistingRoute(to target: LocationTarget) {
        guard route != nil else { return }
        destination = target
        errorMessage = nil
    }
}
