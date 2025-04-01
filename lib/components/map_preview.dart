import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPreview extends StatefulWidget {
  final GeoPoint? location;
  final double? elevation;

  const MapPreview({
    Key? key,
    this.location,
    this.elevation,
  }) : super(key: key);

  @override
  MapPreviewState createState() => MapPreviewState();
}

class MapPreviewState extends State<MapPreview> {
  late GeoPoint _location;
  late double _elevation;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _location = widget.location ?? GeoPoint(0, 0);
    _elevation = widget.elevation ?? 0;
  }

  void updateLocation(GeoPoint newLocation) {
    setState(() {
      _location = newLocation;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_location.latitude, _location.longitude),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: _elevation,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _location.latitude,
                  _location.longitude,
                ),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('taskLocation'),
                  position: LatLng(
                    _location.latitude,
                    _location.longitude,
                  ),
                ),
              },
              scrollGesturesEnabled: false,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: false,
              liteModeEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

