import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:securecom/features/user_auth/presentation/pages/ministries.dart';

class Ministry {

  final String name;
  final String description;


  Ministry({required this.name, required this.description});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }

  factory Ministry.fromMap(Map<String, dynamic> map) {
    return Ministry(
      name: map['name'],
      description: map['description'],
    );
  }
}


class AddMinistryDialog extends StatefulWidget {
  final void Function(Ministry) onMinistryAdded;

  AddMinistryDialog({required this.onMinistryAdded});

  @override
  _AddMinistryDialogState createState() => _AddMinistryDialogState();
}

class _AddMinistryDialogState extends State<AddMinistryDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  void _submit() {
    final name = _nameController.text;
    final description = _descriptionController.text;

    if (name.isNotEmpty && description.isNotEmpty) {
      final newMinistry = Ministry(name: name, description: description);
      widget.onMinistryAdded(newMinistry);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Ministry'),
      content: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Ministry Name'),
          ),
          Container(
            height: 100.0,
            child: TextField(
              onChanged: (value) {
                _descriptionController.text = value;
              },
              decoration: const InputDecoration(
                hintText: 'Ministry Details',
                border: OutlineInputBorder(), // Optional: Add a border to the TextField
              ),
              maxLines: null, // Allows the TextField to expand vertically
            ),
          ),

        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text('Add'),
        ),
      ],
    );
  }
}
