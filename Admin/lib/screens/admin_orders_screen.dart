import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'admin_order_details_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلبات'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          // ---===  الإصلاح هنا: إزالة خاصية التمرير  ===---
          // isScrollable: true,
          physics: NeverScrollableScrollPhysics(),
          tabs: const [
            Tab(text: 'جديد'),
            Tab(text: 'قيد التجهيز'),
            Tab(text: 'مع المندوب'),
            Tab(text: 'مكتمل'),
            Tab(text: 'ملغي'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OrdersTabPage(statuses: const ['قيد المراجعة']),
          OrdersTabPage(statuses: const ['قيد التجهيز']),
          OrdersTabPage(statuses: const ['مع المندوب']),
          OrdersTabPage(statuses: const ['تم التوصيل']),
          OrdersTabPage(statuses: const ['ملغي']),
        ],
      ),
    );
  }
}

// --- ويدجت للحفاظ على حالة كل تبويب (يبقى كما هو) ---
class OrdersTabPage extends StatefulWidget {
  final List<String> statuses;
  const OrdersTabPage({Key? key, required this.statuses}) : super(key: key);

  @override
  State<OrdersTabPage> createState() => _OrdersTabPageState();
}

class _OrdersTabPageState extends State<OrdersTabPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('orders')
          .where('status', whereIn: widget.statuses)
          .orderBy('orderDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("خطأ في جلب الطلبات: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('لا توجد طلبات في هذا القسم حالياً.'));
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          key: PageStorageKey<String>(widget.statuses.join(',')),
          padding: const EdgeInsets.all(12.0),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final orderData = orders[index].data() as Map<String, dynamic>;
            return OrderListItem(orderData: orderData);
          },
        );
      },
    );
  }
}

// --- ويدجت لعرض كل طلب في القائمة (يبقى كما هو) ---
class OrderListItem extends StatelessWidget {
  final Map<String, dynamic> orderData;
  const OrderListItem({Key? key, required this.orderData}) : super(key: key);

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
      builder: (context) {
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
                  Navigator.of(context).pop();
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
    final date = (orderData['orderDate'] as Timestamp?)?.toDate();
    final formattedDate = date != null
        ? DateFormat('yyyy/MM/dd - h:mm a', 'ar').format(date)
        : 'غير محدد';
    final status = orderData['status'] ?? '...';
    final bool canChangeStatus = status != 'تم التوصيل' && status != 'ملغي';

    Color statusColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    if (status == 'قيد المراجعة')
      statusColor = Theme.of(context).colorScheme.primary;
    if (status == 'قيد التجهيز' || status == 'مع المندوب')
      statusColor = Theme.of(context).colorScheme.secondary;
    if (status == 'تم التوصيل') statusColor = Colors.green;
    if (status == 'ملغي') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AdminOrderDetailsScreen(orderData: orderData),
            ),
          );
        },
        leading: CircleAvatar(
          child: Icon(Remix.file_list_3_line,
              color: Theme.of(context).colorScheme.primary),
        ),
        title: Text('طلب من: ${orderData['userName'] ?? 'زبون'}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            'رقم الطلب: #${(orderData['orderId'] as String).substring(0, 6).toUpperCase()}\nبتاريخ: $formattedDate'),
        trailing: TextButton(
          onPressed: canChangeStatus
              ? () {
                  _changeOrderStatus(context, orderData['userId'],
                      orderData['orderId'], status);
                }
              : null,
          child: Text(status,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
        ),
        isThreeLine: true,
      ),
    );
  }
}
