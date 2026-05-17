import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';
import 'package:intl/intl.dart';

class AdminOrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const AdminOrderDetailsScreen({Key? key, required this.orderData})
      : super(key: key);

  void _changeOrderStatus(BuildContext context, String userId, String orderId,
      String currentStatus) {
    List<String> availableStatuses = [];

    switch (currentStatus) {
      case 'قيد المراجعة':
        availableStatuses = ['قيد التجهيز', 'ملغي'];
        break;
      case 'قيد التجهيز':
        availableStatuses = ['مع المندوب', 'ملغي'];
        break;
      case 'مع المندوب':
        availableStatuses = ['تم التوصيل', 'ملغي'];
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('تغيير حالة الطلب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableStatuses.map((status) {
              return ListTile(
                title: Text(status),
                onTap: () {
                  final orderRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('orders')
                      .doc(orderId);
                  String timestampField = '';
                  if (status == 'قيد التجهيز') timestampField = 'preparing';
                  if (status == 'مع المندوب') timestampField = 'delivering';
                  if (status == 'تم التوصيل') timestampField = 'delivered';
                  if (status == 'ملغي') timestampField = 'cancelled';

                  orderRef.update({
                    'status': status,
                    if (timestampField.isNotEmpty)
                      'timestamps.$timestampField':
                          FieldValue.serverTimestamp(),
                  });
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = (orderData['items'] as List<dynamic>?) ?? [];
    final date = (orderData['orderDate'] as Timestamp?)?.toDate();
    final formattedDate = date != null
        ? DateFormat('yyyy/MM/dd - h:mm a', 'ar').format(date)
        : 'غير محدد';
    final status = orderData['status'] ?? 'قيد المراجعة';
    final bool canChangeStatus = status != 'تم التوصيل' && status != 'ملغي';

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'تفاصيل الطلب #${(orderData['orderId'] as String).substring(0, 6).toUpperCase()}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              context,
              title: 'معلومات الزبون',
              icon: Remix.user_line,
              children: [
                _buildDetailRow('الاسم:', orderData['userName'] ?? 'غير متوفر'),
                _buildDetailRow(
                    'رقم الهاتف:', orderData['phone'] ?? 'غير متوفر'),
                _buildDetailRow(
                    'المنطقة:', orderData['deliveryZone'] ?? 'غير متوفر'),
                _buildDetailRow('العنوان:', orderData['address'] ?? 'غير متوفر',
                    isThreeLine: true),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              title: 'تفاصيل الطلب',
              icon: Remix.file_list_3_line,
              children: [
                ...items.map((item) {
                  final itemData = item as Map<String, dynamic>;
                  return ListTile(
                    title:
                        Text('${itemData['name']} (x${itemData['quantity']})'),
                    trailing: Text(
                        '${itemData['price'] * itemData['quantity']} ريال'),
                  );
                }).toList(),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              title: 'الفاتورة',
              icon: Remix.money_dollar_circle_line,
              children: [
                _buildDetailRow(
                    'إجمالي الوجبات:', '${orderData['subtotal']} ريال'),
                _buildDetailRow(
                    'رسوم التوصيل:', '${orderData['deliveryFee']} ريال'),
                const Divider(height: 24),
                _buildDetailRow(
                    'المجموع الكلي:', '${orderData['totalPrice']} ريال',
                    isBold: true),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Remix.edit_line),
          label: const Text('تغيير حالة الطلب', style: TextStyle(fontSize: 18)),
          // --- تعطيل الزر إذا لم يكن بالإمكان تغيير الحالة ---
          onPressed: canChangeStatus
              ? () => _changeOrderStatus(
                  context, orderData['userId'], orderData['orderId'], status)
              : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context,
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, bool isThreeLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment:
            isThreeLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text('$label ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 16 : 14),
            ),
          ),
        ],
      ),
    );
  }
}
