import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';

class AddEditDeliveryZoneScreen extends StatefulWidget {
  final DocumentSnapshot? zoneDoc;

  const AddEditDeliveryZoneScreen({Key? key, this.zoneDoc}) : super(key: key);

  @override
  State<AddEditDeliveryZoneScreen> createState() =>
      _AddEditDeliveryZoneScreenState();
}

class _AddEditDeliveryZoneScreenState extends State<AddEditDeliveryZoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _feeController = TextEditingController();
  bool _isLoading = false;
  bool get _isEditing => widget.zoneDoc != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final data = widget.zoneDoc!.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _feeController.text = (data['fee'] ?? 0).toString();
    }
  }

  Future<void> _saveZone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final zoneData = {
      'name': _nameController.text.trim(),
      'fee': num.tryParse(_feeController.text.trim()) ?? 0,
    };

    try {
      if (_isEditing) {
        await widget.zoneDoc!.reference.update(zoneData);
      } else {
        await FirebaseFirestore.instance
            .collection('delivery_zones')
            .add(zoneData);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'تم تعديل المنطقة بنجاح!'
                : 'تم إضافة المنطقة بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("حدث خطأ: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل منطقة' : 'إضافة منطقة جديدة'),
        centerTitle: true,
        actions: [
          if (_isLoading)
            Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ))),
          if (!_isLoading)
            IconButton(icon: const Icon(Remix.save_line), onPressed: _saveZone),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المنطقة'),
                validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _feeController,
                decoration: const InputDecoration(labelText: 'رسوم التوصيل'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
