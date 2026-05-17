import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';
import 'add_edit_delivery_zone_screen.dart'; // سنقوم بإنشاء هذا الملف لاحقاً

class AdminDeliveryZonesScreen extends StatelessWidget {
  const AdminDeliveryZonesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة مناطق التوصيل'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('delivery_zones').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لم تقم بإضافة أي مناطق بعد.'));
          }

          final zones = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: zones.length,
            itemBuilder: (context, index) {
              final zoneDoc = zones[index];
              final zoneData = zoneDoc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: const Icon(Remix.map_pin_range_line),
                  title: Text(zoneData['name'] ?? 'اسم المنطقة',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('رسوم التوصيل: ${zoneData['fee']} ريال'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Remix.edit_line, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddEditDeliveryZoneScreen(zoneDoc: zoneDoc),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Remix.delete_bin_line,
                            color: Colors.redAccent),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('تأكيد الحذف'),
                              content: Text(
                                  'هل أنت متأكد أنك تريد حذف منطقة "${zoneData['name']}"؟'),
                              actions: [
                                TextButton(
                                    child: const Text('إلغاء'),
                                    onPressed: () => Navigator.of(ctx).pop()),
                                TextButton(
                                  child: const Text('نعم، حذف',
                                      style: TextStyle(color: Colors.red)),
                                  onPressed: () {
                                    zoneDoc.reference.delete();
                                    Navigator.of(ctx).pop();
                                    if (ScaffoldMessenger.of(context).mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('تم حذف المنطقة بنجاح.'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
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
                builder: (context) => const AddEditDeliveryZoneScreen()),
          );
        },
        label: const Text('إضافة منطقة جديدة'),
        icon: const Icon(Remix.add_line),
      ),
    );
  }
}
