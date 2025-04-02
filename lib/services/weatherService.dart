import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weather/weather.dart';
import 'package:intl/intl.dart';

class WeatherService {
  static final WeatherFactory _weatherFactory = WeatherFactory('5a3724da6e42100f6f689e48bb61a5a8');

  // Get weather forecast for a specific location and date
  static Future<WeatherData> getWeatherForecast(GeoPoint location, DateTime dateTime) async {
    try {
      final now = DateTime.now();
      final difference = dateTime.difference(now).inDays;

      if (difference > 5) {
        return WeatherData(
            windSpeed: 'Not available for dates beyond 5-day forecast',
            rainStatus: 'Forecast unavailable',
            fullForecast: 'Weather data is only available for up to 5 days in the future.'
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
            rainStatus: 'No data available',
            fullForecast: 'No forecast data found for the requested date.'
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
      final windSpeed = 'Wind speed expected (${closestForecast.windSpeed ?? 0} m/s)';

      // Determine rain status
      String rainStatus;
      if (closestForecast.rainLast3Hours != null && closestForecast.rainLast3Hours! > 0) {
        rainStatus = 'Rain expected (${closestForecast.rainLast3Hours!.toStringAsFixed(1)} mm)';
      } else {
        rainStatus = 'No rain expected';
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
          rainStatus: rainStatus,
          fullForecast: fullForecast
      );

    } catch (e) {
      debugPrint('Exception in weather forecast: $e');
      return WeatherData(
          windSpeed: 'Error',
          rainStatus: 'Error',
          fullForecast: 'Failed to fetch weather data: $e'
      );
    }
  }
}

// Class to hold weather data
class WeatherData {
  final String windSpeed;
  final String rainStatus;
  final String fullForecast;

  WeatherData({
    required this.windSpeed,
    required this.rainStatus,
    required this.fullForecast,
  });
}