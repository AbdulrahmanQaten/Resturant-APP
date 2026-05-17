import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:remixicon/remixicon.dart';
import 'add_edit_address_screen.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({Key? key}) : super(key: key);

  // --- دالة جديدة لإظهار نافذة تأكيد الحذف ---
  void _showDeleteConfirmation(
      BuildContext context, String userId, String addressId) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد أنك تريد حذف هذا العنوان؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              child:
                  const Text('نعم، حذف', style: TextStyle(color: Colors.red)),
              onPressed: () {
                // حذف العنوان وإغلاق النافذة
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('addresses')
                    .doc(addressId)
                    .delete();
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('عناويني'),
        centerTitle: true,
      ),
      body: userId == null
          ? const Center(child: Text('يرجى تسجيل الدخول لعرض العناوين.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('addresses')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Remix.road_map_line, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('لم تقم بإضافة أي عناوين بعد!',
                            style: TextStyle(fontSize: 22, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final addresses = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final addressData =
                        addresses[index].data() as Map<String, dynamic>;
                    final addressId = addresses[index].id;
                    return Card(
                      color: Theme.of(context).colorScheme.surface,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        leading: const Icon(Remix.map_pin_line),
                        title: Text(addressData['label'] ?? 'عنوان',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle:
                            Text(addressData['details'] ?? 'لا توجد تفاصيل'),
                        // --- جعل العنصر قابلاً للضغط للتعديل ---
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditAddressScreen(
                                addressId: addressId,
                                initialData: addressData,
                              ),
                            ),
                          );
                        },
                        trailing: IconButton(
                          icon: const Icon(Remix.delete_bin_line,
                              color: Colors.redAccent),
                          onPressed: () {
                            // --- استدعاء نافذة التأكيد قبل الحذف ---
                            _showDeleteConfirmation(context, userId, addressId);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddEditAddressScreen()),
          );
        },
        label: const Text('إضافة عنوان جديد'),
        icon: const Icon(Remix.add_line),
      ),
    );
  }
}
