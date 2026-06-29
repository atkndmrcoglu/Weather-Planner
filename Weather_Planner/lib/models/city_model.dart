class CityModel {
  final String name;
  final String country;
  final String lat;
  final String lng;
  final int timezoneOffset;

  CityModel({
    required this.name,
    required this.country,
    required this.lat,
    required this.lng,
    required this.timezoneOffset,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    String latitude = (json['lat'] ?? '0.0').toString();
    String longitude = (json['lng'] ?? '0.0').toString();
    String nameValue = (json['name'] ?? 'Unknown City').toString();
    String countryValue = (json['country'] ?? '--').toString();
    var rawOffset = json['timezone'] ?? 0;
    int finalOffset = 0;
    
    if (rawOffset is num) {
      finalOffset = (rawOffset.abs() <= 18) 
          ? (rawOffset * 3600).toInt() 
          : rawOffset.toInt();
    }

    return CityModel(
      name: nameValue,
      country: countryValue,
      lat: latitude,
      lng: longitude,
      timezoneOffset: finalOffset,
    );
  }
}