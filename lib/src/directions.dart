// Copyright (c) 2020, the MarchDev Toolkit project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ui';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:flinq/flinq.dart';
import 'package:http/http.dart' as http;
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart'
    as gpl;

part 'directions.request.dart';
part 'directions.response.dart';

/// This service is used to calculate route between two points
class DirectionsService {
  static const _directionApiUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  static String _apiKey;

  /// Initializer of [GoogleMap].
  ///
  /// `Required` if `Directions API` on `Mobile device` will be needed.
  /// For other cases, could be ignored.
  static void init(String apiKey) => _apiKey = apiKey;

  /// Gets an google API key
  static String get apiKey => _apiKey;

  /// Calculates route between two points.
  ///
  /// `request` argument contains origin and destination points
  /// and also settings for route calculation.
  ///
  /// `callback` argument will be called when route calculations finished.
  Future<void> route(
    DirectionsRequest request,
    void Function(DirectionsResult, DirectionsStatus) callback,
  ) async {
    assert(() {
      if (request == null) {
        throw ArgumentError.notNull('request');
      }

      if (request == null) {
        throw ArgumentError.notNull('callback');
      }

      return true;
    }());

    final url = '$_directionApiUrl${request.toString()}&key=$apiKey';
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
          '${response.statusCode} (${response.reasonPhrase}), uri = ${response.request.url}');
    }

    final result = DirectionsResult.fromMap(json.decode(response.body));

    callback(result, result.status);
  }
}

/// A pair of latitude and longitude coordinates, stored as degrees.
class LatLng {
  /// Creates a geographical location specified in degrees [latitude] and
  /// [longitude].
  ///
  /// The latitude is clamped to the inclusive interval from -90.0 to +90.0.
  ///
  /// The longitude is normalized to the half-open interval from -180.0
  /// (inclusive) to +180.0 (exclusive)
  const LatLng(double latitude, double longitude)
      : assert(latitude != null),
        assert(longitude != null),
        latitude =
            (latitude < -90.0 ? -90.0 : (90.0 < latitude ? 90.0 : latitude)),
        longitude = (longitude + 180.0) % 360.0 - 180.0;

  /// The latitude in degrees between -90.0 and 90.0, both inclusive.
  final double latitude;

  /// The longitude in degrees between -180.0 (inclusive) and 180.0 (exclusive).
  final double longitude;

  static LatLng _fromList(List<num> list) => LatLng(
        list[0],
        list[1],
      );

  @override
  String toString() => '$runtimeType($latitude, $longitude)';

  @override
  bool operator ==(Object o) {
    return o is LatLng && o.latitude == latitude && o.longitude == longitude;
  }

  @override
  int get hashCode => hashValues(latitude, longitude);
}

/// A latitude/longitude aligned rectangle.
///
/// The rectangle conceptually includes all points (lat, lng) where
/// * lat ∈ [`southwest.latitude`, `northeast.latitude`]
/// * lng ∈ [`southwest.longitude`, `northeast.longitude`],
///   if `southwest.longitude` ≤ `northeast.longitude`,
/// * lng ∈ [-180, `northeast.longitude`] ∪ [`southwest.longitude`, 180],
///   if `northeast.longitude` < `southwest.longitude`
class LatLngBounds {
  /// Creates geographical bounding box with the specified corners.
  ///
  /// The latitude of the southwest corner cannot be larger than the
  /// latitude of the northeast corner.
  LatLngBounds({@required this.southwest, @required this.northeast})
      : assert(southwest != null),
        assert(northeast != null),
        assert(southwest.latitude <= northeast.latitude);

  /// The southwest corner of the rectangle.
  final LatLng southwest;

  /// The northeast corner of the rectangle.
  final LatLng northeast;

  /// Returns whether this rectangle contains the given [LatLng].
  bool contains(LatLng point) {
    return _containsLatitude(point.latitude) &&
        _containsLongitude(point.longitude);
  }

  bool _containsLatitude(double lat) {
    return (southwest.latitude <= lat) && (lat <= northeast.latitude);
  }

  bool _containsLongitude(double lng) {
    if (southwest.longitude <= northeast.longitude) {
      return southwest.longitude <= lng && lng <= northeast.longitude;
    } else {
      return southwest.longitude <= lng || lng <= northeast.longitude;
    }
  }

  @override
  String toString() {
    return '$runtimeType($southwest, $northeast)';
  }

  @override
  bool operator ==(Object o) {
    return o is LatLngBounds &&
        o.southwest == southwest &&
        o.northeast == northeast;
  }

  @override
  int get hashCode => hashValues(southwest, northeast);
}

/// Represents an enum of various travel modes.
///
/// The valid travel modes that can be specified in a
/// `DirectionsRequest` as well as the travel modes returned
/// in a `DirectionsStep`. Specify these by value, or by using
/// the constant's name.
class TravelMode {
  const TravelMode(this._name);

  final String _name;

  static final values = <TravelMode>[bicycling, driving, transit, walking];

  /// Specifies a bicycling directions request.
  static const bicycling = TravelMode('bicycling');

  /// Specifies a driving directions request.
  static const driving = TravelMode('driving');

  /// Specifies a transit directions request.
  static const transit = TravelMode('transit');

  /// Specifies a walking directions request.
  static const walking = TravelMode('walking');

  @override
  int get hashCode => _name.hashCode;

  @override
  bool operator ==(dynamic other) =>
      other is TravelMode && _name == other._name;

  @override
  String toString() => '$_name';
}
