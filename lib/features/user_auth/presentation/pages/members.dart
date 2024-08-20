import 'package:flutter/material.dart';
import 'package:securecom/features/user_auth/presentation/pages/add_member.dart';
import 'package:securecom/features/user_auth/presentation/pages/login_pg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MembersPage extends StatefulWidget {
  @override
  _MembersPageState createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  String query = '';
  String sortBy = 'firstName'; // Default sorting by first name
  List<Member> members = [];

  @override
  void initState() {
    super.initState();
    _fetchMembersFromFirestore();
  }

  Future<void> _fetchMembersFromFirestore() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('members').get();
      List<Member> fetchedMembers = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;

        // Debug prints to check if data is being fetched correctly
        print('Fetched member data: $data');

        return Member(
          id: doc.id,
          firstName: data['firstName'] ?? 'N/A',
          lastName: data['lastName'] ?? 'N/A',
          phoneNumber: data['phone'] ?? 'N/A',
          emailAddress: data['email'] ?? 'N/A',
          profilePictureUrl: data['imageUrl'] ?? '',
        );
      }).toList();

      setState(() {
        members = fetchedMembers;
      });
    } catch (e) {
      print("Error fetching members: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = members.where((member) {
      return member.fullName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    filteredMembers.sort((a, b) {
      if (sortBy == 'firstName') {
        return a.firstName.compareTo(b.firstName);
      } else {
        return a.lastName.compareTo(b.lastName);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                sortBy = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'firstName',
                  child: Text('Sort by First Name'),
                ),
                const PopupMenuItem<String>(
                  value: 'lastName',
                  child: Text('Sort by Last Name'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (text) {
                setState(() {
                  query = text;
                });
              },
            ),
          ),
          Expanded(
            child: members.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                final member = filteredMembers[index];
                return ListTile(
                  leading: member.profilePictureUrl.isEmpty
                      ? CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      '${member.firstName[0].toUpperCase()}${member.lastName[0].toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                  )
                      : CachedNetworkImage(
                    imageUrl: member.profilePictureUrl,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                    imageBuilder: (context, imageProvider) => CircleAvatar(
                      backgroundImage: imageProvider,
                    ),
                  ),
                  title: Text(member.fullName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.phoneNumber),
                      Text(member.emailAddress),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // Implement your edit functionality here
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final memberId = filteredMembers[index].id; // Assuming you have a unique ID for each member

                          // Show a confirmation dialog before deleting
                          bool? confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: const Text('Are you sure you want to delete this member?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmDelete == true) {
                            try {
                              // Delete member from Firestore
                              await FirebaseFirestore.instance.collection('members').doc(memberId).delete();

                              // Remove the member from the local list and update the UI
                              setState(() {
                                members.removeAt(index);
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Member deleted successfully')),
                              );
                            } catch (e) {
                              print("Error deleting member: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to delete member')),
                              );
                            }
                          }
                        }
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPg(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FirebaseAuth.instance.currentUser!.email == 'testuser@gmail.com'
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMember()),
          );
        },
        label: const Text("Add Member"),
        icon: const Icon(Icons.add),
      )
          : const SizedBox.shrink(),
    );
  }
}

class Member {
  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String emailAddress;
  final String profilePictureUrl;

  Member({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.emailAddress,
    required this.profilePictureUrl,
  });

  String get fullName => '$firstName $lastName';
}
