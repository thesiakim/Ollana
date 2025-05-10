import 'footprint_mountain.dart';

class FootprintResponse {
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool last;
  final String totalDistance;
  final List<footprintMountain> mountains;

  FootprintResponse({
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.last,
    required this.totalDistance,
    required this.mountains,
  });

  factory FootprintResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return FootprintResponse(
      currentPage: data['currentPage'],
      totalPages: data['totalPages'],
      totalElements: data['totalElements'],
      last: data['last'],
      totalDistance: data['totalDistance'].toString(),
      mountains: (data['mountains'] as List)
          .map((item) => footprintMountain.fromJson(item))
          .toList(),
    );
  }
}
