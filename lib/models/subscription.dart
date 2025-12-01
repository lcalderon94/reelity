import 'package:cloud_firestore/cloud_firestore.dart';

class Subscription {
  final String id;
  final String userId;  // Quien se suscribe
  final String subscribedToUserId;  // A quien se suscribe
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.subscribedToUserId,
    required this.createdAt,
  });

  factory Subscription.fromFirestore(Map<String, dynamic> data, String id) {
    return Subscription(
      id: id,
      userId: data['userId'] as String,
      subscribedToUserId: data['subscribedToUserId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'subscribedToUserId': subscribedToUserId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
