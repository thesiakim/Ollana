import 'path_detail.dart';

class FootprintDetailResponse {
  final String mountainName;
  final List<PathDetail> paths;
  final bool last;

  FootprintDetailResponse({
    required this.mountainName,
    required this.paths,
    required this.last,
  });

  factory FootprintDetailResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return FootprintDetailResponse(
      mountainName: data['mountain']['mountainName'],
      paths: (data['paths'] as List)
          .map((p) => PathDetail.fromJson(p))
          .toList(),
      last: data['last'],
    );
  }
}
