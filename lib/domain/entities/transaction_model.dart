class TransactionModel {
  final int? id;
  final double amount;
  final String partyName;
  final String type; // Income, Expense, Udhaari
  final String? categoryName; // NEW!
  final int profileId;
  final DateTime timestamp;
  final DateTime? createdAt;
  final List<String>? images;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    this.id,
    required this.amount,
    required this.partyName,
    required this.type,
    this.categoryName,
    required this.profileId,
    required this.timestamp,
    this.createdAt,
    this.images,
    this.metadata,
  });


  @override
  String toString() {
    return 'TransactionModel(id: $id, amount: $amount, partyName: $partyName, type: $type, categoryName: $categoryName, profileId: $profileId, timestamp: $timestamp)';
  }
}
