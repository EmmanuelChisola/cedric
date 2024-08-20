import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';

class FormsPage extends StatefulWidget {
  const FormsPage({Key? key});

  @override
  _FormsPageState createState() => _FormsPageState();
}

class _FormsPageState extends State<FormsPage> {
  PlatformFile? _baptismFile;
  PlatformFile? _membershipFile;
  bool _isMarried = false;

  @override
  void initState() {
    super.initState();
    _checkMaritalStatus();
  }

  Future<void> _checkMaritalStatus() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          _isMarried = snapshot['status'] == 'married';
        });
      } catch (e) {
        print("Error fetching user marital status: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kabwata Baptist Church Forms'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFormSection('Baptism Form', _buildBaptismForm()),
            _buildFormSection('Membership Form', _buildMembershipForm()),
            if (!_isMarried) _buildFormSection('Marriage Form', _buildMarriageForm()),
            _buildFormSection('Leave Form', _buildLeaveForm()),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(String title, Widget form) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4.0,
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: form,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaptismForm() {
    return _buildGenericForm(
      ['Full Name', 'Date of Birth', 'Email', 'Contact Number'],
      _baptismFile,
          (file) {
        setState(() {
          _baptismFile = file;
        });
      },
          () {
        setState(() {
          _baptismFile = null;
        });
      },
    );
  }

  Widget _buildMembershipForm() {
    return _buildGenericForm(
      ['Full Name', 'Address', 'Email', 'Contact Number', 'Date of Joining'],
      _membershipFile,
          (file) {
        setState(() {
          _membershipFile = file;
        });
      },
          () {
        setState(() {
          _membershipFile = null;
        });
      },
    );
  }

  Widget _buildMarriageForm() {
    return _buildGenericForm(
      ['Full Name', 'Spouse\'s Name', 'Wedding Date', 'Email', 'Contact Number'],
      null,
      null,
      null,
    );
  }

  Widget _buildLeaveForm() {
    return _buildGenericForm(
      ['Full Name', 'Reason for Leave', 'Start Date', 'End Date', 'Email', 'Contact Number'],
      null,
      null,
      null,
    );
  }

  Widget _buildGenericForm(List<String> fields, PlatformFile? file, Function(PlatformFile?)? onFilePicked, VoidCallback? onRemoveFile) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...fields.map((field) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: field,
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }).toList(),
          if (onFilePicked != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles();
                      if (result != null) {
                        onFilePicked(result.files.first);
                      }
                    },
                    child: Text(file != null ? 'Change Attachment' : 'Attach File'),
                  ),
                  if (file != null)
                    IconButton(
                      icon: Icon(Icons.remove_circle),
                      color: Colors.red,
                      onPressed: onRemoveFile,
                    ),
                ],
              ),
            ),
          if (file != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Attached: ${file.name}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: () {
                // Handle form submission
              },
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: FormsPage(),
  ));
}
