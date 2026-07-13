class Couple {
  const Couple({
    required this.id,
    required this.memberA,
    required this.memberB,
    required this.status,
    required this.longDistance,
    this.anniversaryGreg,
    this.anniversaryHijri,
  });

  final String id;
  final String memberA;
  final String memberB;
  final String status;
  final bool longDistance;
  final DateTime? anniversaryGreg;
  final String? anniversaryHijri;

  bool includes(String userId) => userId == memberA || userId == memberB;
  String spouseOf(String userId) => userId == memberA ? memberB : memberA;

  factory Couple.fromRow(Map<String, dynamic> row) => Couple(
        id: row['id'] as String,
        memberA: row['member_a'] as String,
        memberB: row['member_b'] as String,
        status: (row['status'] ?? 'active') as String,
        longDistance: (row['long_distance'] ?? false) as bool,
        anniversaryGreg: row['anniversary_greg'] == null
            ? null
            : DateTime.parse(row['anniversary_greg'] as String),
        anniversaryHijri: row['anniversary_hijri'] as String?,
      );
}
