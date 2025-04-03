import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/weatherService.dart';

class WindLayer {
  // Map of wind indicators
  Map<CircleId, Circle> _windCircles = {};
  Map<PolygonId, Polygon> _windFlowPolygons = {};

  // Timer for animation
  Timer? _animationTimer;

  // Wind data
  List<WindDirectionData> _windData = [];
  WindRegionData? _regionWindData;

  // Animation parameters
  double _animationProgress = 0.0;
  final double _animationSpeed = 0.05; // Controls animation speed

  // Grid parameters
  final int _gridSize = 5; // 5x5 grid
  late List<GeoPoint> _gridPoints;

  // Map bounds
  LatLngBounds? _mapBounds;

  // Visualization mode
  bool _useStreamlines = true; // Use streamlines instead of particles

  // Callbacks
  final Function(Map<CircleId, Circle>) onCirclesUpdated;
  final Function(Map<PolygonId, Polygon>) onPolygonsUpdated;

  WindLayer({
    required this.onCirclesUpdated,
    required this.onPolygonsUpdated,
  }) {
    // Initial empty state
    _windCircles = {};
    _windFlowPolygons = {};
  }

  // Initialize the wind layer with map bounds
  void initialize(LatLngBounds bounds) {
    _mapBounds = bounds;
    _createGridPoints();

    // Start wind data updates
    WeatherService.startWindDataUpdates(_gridPoints, _onWindDataUpdated);

    // Get regional wind data for streamlines
    _fetchRegionalWindData();

    // Start animation
    _startAnimation();
  }

  // Fetch regional wind data
  Future<void> _fetchRegionalWindData() async {
    if (_mapBounds == null) return;
    _regionWindData = await WeatherService.getRegionalWindData(_mapBounds!);
    _updateStreamlines();
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

  // Update visualization based on mode
  void updateVisualizationMode(bool useStreamlines) {
    _useStreamlines = useStreamlines;
    if (_useStreamlines) {
      _fetchRegionalWindData();
    } else {
      _updateWindCircles();
    }
  }

  // Update the circles based on current wind data and animation state
  void _updateWindCircles() {
    if (_windData.isEmpty || _useStreamlines) {
      onCirclesUpdated({});
      return;
    }

    Map<CircleId, Circle> newCircles = {};

    for (int i = 0; i < _windData.length; i++) {
      final data = _windData[i];

      // Skip locations with no wind
      if (data.windSpeed < 0.5) continue;

      // Calculate offset based on wind direction and animation progress
      final double directionRadians = (data.windDirection * pi / 180);

      // Scale the distance by wind speed (stronger wind = longer paths)
      final double distanceFactor = min(1.0, data.windSpeed / 20.0); // Cap at wind speed of 20 m/s
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
        } else if (data.windSpeed < 10) {
          circleColor = Colors.indigo.withOpacity(0.6);
        } else {
          circleColor = Colors.purple.withOpacity(0.7);
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
    onCirclesUpdated(_windCircles);
  }

  // Update streamlines from regional wind data
  void _updateStreamlines() {
    if (_regionWindData == null || !_useStreamlines || _regionWindData!.windGrid.isEmpty) {
      onPolygonsUpdated({});
      return;
    }

    Map<PolygonId, Polygon> newPolygons = {};

    // Create streamlines from grid data
    // This is a simplified example - real streamline generation is more complex
    final int gridRows = _regionWindData!.windGrid.length;
    final int gridCols = _regionWindData!.windGrid[0].length;

    // Step size for streamlines
    final int stepSize = 2;

    // Create streamlines for a subset of grid points
    for (int i = 0; i < gridRows; i += stepSize) {
      for (int j = 0; j < gridCols; j += stepSize) {
        if (i >= _regionWindData!.windGrid.length ||
            j >= _regionWindData!.windGrid[i].length ||
            i >= _regionWindData!.windDirectionGrid.length ||
            j >= _regionWindData!.windDirectionGrid[i].length) {
          continue;
        }

        final double windSpeed = _regionWindData!.windGrid[i][j];
        final double windDirection = _regionWindData!.windDirectionGrid[i][j];

        // Skip points with very low wind speed
        if (windSpeed < 1.0) continue;

        // Generate streamline path for this point
        final List<LatLng> streamline = _generateStreamline(i, j, gridRows, gridCols);

        // Skip if streamline is too short
        if (streamline.length < 3) continue;

        // Determine color based on wind speed
        Color polygonColor;
        if (windSpeed < 5) {
          polygonColor = Colors.blue.withOpacity(0.4);
        } else if (windSpeed < 10) {
          polygonColor = Colors.indigo.withOpacity(0.5);
        } else {
          polygonColor = Colors.purple.withOpacity(0.6);
        }

        // Create polygon for this streamline
        final polygonId = PolygonId('streamline_${i}_${j}');
        newPolygons[polygonId] = Polygon(
          polygonId: polygonId,
          points: streamline,
          strokeWidth: 2,
          strokeColor: polygonColor,
          fillColor: Colors.transparent,
          consumeTapEvents: false,
        );
      }
    }

    _windFlowPolygons = newPolygons;
    onPolygonsUpdated(_windFlowPolygons);
  }

  // Generate a streamline path from a starting grid point
  List<LatLng> _generateStreamline(int startI, int startJ, int gridRows, int gridCols) {
    if (_regionWindData == null || _mapBounds == null) return [];

    List<LatLng> path = [];

    // Convert grid indices to lat/lng
    double latStep = (_mapBounds!.northeast.latitude - _mapBounds!.southwest.latitude) / gridRows;
    double lngStep = (_mapBounds!.northeast.longitude - _mapBounds!.southwest.longitude) / gridCols;

    // Starting point
    double lat = _mapBounds!.southwest.latitude + (startI * latStep);
    double lng = _mapBounds!.southwest.longitude + (startJ * lngStep);

    // Add starting point to path
    path.add(LatLng(lat, lng));

    // Track current position in grid
    int currI = startI;
    int currJ = startJ;

    // Generate streamline by following wind vectors
    for (int step = 0; step < 20; step++) {  // Limit to 20 steps max
      if (currI < 0 || currI >= gridRows || currJ < 0 || currJ >= gridCols) break;

      // Get wind data at current position
      double windSpeed = _regionWindData!.windGrid[currI][currJ];
      double windDir = _regionWindData!.windDirectionGrid[currI][currJ] * (pi / 180);  // Convert to radians

      // Calculate movement vector
      double stepSize = 0.5;  // Adjust for density of streamlines
      double dX = stepSize * sin(windDir);
      double dY = stepSize * cos(windDir);

      // Move point based on wind
      lng += dX * lngStep;
      lat += dY * latStep;

      // Update current grid position
      currI = ((lat - _mapBounds!.southwest.latitude) / latStep).floor();
      currJ = ((lng - _mapBounds!.southwest.longitude) / lngStep).floor();

      // Add point to path
      path.add(LatLng(lat, lng));

      // Stop if wind is very weak
      if (windSpeed < 0.5) break;
    }

    return path;
  }

  // Start animation timer
  void _startAnimation() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _animationProgress = (_animationProgress + _animationSpeed) % 1.0;

      if (_useStreamlines) {
        // For streamlines, we just need to update occasionally
        if (_animationProgress < _animationSpeed) {
          _updateStreamlines();
        }
      } else {
        // For particle animation, update every frame
        _updateWindCircles();
      }
    });
  }

  // Update map bounds when map moves
  void updateBounds(LatLngBounds bounds) {
    _mapBounds = bounds;
    _createGridPoints();

    // Restart wind data updates with new grid points
    WeatherService.startWindDataUpdates(_gridPoints, _onWindDataUpdated);

    // Fetch new regional data for streamlines
    _fetchRegionalWindData();
  }

  // Toggle between visualization types
  void toggleVisualizationMode() {
    _useStreamlines = !_useStreamlines;

    if (_useStreamlines) {
      _fetchRegionalWindData();
      onCirclesUpdated({});  // Clear circles
    } else {
      _updateWindCircles();
      onPolygonsUpdated({});  // Clear polygons
    }
  }

  // Clean up resources
  void dispose() {
    _animationTimer?.cancel();
    WeatherService.stopWindDataUpdates();
    _windCircles.clear();
    _windFlowPolygons.clear();
    onCirclesUpdated({});
    onPolygonsUpdated({});
  }
}