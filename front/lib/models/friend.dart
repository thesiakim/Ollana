class Friend {
  final num id;
  final String nickname;
  final bool isPossible;

  Friend({required this.id, required this.nickname, required this.isPossible});

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
        id: json['id'],
        nickname: json['nickname'],
        isPossible: json['isPossible']);
  }
}
