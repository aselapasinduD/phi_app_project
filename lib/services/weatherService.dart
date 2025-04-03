import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weather/weather.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WeatherService {
  static final WeatherFactory _weatherFactory = WeatherFactory('5a3724da6e42100f6f689e48bb61a5a8');
  static const String _windyComApiKey = 'HaHS5hcq1sNoV2DX3ENgMUwYEMavYojK';
  static const String _windyComBaseUrl = 'https://api.windy.com/api/point-forecast/v2';
  static Timer? _refreshTimer;
  static Function(List<WindDirectionData>)? onWindDataUpdated;

  // Get weather forecast for a specific location and date
  static Future<WeatherData> getWeatherForecast(GeoPoint location, DateTime dateTime) async {
    try {
      final now = DateTime.now();
      final difference = dateTime.difference(now).inDays;

      if (difference > 5) {
        return WeatherData(
          windSpeed: 'Unavailable beyond 5 days forecast',
          windDirection: 'Unavailable',
          windDirectionDegrees: 0.0,
          rainStatus: 'Forecast unavailable',
          isRaining: true,
        );
      }

      // Get 5-day forecast with data points every 3 hours
      final List<Weather> forecasts = await _weatherFactory.fiveDayForecastByLocation(
          location.latitude,
          location.longitude
      );

      // Find forecasts for the requested date
      final targetDate = DateFormat('yyyy-MM-dd').format(dateTime);
      final targetDateForecasts = forecasts.where((forecast) {
        final forecastDate = DateFormat('yyyy-MM-dd').format(forecast.date!);
        return forecastDate == targetDate;
      }).toList();

      if (targetDateForecasts.isEmpty) {
        return WeatherData(
          windSpeed: 'No data available',
          windDirection: 'No data available',
          windDirectionDegrees: 0.0,
          rainStatus: 'No data available',
          isRaining: false,
        );
      }

      // Find the forecast closest to the requested time
      final targetHour = dateTime.hour;
      Weather closestForecast = targetDateForecasts.first;
      int smallestHourDifference = 24;

      for (var forecast in targetDateForecasts) {
        final forecastHour = forecast.date!.hour;
        final hourDifference = (forecastHour - targetHour).abs();

        if (hourDifference < smallestHourDifference) {
          smallestHourDifference = hourDifference;
          closestForecast = forecast;
        }
      }

      // Extract weather data
      final windDirection = closestForecast.windDegree ?? 0;
      final windSpeed = 'Wind speed expected (${closestForecast.windSpeed ?? 0} m/s to ${_getCardinalDirection(windDirection)})';

      // Determine rain status
      String rainStatus;
      bool isRaining;
      if (closestForecast.rainLast3Hours != null && closestForecast.rainLast3Hours! > 0) {
        rainStatus = 'Rain expected (${closestForecast.rainLast3Hours!.toStringAsFixed(1)} mm)';
        isRaining = true;
      } else {
        rainStatus = 'No rain expected';
        isRaining = false;
      }

      // Full forecast description
      final weatherDescription = closestForecast.weatherDescription ?? 'Unknown';
      final temperature = closestForecast.temperature?.celsius ?? 0;
      final fullForecast =
          '${weatherDescription.toUpperCase()}, '
          'Temperature: ${temperature.toStringAsFixed(1)}°C, '
          'Wind: $windSpeed, '
          '$rainStatus';

      return WeatherData(
        windSpeed: windSpeed,
        windDirection: _getCardinalDirection(windDirection),
        windDirectionDegrees: windDirection,
        rainStatus: rainStatus,
        isRaining: isRaining,
      );

    } catch (e) {
      debugPrint('Exception in weather forecast: $e');
      return WeatherData(
          windSpeed: 'Error',
          windDirection: 'Error',
          windDirectionDegrees: 0.0,
          rainStatus: 'Error',
          isRaining: false,
      );
    }
  }

  // Get current wind data for multiple locations
  // static Future<List<WindDirectionData>> getCurrentWindData(List<GeoPoint> locations) async {
  //   List<WindDirectionData> windDataList = [];
  //
  //   try {
  //     for (var location in locations) {
  //       Weather currentWeather = await _weatherFactory.currentWeatherByLocation(
  //           location.latitude,
  //           location.longitude
  //       );
  //
  //       windDataList.add(
  //           WindDirectionData(
  //               location: location,
  //               windSpeed: currentWeather.windSpeed ?? 0,
  //               windDirection: currentWeather.windDegree ?? 0,
  //               lastUpdated: DateTime.now()
  //           )
  //       );
  //     }
  //     return windDataList;
  //   } catch (e) {
  //     debugPrint('Error fetching wind data: $e');
  //     return [];
  //   }
  // }

  // Get wind data for a region (not just points)
  static Future<WindRegionData> getRegionalWindData(LatLngBounds bounds) async {
    print('--------------------------getRegionalWindData--------------------');
    try {
      final response = await http.post(
        Uri.parse('$_windyComBaseUrl/rectangle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_windyComApiKey',
        },
        body: jsonEncode({
          'bbox': [
            bounds.southwest.longitude,
            bounds.southwest.latitude,
            bounds.northeast.longitude,
            bounds.northeast.latitude
          ],
          'model': 'gfs', // Weather forecast model
          'parameters': ['wind'],
          'levels': ['surface'],
          'key': _windyComApiKey,
        }),
      );
      
      print('-----------------------------${response.statusCode}---------------------------');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Parse grid data from Windy API
        final windGrid = data['wind']['surface'];
        final directionGrid = data['windDirection']['surface'];
        
        print('-----------------${windGrid}------------------');

        return WindRegionData(
          windGrid: windGrid,
          windDirectionGrid: directionGrid,
          resolution: data['resolution'],
          bounds: bounds,
          timestamp: DateTime.now(),
        );
      } else {
        debugPrint('Failed to fetch regional wind data: ${response.statusCode}');
        return WindRegionData.empty();
      }
    } catch (e) {
      debugPrint('Error fetching regional wind data: $e');
      return WindRegionData.empty();
    }
  }

  // Update how we start wind data updates to use Windy API
  static void startWindDataUpdates(List<GeoPoint> locations, Function(List<WindDirectionData>) callback) {
    onWindDataUpdated = callback;

    // getWindyData(locations).then((data) {
    //   if (onWindDataUpdated != null) {
    //     onWindDataUpdated!(data);
    //   }
    // });

    _refreshTimer?.cancel();

    // Refresh every 30 minutes
    // _refreshTimer = Timer.periodic(const Duration(minutes: 30), (_) {
    //   getWindyData(locations).then((data) {
    //     if (onWindDataUpdated != null) {
    //       onWindDataUpdated!(data);
    //     }
    //   });
    // });
  }

  // Rest of existing code
  static void stopWindDataUpdates() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    onWindDataUpdated = null;
  }

  // Convert wind degrees to cardinal direction
  static String _getWindDirectionName(double degrees) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    int index = ((degrees + 11.25) % 360 / 22.5).floor();
    return directions[index];
  }

  static String _getCardinalDirection(double degrees) {
    const directions = ['North', 'Northeast', 'East', 'Southeast', 'South', 'Southwest', 'West', 'Northwest'];
    int index = ((degrees + 11.25) % 360 / 44).floor();
    return directions[index];
  }
}

// Class to hold weather data
class WeatherData {
  final String windSpeed;
  final String windDirection;
  final double windDirectionDegrees;
  final String rainStatus;
  final bool isRaining;

  WeatherData({
    required this.windSpeed,
    required this.windDirection,
    required this.windDirectionDegrees,
    required this.rainStatus,
    required this.isRaining,
  });
}

// Class to hold wind direction data for visualization
class WindDirectionData {
  final GeoPoint location;
  final double windSpeed;
  final double windDirection;
  final DateTime lastUpdated;

  WindDirectionData({
    required this.location,
    required this.windSpeed,
    required this.windDirection,
    required this.lastUpdated,
  });
}

// New class for regional wind data
class WindRegionData {
  final List<List<double>> windGrid;
  final List<List<double>> windDirectionGrid;
  final double resolution;
  final LatLngBounds bounds;
  final DateTime timestamp;

  WindRegionData({
    required this.windGrid,
    required this.windDirectionGrid,
    required this.resolution,
    required this.bounds,
    required this.timestamp,
  });

  factory WindRegionData.empty() {
    return WindRegionData(
        windGrid: [],
        windDirectionGrid: [],
        resolution: 0.0,
        bounds: LatLngBounds(southwest: const LatLng(0, 0), northeast: const LatLng(0, 0)),
        timestamp: DateTime.now()
    );
  }
}