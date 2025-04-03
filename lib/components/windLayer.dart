import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/weatherService.dart';

class WindLayer {
  // Map of wind indicators
  Map<CircleId, Circle> _windCircles = {};

  // Timer for animation
  Timer? _animationTimer;

  // Wind data
  List<WindDirectionData> _windData = [];

  // Animation parameters
  double _animationProgress = 0.0;
  final double _animationSpeed = 0.05; // Controls animation speed

  // Grid parameters (for even distribution of wind indicators)
  final int _gridSize = 5; // 5x5 grid
  late List<GeoPoint> _gridPoints;

  // Map bounds
  LatLngBounds? _mapBounds;

  // Callback to update UI
  final Function(Map<CircleId, Circle>) onWindLayerUpdated;

  WindLayer({required this.onWindLayerUpdated}) {
    // Initial empty state
    _windCircles = {};
  }

  // Initialize the wind layer with map bounds
  void initialize(LatLngBounds bounds) {
    _mapBounds = bounds;
    _createGridPoints();

    // Start wind data updates
    WeatherService.startWindDataUpdates(_gridPoints, _onWindDataUpdated);

    // Start animation
    _startAnimation();
  }

  // Create a grid of points to display wind indicators
  void _createGridPoints() {
    if (_mapBounds == null) return;

    _gridPoints = [];

    final double latDelta = (_mapBounds!.northeast.latitude - _mapBounds!.southwest.latitude) / (_gridSize + 1);
    final double lngDelta = (_mapBounds!.northeast.longitude - _mapBounds!.southwest.longitude) / (_gridSize + 1);

    for (int i = 1; i <= _gridSize; i++) {
      double lat = _mapBounds!.southwest.latitude + (latDelta * i);

      for (int j = 1; j <= _gridSize; j++) {
        double lng = _mapBounds!.southwest.longitude + (lngDelta * j);
        _gridPoints.add(GeoPoint(lat, lng));
      }
    }
  }

  // Handle updated wind data
  void _onWindDataUpdated(List<WindDirectionData> data) {
    _windData = data;
    _updateWindCircles();
  }

  // Update the circles based on current wind data and animation state
  void _updateWindCircles() {
    if (_windData.isEmpty) return;

    Map<CircleId, Circle> newCircles = {};

    for (int i = 0; i < _windData.length; i++) {
      final data = _windData[i];

      // Skip locations with no wind
      if (data.windSpeed < 0.5) continue;

      // Calculate offset based on wind direction and animation progress
      final double directionRadians = (data.windDirection * pi / 180);

      // Scale the distance by wind speed (stronger wind = longer paths)
      final double distanceFactor = min(1.0, data.windSpeed / 20.0); // Cap at wind speed of 10 m/s
      final double maxOffset = 0.002; // Maximum offset in degrees (approx 200m)

      // Create multiple circles to represent wind motion
      final numCircles = 10; // Number of indicators per location

      for (int j = 0; j < numCircles; j++) {
        // Calculate position in animation sequence
        final double individualProgress = (_animationProgress + (j / numCircles)) % 1.0;

        // Calculate the offset for this specific circle
        final double offsetX = maxOffset * individualProgress * distanceFactor * sin(directionRadians);
        final double offsetY = maxOffset * individualProgress * distanceFactor * cos(directionRadians);

        // Calculate the position
        final newLatLng = LatLng(
            data.location.latitude + offsetY,
            data.location.longitude + offsetX
        );

        // Create circle with size based on position in sequence (getting smaller as they "move")
        final double baseRadius = 50.0; // Base radius in meters
        final double circleRadius = baseRadius * (1 - individualProgress * 0.5);

        // Determine color based on wind speed
        Color circleColor;
        if (data.windSpeed < 3) {
          circleColor = Colors.blue.withOpacity(0.4);
        } else if (data.windSpeed < 6) {
          circleColor = Colors.blueAccent.withOpacity(0.5);
        } else {
          circleColor = Colors.indigo.withOpacity(0.6);
        }

        // Create circle
        final circleId = CircleId('wind_${i}_${j}');
        newCircles[circleId] = Circle(
          circleId: circleId,
          center: newLatLng,
          radius: circleRadius,
          fillColor: circleColor,
          strokeWidth: 1,
          strokeColor: circleColor.withOpacity(0.8),
          consumeTapEvents: false,
        );
      }
    }

    _windCircles = newCircles;

    // Notify parent
    onWindLayerUpdated(_windCircles);
  }

  // Start animation timer
  void _startAnimation() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _animationProgress = (_animationProgress + _animationSpeed) % 1.0;
      _updateWindCircles();
    });
  }

  // Update map bounds when map moves
  void updateBounds(LatLngBounds bounds) {
    _mapBounds = bounds;
    _createGridPoints();

    // Restart wind data updates with new grid points
    WeatherService.startWindDataUpdates(_gridPoints, _onWindDataUpdated);
  }

  // Clean up resources
  void dispose() {
    _animationTimer?.cancel();
    WeatherService.stopWindDataUpdates();
    _windCircles.clear();
    onWindLayerUpdated({});
  }

  // Get current wind circles
  Map<CircleId, Circle> getWindCircles() {
    return _windCircles;
  }
}