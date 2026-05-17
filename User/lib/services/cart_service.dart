import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> addToCart(
  BuildContext context,
  String mealId,
  Map<String, dynamic> mealData,
  num finalPrice,
) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  final cartItemData = Map<String, dynamic>.from(mealData);
  cartItemData.remove('discountPrice');
  cartItemData['price'] = finalPrice;

  final cartRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('cart')
      .doc(mealId);

  final doc = await cartRef.get();
  if (!doc.exists) {
    await cartRef.set({
      ...cartItemData,
      'quantity': 1,
      'addedAt': FieldValue.serverTimestamp(),
    });
  } else {
    await cartRef.update({'quantity': FieldValue.increment(1)});
  }

  // تأكد من أن السياق ما زال صالحًا (اختياري حسب استخدامك)
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت إضافة "${mealData['name']}" إلى السلة!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
