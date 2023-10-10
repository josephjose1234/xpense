
class Transactions {

  Transactions({
    this.id,
    required this.operator,
    required this.item,
    required this.amount,
    required this.DTime,
  });

  final String DTime;
  final int amount;
  final int? id;
  final String item;
  final String operator;

  Map<String, dynamic> toMap() {
    return {
      'operator': operator,
      'item': item,
      'amount': amount,
      'DTime': DTime,
    };
  }
}