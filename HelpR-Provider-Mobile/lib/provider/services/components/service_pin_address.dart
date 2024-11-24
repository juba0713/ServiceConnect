import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class PinLocationScreen extends StatefulWidget {
  @override
  _PinLocationScreenState createState() => _PinLocationScreenState();
}

class _PinLocationScreenState extends State<PinLocationScreen> {
  late GoogleMapController _mapController;
  LatLng? _currentPosition;
  String _address = "Move the map to pin a location";

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      // If permission is granted, fetch the current location
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });

        // Update the address based on the current location
        _onCameraIdle();
      }
    } catch (e) {
      setState(() {
        _address = "Error fetching current location: $e";
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _currentPosition = position.target;
    });
  }

  Future<void> _onCameraIdle() async {
    if (_currentPosition == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _address =
              "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        });
      } else {
        setState(() {
          _address = "No address found for this location.";
        });
      }
    } catch (e) {
      setState(() {
        _address = "Error fetching address: $e";
      });
    }
  }

  void _confirmLocation() {
    if (_currentPosition == null) return;

    Navigator.pop(
      context,
      {
        "address": _address,
        "latitude": _currentPosition!.latitude,
        "longitude": _currentPosition!.longitude,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pin Location')),
      body: Stack(
        children: [
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 14.0,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                ),
          const Center(
            child: Icon(
              Icons.location_pin,
              size: 40,
              color: Colors.red,
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _address,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _confirmLocation,
                  child: const Text("Confirm Location"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
