class Content {
  final String id;
  final String name;
  final String type;
  final String url;
  final int displayDuration;
  final int sequence;
  final DateTime createdAt;
  final String slaveId;
  final String masterId;

  Content({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.displayDuration,
    required this.sequence,
    required this.createdAt,
    required this.slaveId,
    required this.masterId,
  });

  factory Content.fromMap(Map<String, dynamic> map) {
    return Content(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      url: map['url'],
      displayDuration: map['displayDuration'],
      sequence: map['sequence'],
      createdAt: DateTime.parse(map['createdAt']),
      slaveId: map['slaveId'],
      masterId: map['masterId'],
    );
  }
}