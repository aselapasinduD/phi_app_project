import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:phi_app/components/my_colors.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/geographicInformationSystemService.dart';
// import '../services/weatherService.dart';
// import '../components/windLayer.dart';

class GISPage extends StatefulWidget {
  const GISPage({Key? key}) : super(key: key);

  @override
  _GISPage createState() => _GISPage();
}

class _GISPage extends State<GISPage>{
  final GeographicInformationSystemService _gisService = GeographicInformationSystemService();
  GoogleMapController? _mapController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  bool _useStreamlines = true;

  Map<MarkerId, Marker> _markers = {};
  Map<CircleId, Circle> _densityCircles = {};
  Map<CircleId, Circle> _windCircles = {};
  Map<PolygonId, Polygon> _windPolygons = {};

  bool _showPatients = true;
  bool _showFumigations = true;
  bool _showBreedingSites = true;
  bool _showHeatmap = false;
  bool _showWindDirection = false;

  LatLngBounds? _currentBounds;
  // WindLayer? _windLayer;
  Timer? _boundsUpdateTimer;

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(7.8731, 80.7718),
    zoom: 8.0,
  );

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  @override
  void dispose() {
    // _windLayer?.dispose();
    _boundsUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMapData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final mapData = await _gisService.getAllMapData(_startDate, _endDate);
      _updateMarkers(mapData);

      if (_showHeatmap) {
        await _loadDensityCircles();
      } else {
        setState(() {
          _densityCircles.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading map data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // void _initializeWindLayer() {
  //   print('-----------------------${_currentBounds}-----------------------');
  //   if (_currentBounds != null) {
  //     _windLayer ??= WindLayer(
  //       onCirclesUpdated: _updateWindCircles,
  //       onPolygonsUpdated: _updateWindPolygons,
  //     );
  //     _windLayer!.initialize(_currentBounds!);
  //   }
  // }

  // void _updateWindPolygons(Map<PolygonId, Polygon> polygons) {
  //   setState(() {
  //     _windPolygons = polygons;
  //   });
  // }

  Future<void> _loadDensityCircles() async {
    try {
      final heatMapData = await _gisService.getDengueCasesHeatMap(_startDate, _endDate);
      Map<CircleId, Circle> circles = {};

      for (int i = 0; i < heatMapData.length; i++) {
        final point = heatMapData[i];

        final double weight = point['weight']?.toDouble() ?? 1.0;

        Color circleColor;
        if (weight < 0.3) {
          circleColor = Colors.green.withOpacity(0.5);
        } else if (weight < 0.6) {
          circleColor = Colors.yellow.withOpacity(0.5);
        } else if (weight < 0.8) {
          circleColor = Colors.orange.withOpacity(0.5);
        } else {
          circleColor = Colors.red.withOpacity(0.5);
        }

        final double radius = 50 + (weight * 25); // Between 100m and 250m

        final circleId = CircleId('density_${i}');
        circles[circleId] = Circle(
          circleId: circleId,
          center: LatLng(point['latitude'], point['longitude']),
          radius: radius,
          fillColor: circleColor,
          strokeColor: circleColor.withOpacity(0.8),
          strokeWidth: 1,
        );
      }

      setState(() {
        _densityCircles = circles;
      });
    } catch (e) {
      print('Error loading density circles data: $e');
    }
  }

  // void _updateWindCircles(Map<CircleId, Circle> circles) {
  //   setState(() {
  //     _windCircles = circles;
  //   });
  // }
  //
  // void _toggleWindVisualizationMode() {
  //   setState(() {
  //     _useStreamlines = !_useStreamlines;
  //   });
  //
  //   if (_windLayer != null) {
  //     _windLayer!.updateVisualizationMode(_useStreamlines);
  //   }
  // }

  // void _toggleWindDirection(bool value) {
  //   setState(() {
  //     _showWindDirection = value;
  //   });
  //
  //   if (value) {
  //     _initializeWindLayer();
  //   } else {
  //     _windLayer?.dispose();
  //     setState(() {
  //       _windCircles.clear();
  //       _windPolygons.clear();
  //     });
  //   }
  // }

  void _updateMarkers(Map<String, List<GISMapData>> mapData) {
    Map<MarkerId, Marker> markers = {};

    if (_showPatients) {
      for (var item in mapData['patients'] ?? []) {
        final markerId = MarkerId('patient_${item.id}');
        markers[markerId] = Marker(
          markerId: markerId,
          position: LatLng(item.location.latitude, item.location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Patients: ${item.additionalData['numberOfPatients']}',
            snippet: '${item.address}\n${DateFormat('yyyy-MM-dd').format(item.date)}',
          ),
        );
      }
    }

    if (_showFumigations) {
      for (var item in mapData['fumigations'] ?? []) {
        final markerId = MarkerId('fumigation_${item.id}');
        markers[markerId] = Marker(
          markerId: markerId,
          position: LatLng(item.location.latitude, item.location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: item.title,
            snippet: '${item.address}\n${DateFormat('yyyy-MM-dd').format(item.date)}\n${item.additionalData['isCompleted'] ? 'Completed' : 'Pending'}',
          ),
        );
      }
    }

    if (_showBreedingSites) {
      for (var item in mapData['breeding'] ?? []) {
        final markerId = MarkerId('breeding_${item.id}');
        markers[markerId] = Marker(
          markerId: markerId,
          position: LatLng(item.location.latitude, item.location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: item.title,
            snippet: '${item.address}\n${DateFormat('yyyy-MM-dd').format(item.date)}\n${item.additionalData['legalAction'] ? 'Legal Action Taken' : 'No Legal Action'}',
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Get initial map bounds
    // _mapController!.getVisibleRegion().then((bounds) {
    //   _currentBounds = bounds;
    //   if (_showWindDirection) {
    //     _initializeWindLayer();
    //   }
    // });
  }

  // Future<void> _updateMapBounds() async {
  //   if (_mapController == null) return;
  //
  //   try {
  //     LatLngBounds bounds = await _mapController!.getVisibleRegion();
  //     _currentBounds = bounds;
  //
  //     // Update wind layer if active
  //     if (_showWindDirection && _windLayer != null) {
  //       _windLayer!.updateBounds(bounds);
  //     }
  //   } catch (e) {
  //     print('Error updating map bounds: $e');
  //   }
  // }

  void _showDateRangePicker() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Date Range'),
            content: Container(
              width: double.maxFinite,
              height: 300,
              child: SfDateRangePicker(
                view: DateRangePickerView.month,
                selectionMode: DateRangePickerSelectionMode.range,
                initialSelectedRange: PickerDateRange(_startDate, _endDate),
                maxDate: DateTime.now(),
                onSelectionChanged: (DateRangePickerSelectionChangedArgs args){
                  if (args.value is PickerDateRange) {
                    final PickerDateRange range = args.value;
                    setState(() {
                      _startDate = range.startDate ?? _startDate;
                      _endDate = range.endDate ?? _startDate;
                    });
                  }
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: (){
                  Navigator.of(context).pop();
                  _loadMapData();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    final Set<Circle> allCircles = Set<Circle>();
    allCircles.addAll(_densityCircles.values);
    // allCircles.addAll(_windCircles.values);

    // if (_showWindDirection && !_useStreamlines) {
    //   allCircles.addAll(_windCircles.values);
    // }
    // final Set<Polygon> allPolygons = Set<Polygon>();
    // allPolygons.addAll(_windPolygons.values);

    // if (_showWindDirection && _useStreamlines) {
    //   allPolygons.addAll(_windPolygons.values);
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geographic Information System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialPosition,
            markers: Set<Marker>.of(_markers.values),
            circles: Set<Circle>.of(_densityCircles.values),
            // polygons: allPolygons,
            compassEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapToolbarEnabled: true,
            mapType: MapType.normal,
            // onCameraMove: (CameraPosition position) {
            //   if (_mapController != null) {
            //     _mapController!.getVisibleRegion().then((bounds) {
            //       _currentBounds = bounds;
            //       if (_showWindDirection && _windLayer != null) {
            //         _boundsUpdateTimer?.cancel();
            //         _boundsUpdateTimer = Timer(const Duration(milliseconds: 500), () {
            //           _windLayer!.updateBounds(bounds);
            //         });
            //       }
            //     });
            //   }
            // },
            // onCameraIdle: () {
            //   // Camera movement completed, update bounds now
            //   // _updateMapBounds();
            // },
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Layers',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 130,
                    child: ChoiceChip(
                      label: Center(
                        child: Text('Dengue Patients', style: TextStyle(
                          fontSize: 12,
                          color: _showPatients ? Colors.white : Colors.grey[800]),
                        ),
                      ),
                      selected: _showPatients,
                      selectedColor: Colors.red,
                      checkmarkColor: Colors.white,
                      onSelected: (bool selected) {
                        setState(() {
                          _showPatients = selected;
                        });
                        _loadMapData();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: ChoiceChip(
                      label: Center(
                        child: Text('Fumigations', style: TextStyle(
                          fontSize: 12,
                          color: _showFumigations ? Colors.white : Colors.grey[800]),
                        ),
                      ),
                      selected: _showFumigations,
                      selectedColor: Colors.blueAccent,
                      checkmarkColor: Colors.white,
                      onSelected: (bool selected) {
                        setState(() {
                          _showFumigations = selected;
                        });
                        _loadMapData();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: ChoiceChip(
                      label: Center(
                        child: Text('Breeding Sites', style: TextStyle(
                          fontSize: 12,
                          color: _showBreedingSites ? Colors.white : Colors.grey[800]),
                        ),
                      ),
                      selected: _showBreedingSites,
                      selectedColor: Colors.green,
                      checkmarkColor: Colors.white,
                      onSelected: (bool selected) {
                        setState(() {
                          _showBreedingSites = selected;
                        });
                        _loadMapData();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: ChoiceChip(
                      label: Center(
                        child: Text('Heatmap View', style: TextStyle(fontSize: 12)),
                      ),
                      selected: _showHeatmap,
                      selectedColor: MyColors.secondaryColor,
                      onSelected: (bool selected) {
                        setState(() {
                          _showHeatmap = selected;
                        });
                        _loadMapData();
                      },
                    ),
                  ),
                  // SizedBox(
                  //   width: 130,
                  //   child: ChoiceChip(
                  //     label: Center(
                  //       child: Text('Wind Direction', style: TextStyle(
                  //           fontSize: 12,
                  //           color: _showWindDirection ? Colors.white : Colors.grey[800]),
                  //       ),
                  //     ),
                  //     selected: _showWindDirection,
                  //     selectedColor: Colors.deepPurple,
                  //     checkmarkColor: Colors.white,
                  //     onSelected: (bool selected) {
                  //       _toggleWindDirection(selected);
                  //     },
                  //   ),
                  // ),
                  // SizedBox(
                  //   width: 150,
                  //   child: ChoiceChip(
                  //     label: Text('Wind Direction', style: TextStyle(color: _showWindDirection ? Colors.white : Colors.grey[800])),
                  //     selected: _showWindDirection,
                  //     selectedColor: Colors.indigo,
                  //     checkmarkColor: Colors.white,
                  //     onSelected: _toggleWindDirection,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Date Range',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Legend',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('Dengue Patients'),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.blue, size: 16),
                      SizedBox(width: 4),
                      Text('Fumigations'),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text('Breeding Sites'),
                    ],
                  ),
                  // if (_showWindDirection) const SizedBox(height: 6),
                  // if (_showWindDirection)
                  //   const Text(
                  //     'Wind Direction',
                  //     style: TextStyle(fontWeight: FontWeight.bold),
                  //   ),
                  // if (_showWindDirection) const SizedBox(height: 2),
                  // if (_showWindDirection)
                  // const Row(
                  //   children: [
                  //     Icon(Icons.circle, color: Colors.blue, size: 16),
                  //     SizedBox(width: 4),
                  //     Text('Light Wind'),
                  //   ]
                  // ),
                  if (_showHeatmap) const SizedBox(height: 6),
                  if (_showHeatmap)
                    const Text(
                      'Dengue Density',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  if (_showHeatmap) const SizedBox(height: 2),
                  if (_showHeatmap)
                  const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text('Low'),
                      SizedBox(width: 8),
                      Icon(Icons.circle, color: Colors.yellow, size: 16),
                      SizedBox(width: 4),
                      Text('Medium'),
                      SizedBox(width: 8),
                      Icon(Icons.circle, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('High'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Positioned(
          //   top: 16,
          //   right: 16,
          //   child: Container(
          //     padding: const EdgeInsets.all(6),
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(8),
          //       boxShadow: [
          //         BoxShadow(
          //           color: Colors.black.withOpacity(0.2),
          //           spreadRadius: 1,
          //           blurRadius: 3,
          //           offset: const Offset(0, 3),
          //         ),
          //       ],
          //     ),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       mainAxisSize: MainAxisSize.min,
          //       children:[
          //         Row(
          //           mainAxisSize: MainAxisSize.min,
          //           children: [
          //             const Icon(Icons.wb_sunny, size: 18),
          //             const SizedBox(width: 4),
          //             const Text(
          //               'Weather Info',
          //               style: TextStyle(fontWeight: FontWeight.bold),
          //             ),
          //             const SizedBox(width: 8),
          //             IconButton(
          //               icon: const Icon(Icons.info_outline, size: 16),
          //               onPressed: () => {},
          //               padding: EdgeInsets.zero,
          //               constraints: const BoxConstraints(),
          //               tooltip: 'Weather Information',
          //             ),
          //           ],
          //         ),
          //         const SizedBox(height: 4),
          //         Container(
          //           constraints: const BoxConstraints(maxWidth: 180),
          //           child: const Text(
          //             'Check weather by selecting a location on the map',
          //             style: TextStyle(fontSize: 12),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.refresh),
      //   onPressed: _loadMapData,
      //   tooltip: 'Refresh Data',
      // ),
    );
  }

  // void _showWeatherForecastDialog(LatLng location) async {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   try {
  //     final weatherData = await WeatherService.getWeatherForecast(
  //       GeoPoint(location.latitude, location.longitude),
  //       DateTime.now(),
  //     );
  //
  //     if (!mounted) return;
  //
  //     setState(() {
  //       _isLoading = false;
  //     });
  //
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           title: const Text('Weather Forecast'),
  //           content: SingleChildScrollView(
  //             child: ListBody(
  //               children: <Widget>[
  //                 const Text('Current location:'),
  //                 Text('${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'),
  //                 const SizedBox(height: 16),
  //                 const Text('Forecast:'),
  //                 // Text(weatherData.fullForecast),
  //                 const SizedBox(height: 16),
  //                 Row(
  //                   children: [
  //                     const Icon(Icons.air),
  //                     const SizedBox(width: 8),
  //                     Text(weatherData.windSpeed),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 8),
  //                 Row(
  //                   children: [
  //                     // Transform.rotate(
  //                     //   angle: weatherData.windDirection * 3.14159 / 180,
  //                     //   child: const Icon(Icons.arrow_upward),
  //                     // ),
  //                     const SizedBox(width: 8),
  //                     Text('Wind direction: ${weatherData.windDirection}°'),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 8),
  //                 Row(
  //                   children: [
  //                     const Icon(Icons.water_drop),
  //                     const SizedBox(width: 8),
  //                     Text(weatherData.rainStatus),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //           actions: <Widget>[
  //             TextButton(
  //               child: const Text('Close'),
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error fetching weather data: $e')),
  //     );
  //   }
  // }

}