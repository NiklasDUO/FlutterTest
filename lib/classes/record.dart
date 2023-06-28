class Record {
  late int id;
  int quantity;
  String qrData;
  String comment;
  DateTime timestamp;
  String? macAddress;

  Record({
    required this.qrData,
    required this.comment,
    required this.timestamp,
    required this.id,
    this.quantity = 1,
    String? macAddress,
  }) : macAddress = macAddress ?? RegExp(r'([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})').firstMatch(qrData)?.group(0) ?? 'N/A';

  Map<String, dynamic> toMap() {
    return {
      'qrData': qrData,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
      'macAddress': macAddress,
      'quantity': quantity,
    };
  }

}