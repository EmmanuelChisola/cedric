import 'package:flutter/material.dart';
import 'package:securecom/features/user_auth/presentation/pages/members.dart';

class EditMemberPage extends StatefulWidget {
  final Member member;

  const EditMemberPage({Key? key, required this.member}) : super(key: key);

  @override
  _EditMemberPageState createState() => _EditMemberPageState();
}

class _EditMemberPageState extends State<EditMemberPage> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController phoneNumberController;
  late TextEditingController emailAddressController;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.member.firstName);
    lastNameController = TextEditingController(text: widget.member.lastName);
    phoneNumberController = TextEditingController(text: widget.member.phoneNumber);
    emailAddressController = TextEditingController(text: widget.member.emailAddress);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneNumberController.dispose();
    emailAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Member'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            TextField(
              controller: phoneNumberController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            TextField(
              controller: emailAddressController,
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement update logic here, such as updating Firestore
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
