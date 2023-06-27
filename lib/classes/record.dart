class Record {
  final int? id;
  final String qrData;
  final String comment;
  final DateTime timestamp;

  Record({this.id, required this.qrData, required this.comment, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'qrData': qrData,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}