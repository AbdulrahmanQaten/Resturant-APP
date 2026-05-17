import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:remixicon/remixicon.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main_screen.dart';

// --- كائن لتخزين بيانات منطقة التوصيل ---
class DeliveryZone {
  final String id;
  final String name;
  final double fee;
  DeliveryZone({required this.id, required this.name, required this.fee});
}

// --- كائن جديد لتخزين بيانات العنوان المحفوظ ---
class SavedAddress {
  final String id;
  final String label;
  final String details;
  SavedAddress({required this.id, required this.label, required this.details});
}

class CheckoutScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> cartItems;
  final double totalPrice;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.totalPrice,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  List<DeliveryZone> _deliveryZones = [];
  DeliveryZone? _selectedZone;

  List<SavedAddress> _savedAddresses = [];
  SavedAddress? _selectedAddress;
  bool _useNewAddress = false;

  bool _isLoadingInitialData = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoadingInitialData = false;
      });
      return;
    }

    try {
      // جلب بيانات المستخدم (للحصول على رقم الهاتف)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists && userDoc.data()!.containsKey('phone')) {
        String phone = userDoc.data()!['phone'];
        if (phone.startsWith('+967')) {
          phone = phone.substring(4);
        }
        _phoneController.text = phone;
      }

      // جلب مناطق التوصيل
      final zonesSnapshot =
          await FirebaseFirestore.instance.collection('delivery_zones').get();
      final zones = zonesSnapshot.docs.map((doc) {
        final data = doc.data();
        return DeliveryZone(
            id: doc.id,
            name: data['name'] ?? '',
            fee: (data['fee'] ?? 0).toDouble());
      }).toList();

      // جلب العناوين المحفوظة
      final addressesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .get();
      final addresses = addressesSnapshot.docs.map((doc) {
        final data = doc.data();
        return SavedAddress(
            id: doc.id,
            label: data['label'] ?? '',
            details: data['details'] ?? '');
      }).toList();

      if (mounted) {
        setState(() {
          _deliveryZones = zones;
          _savedAddresses = addresses;
          if (_savedAddresses.isNotEmpty) {
            _selectedAddress = _savedAddresses.first;
          } else {
            _useNewAddress = true;
          }
          _isLoadingInitialData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInitialData = false;
        });
      }
    }
  }

  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser; // --- التعديل هنا ---
    if (user == null) return;

    String finalAddress;
    if (_useNewAddress) {
      finalAddress = _addressController.text.trim();
    } else if (_selectedAddress != null) {
      finalAddress = '${_selectedAddress!.label}: ${_selectedAddress!.details}';
    } else {
      finalAddress = '';
    }

    if (finalAddress.isEmpty ||
        _phoneController.text.isEmpty ||
        _selectedZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى ملء كل الحقول واختيار منطقة التوصيل.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final orderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc();

      // ---===  التعديل هنا: إضافة اسم المستخدم للطلب  ===---
      final orderData = {
        'orderId': orderRef.id,
        'userId': user.uid,
        'userName': user.displayName ?? 'زبون غير مسجل', // الإضافة هنا
        'items': widget.cartItems.map((item) => item.data()).toList(),
        'subtotal': widget.totalPrice,
        'totalPrice': widget.totalPrice + _selectedZone!.fee,
        'deliveryZone': _selectedZone!.name,
        'deliveryFee': _selectedZone!.fee,
        'address': finalAddress,
        'phone': "+967" + _phoneController.text.trim(),
        'status': 'قيد المراجعة',
        'orderDate': FieldValue.serverTimestamp(),
        'timestamps': {'placed': FieldValue.serverTimestamp()}
      };
      // ---=================================================---

      await orderRef.set(orderData);

      final cartCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');
      for (var item in widget.cartItems) {
        await cartCollection.doc(item.id).delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم إرسال طلبك بنجاح!'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => const MainScreen(initialIndex: 3)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("حدث خطأ: $e"), backgroundColor: Colors.red));
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddressPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('اختر عنوان التوصيل'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._savedAddresses.map((address) =>
                        RadioListTile<SavedAddress>(
                          title: Text(address.label,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(address.details,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          value: address,
                          groupValue: _useNewAddress ? null : _selectedAddress,
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedAddress = value;
                              _useNewAddress = false;
                            });
                          },
                        )),
                    RadioListTile<bool>(
                      title: const Text('استخدام عنوان جديد',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      value: true,
                      groupValue: _useNewAddress,
                      onChanged: (value) {
                        setDialogState(() {
                          _useNewAddress = value ?? false;
                          _selectedAddress = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  child: const Text('اختيار'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildSkeletonLoader({double height = 58, double? width}) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).splashColor,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deliveryFee = _selectedZone?.fee ?? 0.0;
    final finalTotal = widget.totalPrice + deliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('إتمام الطلب'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الفاتورة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Card(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الصنف',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600])),
                        Text('الإجمالي',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600])),
                      ],
                    ),
                    const Divider(height: 24),
                    ...widget.cartItems.map((item) {
                      final data = item.data() as Map<String, dynamic>;
                      final price = data['price'] ?? 0;
                      final quantity = data['quantity'] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: Text('${data['name']} (x$quantity)')),
                            Expanded(
                                flex: 1,
                                child: Text('${price * quantity} ريال',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500))),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('معلومات التوصيل',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_isLoadingInitialData)
              Column(
                children: [
                  _buildSkeletonLoader(height: 70),
                  const SizedBox(height: 16),
                  _buildSkeletonLoader(),
                  const SizedBox(height: 16),
                  _buildSkeletonLoader(),
                ],
              )
            else
              Column(
                children: [
                  Card(
                    color: Theme.of(context).cardColor,
                    child: ListTile(
                      leading: const Icon(Remix.map_pin_user_line),
                      title: Text(
                          _useNewAddress
                              ? 'عنوان جديد'
                              : _selectedAddress?.label ??
                                  'الرجاء اختيار عنوان',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: !_useNewAddress && _selectedAddress != null
                          ? Text(_selectedAddress!.details,
                              maxLines: 1, overflow: TextOverflow.ellipsis)
                          : null,
                      trailing: TextButton(
                        child: const Text('تغيير'),
                        onPressed: _showAddressPickerDialog,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _useNewAddress,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: TextField(
                          controller: _addressController,
                          decoration: InputDecoration(
                              labelText: 'العنوان بالتفصيل',
                              prefixIcon: const Icon(Remix.road_map_line),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<DeliveryZone>(
                    decoration: InputDecoration(
                        labelText: 'اختر منطقة التوصيل',
                        prefixIcon: const Icon(Remix.earth_line),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    value: _selectedZone,
                    items: _deliveryZones
                        .map((zone) => DropdownMenuItem<DeliveryZone>(
                            value: zone,
                            child: Text('${zone.name} (+${zone.fee} ريال)')))
                        .toList(),
                    onChanged: (zone) {
                      setState(() {
                        _selectedZone = zone;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                        child: Text('+967',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary)),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي الوجبات:',
                            style: TextStyle(fontSize: 16)),
                        Text('${widget.totalPrice} ريال',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
                  const SizedBox(height: 8),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('سعر التوصيل:',
                            style: TextStyle(fontSize: 16)),
                        Text('$deliveryFee ريال',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
                  const Divider(height: 24),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المجموع الكلي:',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('$finalTotal ريال',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary)),
                      ]),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: _isLoading ? null : _placeOrder,
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ))
              : const Text('تأكيد الطلب والدفع عند الاستلام',
                  style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
