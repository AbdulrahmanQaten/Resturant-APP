import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'dart:ui' as ui;

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _expandedOrderId;
  DateTime? _selectedDate;
  List<DocumentSnapshot>? _cachedOrders;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _expandedOrderId = null; // Close any expanded tile when filtering
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('يرجى تسجيل الدخول لعرض الطلبات.'));
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('orders')
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ في جلب البيانات.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              _cachedOrders == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            _cachedOrders = snapshot.data!.docs;
          }

          if (_cachedOrders == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final allOrders = _cachedOrders!;

          // ---===  الإصلاح هنا: التحقق أولاً إذا كانت القائمة فارغة  ===---
          if (allOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Remix.receipt_line, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد لديك أي طلبات بعد!',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ابدأ بتصفح قائمة الطعام وأضف وجبتك الأولى.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final completedOrders = allOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'تم التوصيل';
          }).toList();

          double totalSpent = 0;
          for (var doc in completedOrders) {
            final data = doc.data() as Map<String, dynamic>;
            totalSpent += (data['totalPrice'] as num?) ?? 0;
          }

          final displayedOrders = _selectedDate == null
              ? allOrders
              : allOrders.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final orderDate = (data['orderDate'] as Timestamp?)?.toDate();
                  if (orderDate == null) return false;
                  return DateUtils.isSameDay(orderDate, _selectedDate);
                }).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _buildStatCard(
                                  'الطلبات المكتملة',
                                  completedOrders.length.toString(),
                                  Remix.checkbox_circle_line,
                                  Colors.green)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildStatCard(
                                  'إجمالي المدفوعات',
                                  '${totalSpent.toStringAsFixed(0)} ريال',
                                  Remix.money_dollar_circle_line,
                                  Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Remix.calendar_line),
                              label: Text(_selectedDate == null
                                  ? 'البحث بالتاريخ'
                                  : DateFormat('yyyy/MM/dd')
                                      .format(_selectedDate!)),
                              onPressed: () => _selectDate(context),
                            ),
                          ),
                          if (_selectedDate != null)
                            IconButton(
                              icon: const Icon(Remix.close_line,
                                  color: Colors.red),
                              onPressed: () =>
                                  setState(() => _selectedDate = null),
                            )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 1)),
              if (displayedOrders.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Remix.calendar_close_line,
                            size: 50, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text('لا توجد طلبات في هذا التاريخ!',
                            style: TextStyle(fontSize: 22, color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final orderData =
                          displayedOrders[index].data() as Map<String, dynamic>;
                      final orderId = orderData['orderId'] as String;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: OrderCard(
                          orderData: orderData,
                          isExpanded: _expandedOrderId == orderId,
                          onExpansionChanged: (isExpanding) {
                            setState(() {
                              if (isExpanding) {
                                _expandedOrderId = orderId;
                              } else {
                                if (_expandedOrderId == orderId) {
                                  _expandedOrderId = null;
                                }
                              }
                            });
                          },
                        ),
                      );
                    },
                    childCount: displayedOrders.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.grey[600])),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// --- ويدجت بطاقة الطلب (يبقى كما هو) ---
class OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  const OrderCard({
    Key? key,
    required this.orderData,
    required this.isExpanded,
    required this.onExpansionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date = (orderData['orderDate'] as Timestamp?)?.toDate();
    final formattedDate =
        date != null ? DateFormat('yyyy/MM/dd', 'ar').format(date) : 'غير محدد';
    final status = orderData['status'] ?? 'قيد المراجعة';
    final timestamps = orderData['timestamps'] as Map<String, dynamic>? ?? {};
    final items = orderData['items'] as List? ?? [];
    final bool isCancelled = status == 'ملغي';
    final bool isCurrentOrder = status != 'تم التوصيل' && !isCancelled;

    int currentStep = 0;
    if (status == 'قيد التجهيز')
      currentStep = 1;
    else if (status == 'مع المندوب')
      currentStep = 2;
    else if (status == 'تم التوصيل') currentStep = 3;

    return Card(
      key: ValueKey(orderData['orderId']),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Theme.of(context).cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey(orderData['orderId']),
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        title: Text(
            'طلب #${(orderData['orderId'] as String).substring(0, 6).toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('بتاريخ: $formattedDate'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${orderData['totalPrice']} ريال',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
            if (isCurrentOrder)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('جاري',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            if (isCancelled)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text('ملغي',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCancelled) ...[
                  const Text('مراحل الطلب:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTimelineStep(
                      context,
                      'تم استلام الطلب',
                      Remix.receipt_line,
                      timestamps['placed'],
                      currentStep >= 0,
                      currentStep > 0),
                  _buildTimelineStep(
                      context,
                      'قيد التجهيز',
                      Remix.restaurant_line,
                      timestamps['preparing'],
                      currentStep >= 1,
                      currentStep > 1),
                  _buildTimelineStep(
                      context,
                      'مع مندوب التوصيل',
                      Remix.takeaway_line,
                      timestamps['delivering'],
                      currentStep >= 2,
                      currentStep > 2),
                  _buildTimelineStep(
                      context,
                      'تم التوصيل',
                      Remix.checkbox_circle_line,
                      timestamps['delivered'],
                      currentStep >= 3,
                      false,
                      isLast: true),
                  const Divider(height: 32),
                ],
                ExpansionTile(
                  key: ValueKey('${orderData['orderId']}_delivery'),
                  tilePadding: EdgeInsets.zero,
                  initiallyExpanded: false,
                  title: const Text('تفاصيل التوصيل',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    ListTile(
                      leading: Icon(Remix.road_map_line,
                          color: Theme.of(context).colorScheme.primary),
                      title:
                          Text(orderData['deliveryZone'] ?? 'منطقة غير محددة'),
                      subtitle: Text(orderData['address'] ?? 'عنوان غير محدد'),
                    ),
                    ListTile(
                      leading: Icon(
                        Remix.phone_line,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Align(
                        alignment: Alignment.centerRight,
                        child: Directionality(
                          textDirection: ui.TextDirection.ltr,
                          child: Text(orderData['phone'] ?? 'رقم غير محدد'),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1),
                ExpansionTile(
                  key: ValueKey('${orderData['orderId']}_meals'),
                  tilePadding: EdgeInsets.zero,
                  initiallyExpanded: false,
                  title: const Text('تفاصيل الوجبة',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    ...items.map((item) {
                      return ListTile(
                        title: Text('${item['name']} (x${item['quantity']})'),
                        trailing:
                            Text('${item['price'] * item['quantity']} ريال'),
                      );
                    }).toList(),
                    ListTile(
                      title: const Text('سعر التوصيل'),
                      trailing: Text('${orderData['deliveryFee']} ريال'),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimelineStep(BuildContext context, String title, IconData icon,
      Timestamp? timestamp, bool isActive, bool isConnectorActive,
      {bool isLast = false}) {
    String time = timestamp != null
        ? DateFormat('h:mm a', 'ar').format(timestamp.toDate())
        : '...';
    final activeColor = Theme.of(context).colorScheme.secondary;
    final inactiveColor = Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: isActive ? activeColor : inactiveColor,
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            if (!isLast)
              Container(
                height: 30,
                width: 2,
                color: isConnectorActive ? activeColor : inactiveColor,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: isActive
                            ? (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black)
                            : Colors.grey,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16)),
                if (isActive && timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(time,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
