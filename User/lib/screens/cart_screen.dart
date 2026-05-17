import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ---===  دالة التحديث الجديدة والسريعة  ===---
  void _updateQuantity(
      String userId, String cartItemId, int currentQuantity, int change) {
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(cartItemId);

    // إذا كانت الكمية الحالية هي 1 ونريد إنقاصها، قم بالحذف
    if (currentQuantity == 1 && change == -1) {
      cartRef.delete();
    } else {
      // في الحالات الأخرى، استخدم increment السريعة
      cartRef.update({'quantity': FieldValue.increment(change)});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('يرجى تسجيل الدخول لعرض السلة.'));
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('cart')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Remix.shopping_cart_2_line,
                      size: 50, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('سلة المشتريات فارغة!',
                      style: TextStyle(fontSize: 22, color: Colors.grey)),
                ],
              ),
            );
          }

          final cartItems = snapshot.data!.docs;
          double totalPrice = 0;
          for (var item in cartItems) {
            final data = item.data() as Map<String, dynamic>;
            final price = data['price'] ?? 0;
            totalPrice += price * (data['quantity'] ?? 0);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  key: const PageStorageKey<String>('cartList'),
                  padding: const EdgeInsets.all(8.0),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final itemData = item.data() as Map<String, dynamic>;
                    final price = itemData['price'] ?? 0;
                    final quantity = itemData['quantity'] ?? 0;

                    return Card(
                      color: Theme.of(context).cardColor,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                            radius: 30,
                            backgroundImage:
                                NetworkImage(itemData['imageUrl'] ?? '')),
                        title: Text(itemData['name'] ?? 'اسم الوجبة',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$price ريال'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.redAccent),
                              onPressed: () => _updateQuantity(
                                  userId, item.id, quantity, -1),
                            ),
                            Text('$quantity',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline,
                                  color: Theme.of(context).colorScheme.primary),
                              onPressed: () =>
                                  _updateQuantity(userId, item.id, quantity, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5))
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الإجمالي:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('$totalPrice ريال',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckoutScreen(
                                cartItems: cartItems,
                                totalPrice: totalPrice,
                              ),
                            ),
                          );
                        },
                        child: const Text('الانتقال للدفع',
                            style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
