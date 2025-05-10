import 'record.dart';

class PathDetail {
  final int pathId;
  final String pathName;
  final List<Record> records;

  PathDetail({
    required this.pathId,
    required this.pathName,
    required this.records,
  });

  factory PathDetail.fromJson(Map<String, dynamic> json) {
    final path = json['path'];
    return PathDetail(
      pathId: path['pathId'],
      pathName: path['pathName'],
      records: (json['records'] as List)
          .map((r) => Record.fromJson(r))
          .toList(),
    );
  }
}
