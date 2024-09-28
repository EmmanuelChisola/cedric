import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:securecom/features/user_auth/presentation/pages/add_ministry.dart';

class Ministry {
  String id;
  String name;
  String description;

  Ministry({
    required this.id,
    required this.name,
    required this.description,
  });


  // Factory constructor to create a Ministry object from Firestore data
  factory Ministry.fromMap(Map<String, dynamic> data, String id) {
    return Ministry(
      id: id,
      name: data['name'] as String,
      description: data['description'] as String,
    );
  }

  // Method to convert a Ministry object to a Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }
}


class MinistriesPage extends StatefulWidget {

  @override
  State<MinistriesPage> createState() => _MinistriesPageState();
}

class _MinistriesPageState extends State<MinistriesPage> {

  List<Ministry> ministries = [];


  @override
  void initState() {
    super.initState();
    _fetchMinistriesFromDatabase();
  }

  void _editMinistry(BuildContext context, Ministry ministry) {
    final TextEditingController _nameController = TextEditingController(text: ministry.name);
    final TextEditingController _descriptionController = TextEditingController(text: ministry.description);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit ${ministry.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Save the updated values
                final updatedMinistry = Ministry(
                  id: ministry.id,
                  name: _nameController.text,
                  description: _descriptionController.text,
                );

                // Update the ministry in the database
                final firestore = FirebaseFirestore.instance;
                await firestore
                    .collection('ministries')
                    .doc(updatedMinistry.id)
                    .update(updatedMinistry.toMap());

                // Refresh the list of ministries
                _fetchMinistriesFromDatabase();

                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }


  void _deleteMinistry(BuildContext context, Ministry ministry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Ministry'),
          content: Text('Are you sure you want to delete ${ministry.name}?'),
          actions: [
            TextButton(
              onPressed: () async {
                // Perform the delete operation on Firestore
                final firestore = FirebaseFirestore.instance;
                await firestore.collection('ministries').doc(ministry.id).delete();
                // Refresh the list of ministries
                _fetchMinistriesFromDatabase();
                // Close the dialog
                Navigator.of(context).pop();
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _fetchMinistriesFromDatabase() async {
    final firestore = FirebaseFirestore.instance;
    final querySnapshot = await firestore.collection('ministries').get();

    setState(() {
      ministries = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Ministry.fromMap(data, doc.id); // Pass the document ID here
      }).toList();
    });
  }


  Future<void> _addMinistryToDatabase(Ministry ministry) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('ministries').add(ministry.toMap());
  }

  void _addMinistry() {
    showDialog(
      context: context,
      builder: (context) => AddMinistryDialog(
        onMinistryAdded: (ministry) async {
          await _addMinistryToDatabase(ministry as Ministry);
          _fetchMinistriesFromDatabase();
        },
      ),
    );
  }

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Church Ministries'),
      ),
      body: ListView.builder(
        itemCount: ministries.length,
        itemBuilder: (context, index) {
          final ministry = ministries[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(ministry.name),
              subtitle: Text(ministry.description),
              trailing: FirebaseAuth.instance.currentUser!.email == 'testuser@gmail.com'
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editMinistry(context, ministry),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteMinistry(context, ministry),
                  ),
                ],
              ):null,
            ),
          );
        },
      ),
      floatingActionButton: FirebaseAuth.instance.currentUser!.email == 'testuser@gmail.com'
          ? FloatingActionButton(
        onPressed: _addMinistry,
        child: Icon(Icons.add),
        tooltip: 'Add Ministry',
      ):null,
    );
  }
}
