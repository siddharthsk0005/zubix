import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  /// Returns the device's current place as "Area, City" (e.g. "Indiranagar, Bengaluru").
  /// Throws [LocationException] when services or permissions are unavailable.
  static Future<String> getCurrentPlaceLabel() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException('Turn on location services to see nearby brands.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationException('Location permission was denied.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );

    final parts = kIsWeb
        ? await _reverseGeocodeWeb(position.latitude, position.longitude)
        : await _reverseGeocodeNative(position.latitude, position.longitude);

    final area = parts.$1;
    final city = parts.$2;
    if (city == null) {
      throw const LocationException('Could not determine your city.');
    }
    return area == null ? city : '$area, $city';
  }

  // geocoding has no web implementation, so the browser uses OpenStreetMap Nominatim.
  static Future<(String?, String?)> _reverseGeocodeWeb(double lat, double lon) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': '$lat',
      'lon': '$lon',
      'zoom': '16',
      'addressdetails': '1',
    });
    final response = await http.get(uri, headers: {'Accept-Language': 'en'});
    if (response.statusCode != 200) {
      throw const LocationException('Could not determine your area.');
    }
    final address = (jsonDecode(response.body) as Map<String, dynamic>)['address']
        as Map<String, dynamic>?;
    if (address == null) {
      throw const LocationException('Could not determine your area.');
    }
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = address[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    final area = pick(['neighbourhood', 'suburb', 'quarter', 'hamlet', 'road']);
    final city = pick(['city', 'town', 'village', 'municipality', 'county', 'state_district']);
    return (area, city);
  }

  static Future<(String?, String?)> _reverseGeocodeNative(double lat, double lon) async {
    final placemarks = await Geocoding().placemarkFromCoordinates(lat, lon);
    if (placemarks.isEmpty) {
      throw const LocationException('Could not determine your area.');
    }
    final place = placemarks.first;
    return (
      _firstNonEmpty([place.subLocality, place.name, place.street]),
      _firstNonEmpty([place.locality, place.subAdministrativeArea]),
    );
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}
