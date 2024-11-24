import 'dart:async';
import 'dart:math'; // Import math library for distance calculation
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/service_response.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSample extends StatefulWidget {
  final double latitude;
  final double longitude;
  final List<ServiceLocationResponse> serviceLocations;

  const MapSample({super.key, required this.latitude, required this.longitude, required this.serviceLocations});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  late CameraPosition _initialPosition;
  String? _selectedCategory;
  String? _selectedServiceName; // New variable for the selected service name
  ServiceLocationResponse? _nearestService; // To store the nearest service

  @override
  void initState() {
    super.initState();
    _initialPosition = CameraPosition(
      target: LatLng(widget.latitude, widget.longitude),
      zoom: 14.4746,
    );

    _selectedCategory = "All Categories";
  }

  // Function to calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double degree) {
    return degree * pi / 180;
  }

  // Define _goToTheLake method before the build method
  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;

    // Print current location to debug
    print("Moving camera to: Lat: ${widget.latitude}, Lng: ${widget.longitude}");

    // Move the camera to the current location
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(widget.latitude, widget.longitude),
      zoom: 19.151926040649414,
    )));
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {};

    // Extract category names from the serviceLocations
    List<String> categoryNames = widget.serviceLocations
        .map((service) => service.categoryName ?? "Unknown Category")
        .toSet()  // Remove duplicates
        .toList();

    // Add a "All Categories" option
    categoryNames.insert(0, "All Categories");

    // Filtered service names based on selected category
    List<String> serviceNames = widget.serviceLocations
        .where((service) => _selectedCategory == "All Categories" || service.categoryName == _selectedCategory)
        .map((service) => service.serviceName ?? "Unknown Service")
        .toSet() // Remove duplicates
        .toList();

    // Add a "All Services" option
    serviceNames.insert(0, "All Services");

    double minDistance = double.infinity;
    ServiceLocationResponse? nearestService;

    // Filter markers based on selected category and service name
    for (var service in widget.serviceLocations) {
      // Only show markers that match the selected category or all categories
      if ((_selectedCategory == "All Categories" || service.categoryName == _selectedCategory) &&
          (_selectedServiceName == "All Services" || service.serviceName == _selectedServiceName)) {
        if (service.serviceAddressMapping != null) {
          for (var mapping in service.serviceAddressMapping!) {
            try {
              double? latitude = double.tryParse(mapping.providerAddressMapping!.latitude ?? "");
              double? longitude = double.tryParse(mapping.providerAddressMapping!.longitude ?? "");

              if (latitude != null && longitude != null) {
                // Calculate distance from current location
                double distance = _calculateDistance(widget.latitude, widget.longitude, latitude, longitude);
                if (distance < minDistance) {
                  minDistance = distance;
                  nearestService = service;
                }

                // Use default color for all markers
                BitmapDescriptor markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

                // If the service is the nearest, change its color to green
                if (_selectedCategory != "All Categories" && service == nearestService) {
                  markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
                }

                markers.add(Marker(
                  markerId: MarkerId('${service.serviceId}-${markers.length}'),
                  position: LatLng(latitude, longitude),
                  icon: markerColor,
                  infoWindow: InfoWindow(title: service.serviceName),
                ));
              } else {
                print("Invalid latitude or longitude for service: ${service.serviceName}");
              }
            } catch (e) {
              // Handle any unexpected errors that might occur during parsing
              print("Error processing service location for service: ${service.serviceName}. Error: $e");
            }
          }
        } else {
          print("serviceAddressMapping is null for service: ${service.serviceName}");
        }
      }
    }

    // Store the nearest service to display below the dropdown
    if (_selectedCategory != "All Categories") {
      _nearestService = nearestService;
    } else {
      _nearestService = null;
    }

    // Add a marker for the current location
    markers.add(Marker(
      markerId: MarkerId("current_location"),
      position: LatLng(widget.latitude, widget.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Current location marker (blue)
      infoWindow: const InfoWindow(title: "Your Location"),
    ));
    

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Sample'),
        backgroundColor: Colors.blueAccent,
      ),
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          // Google Map widget
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: markers,
            padding: EdgeInsets.only(
              right: 10, // Adjust this value to move the zoom controls closer to the center horizontally
              bottom: 135, // Adjust this value to move the zoom controls higher vertically
            ),
          ),
          // Positioned Category Dropdown (absolute position)
          Positioned(
            top: 20, // Adjust as needed
            left: 30, // Adjust as needed
            right: 30, // Maintain spacing from both sides
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: DropdownButton<String>(
                hint: const Text('Select Category'),
                value: _selectedCategory,
                isExpanded: true,
                items: categoryNames.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                    _selectedServiceName = "All Services"; // Reset service selection when category changes
                  });
                },
                underline: SizedBox(), // Remove the default underline
              ),
            ),
          ),
          // Positioned Service Name Dropdown (below the category dropdown)
          Positioned(
            top: 80, // Adjust as needed to position below the category dropdown
            left: 30, // Adjust as needed
            right: 30, // Maintain spacing from both sides
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: DropdownButton<String>(
                hint: const Text('Select Service'),
                value: _selectedServiceName,
                isExpanded: true,
                items: serviceNames.map((serviceName) {
                  return DropdownMenuItem<String>(
                    value: serviceName,
                    child: Text(
                      serviceName,
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedServiceName = newValue;
                  });
                },
                underline: SizedBox(), // Remove the default underline
              ),
            ),
          ),
          // Optional: Other absolute-positioned widgets (like the FloatingActionButton)
          
          Positioned(
            bottom: 150, // Position above the list of containers
            left: 16.0,
            child: FloatingActionButton.extended(
              onPressed: _goToTheLake,
              label: const Text('Go to My Location'),
              icon: const Icon(Icons.location_searching),
            ),
          ),
          Positioned(
            bottom: 0, // Position for the list of containers
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Enable horizontal scrolling
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Align containers to start
                children: widget.serviceLocations
                    .map((service) {
                      // Calculate distance for each service
                      double distance = 0;
                      if (service.serviceAddressMapping != null &&
                          service.serviceAddressMapping!.isNotEmpty) {
                        var firstMapping = service.serviceAddressMapping!.first;
                        double? latitude = double.tryParse(firstMapping.providerAddressMapping!.latitude ?? "");
                        double? longitude = double.tryParse(firstMapping.providerAddressMapping!.longitude ?? "");

                        if (latitude != null && longitude != null) {
                          distance = _calculateDistance(widget.latitude, widget.longitude, latitude, longitude);
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IntrinsicWidth( // Ensure the width is adaptive to content
                          child: Container(
                            padding: EdgeInsets.all(16),
                            constraints: BoxConstraints(
                              minWidth: 150, // Set a minimum width for the container
                              maxWidth: 300, // Set a maximum width for the container
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.categoryName ?? "Unknown Category",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  service.serviceName ?? "Unknown Service",
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "${distance.toStringAsFixed(2)} km away",
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
