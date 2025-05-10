import './opponent_record.dart';

class Opponent {
  final int opponentId;
  final String nickname;
  final List<OpponentRecord> records;

  Opponent({
    required this.opponentId,
    required this.nickname,
    required this.records,
  });

  factory Opponent.fromJson(Map<String, dynamic> json) {
    return Opponent(
      opponentId: json['opponentId'] as int,
      nickname: json['nickname'] as String,
      records: (json['records'] as List)
          .map((record) =>
              OpponentRecord.fromJson(record as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opponentId': opponentId,
      'nickname': nickname,
      'records': records.map((record) => record.toJson()).toList(),
    };
  }
}
