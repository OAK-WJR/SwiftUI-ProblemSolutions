//
//  ContentView.swift
//  GradientPolyline_MapView
//
//  Created by WJR on 3/15/24.
//

//https://stackoverflow.com/questions/78170090/swiftui-gradient-polyline-on-map-view

//https://github.com/OAK-WJR/SwiftUI-ProblemSolutions/tree/43bfa3f58686c0fe0ede63221d5d9f294933913d/GradientPolyline_MapView

import SwiftUI
import MapKit

class GradientPolylineOverlay: NSObject, MKOverlay {
  var coordinate: CLLocationCoordinate2D
  var boundingMapRect: MKMapRect
  var points: [CLLocationCoordinate2D]
  
  init(points: [CLLocationCoordinate2D]) {
    self.points = points
    self.coordinate = points.first ?? CLLocationCoordinate2D()
    self.boundingMapRect = MKMapRect.world
  }
}

class GradientPolylineRenderer: MKOverlayRenderer {
  // Gradient color
  var gradientColors: [UIColor] = [.red, .green, .blue]
  // Ratio of different color gradients
  let colorLocations: [CGFloat] = [0.0, 0.5, 1.0]
  // Gradient direction (horizontal or vertical)
  var isHorizontalGradient: Bool = true
  
  override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
    guard let overlay = self.overlay as? GradientPolylineOverlay else { return }
    
    let path = CGMutablePath()
    for (index, coordinate) in overlay.points.enumerated() {
      let mapPoint = MKMapPoint(coordinate)
      let point = self.point(for: mapPoint)
      if index == 0 {
        path.move(to: point)
      } else {
        path.addLine(to: point)
      }
    }
    
    context.addPath(path)
    context.setLineWidth(5 / zoomScale)
    context.replacePathWithStrokedPath()
    context.clip()
    
    // create CGGradient
    let cgGradientColors = gradientColors.map { $0.cgColor } as CFArray
    guard let gradient = CGGradient(colorsSpace: nil, colors: cgGradientColors, locations: colorLocations) else { return }
    
    // Determine the gradient direction based on isHorizontalGradient
    let startAndEndPoints = determineGradientPoints(for: path.boundingBoxOfPath, isHorizontal: isHorizontalGradient)
    context.drawLinearGradient(gradient, start: startAndEndPoints.start, end: startAndEndPoints.end, options: [])
  }
  
  private func determineGradientPoints(for boundingBox: CGRect, isHorizontal: Bool) -> (start: CGPoint, end: CGPoint) {
    if isHorizontal {
      let start = CGPoint(x: boundingBox.minX, y: boundingBox.midY)
      let end = CGPoint(x: boundingBox.maxX, y: boundingBox.midY)
      return (start, end)
    } else {
      let start = CGPoint(x: boundingBox.midX, y: boundingBox.minY)
      let end = CGPoint(x: boundingBox.midX, y: boundingBox.maxY)
      return (start, end)
    }
  }
}

struct MapView: UIViewRepresentable {
  var points: [CLLocationCoordinate2D]
  
  func makeUIView(context: Context) -> MKMapView {
    MKMapView(frame: .zero)
  }
  
  func updateUIView(_ uiView: MKMapView, context: Context) {
    let overlay = GradientPolylineOverlay(points: points)
    uiView.addOverlay(overlay)
    uiView.delegate = context.coordinator
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, MKMapViewDelegate {
    var parent: MapView
    
    init(_ parent: MapView) {
      self.parent = parent
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      if overlay is GradientPolylineOverlay {
        return GradientPolylineRenderer(overlay: overlay)
      } else {
        return MKOverlayRenderer()
      }
    }
  }
}

struct ContentView: View {
  let points: [CLLocationCoordinate2D] = [
    CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    CLLocationCoordinate2D(latitude: 37.3352, longitude: -122.0322),
    CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
  ]
  
  var body: some View {
    MapView(points: points)
      .edgesIgnoringSafeArea(.all)
  }
}

#Preview {
    ContentView()
}
