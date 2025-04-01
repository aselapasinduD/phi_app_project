// Modified LocationPicker to work with your navigation approach
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:phi_app/components/my_colors.dart';

class LocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng, String?) onLocationSelected;

  const LocationPicker({
    Key? key,
    this.initialLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  _LocationPickerWidgetState createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPicker> {
  late LatLng _selectedLocation;
  GoogleMapController? _mapController;
  bool _isLoading = true;
  String? _address;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? const LatLng(0, 0);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Only get current location if no initial location was provided
      if (widget.initialLocation == null) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });

        // Update map camera position
        _updateCameraPosition(_selectedLocation);
      }

      // Get address for the location
      _getAddressFromLatLng(_selectedLocation);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
  }

  void _updateCameraPosition(LatLng position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: 15,
          ),
        ),
      );
    }
  }

  void _handleLocationSelection(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });

    _getAddressFromLatLng(location);
  }

  void _submitLocation() {
    // Use the callback with both location and address
    widget.onLocationSelected(_selectedLocation, _address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Pop and return just the location to match your existing implementation
              Navigator.pop(context, _selectedLocation);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapToolbarEnabled: true,
                  zoomControlsEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: _handleLocationSelection,
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: _selectedLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      infoWindow: InfoWindow(
                        title: 'Selected Location',
                        snippet: '${_selectedLocation.latitude}, ${_selectedLocation.longitude}',
                      ),
                    )
                  },
                ),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                Positioned(
                  bottom: 40,
                  left: 16,
                  child: FloatingActionButton(
                    onPressed: _getCurrentLocation,
                    tooltip: 'Get Current Location',
                    backgroundColor: MyColors.secondaryColor,
                    child: const Icon(Icons.my_location, color: MyColors.mainColor),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selected Location: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (_address != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Address: $_address',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedLocation);
                    },
                    child: const Text('Confirm Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.secondaryColor,
                      foregroundColor: MyColors.mainColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}