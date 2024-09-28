import 'package:flutter/material.dart';
import 'package:securecom/features/user_auth/presentation/pages/add_member.dart';
import 'package:securecom/features/user_auth/presentation/pages/edit_member.dart';
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
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
                  icon: const Icon(Icons.more_vert),
                ),
              ],
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
                      radius: 30,
                      backgroundImage: imageProvider,
                    ),
                  ),
                  title: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: member.firstName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 18.0,
                          ),
                        ),
                        TextSpan(
                          text: ' ${member.lastName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                            fontSize: 18.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            member.phoneNumber,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            member.emailAddress,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: FirebaseAuth.instance.currentUser!.email == 'testuser@gmail.com'
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // Replace 'member.id' with the actual member ID from your data
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Update_Members(memberId: member.id),
                            ),
                          );
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final memberId = filteredMembers[index].id;

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
                              await FirebaseFirestore.instance
                                  .collection('members')
                                  .doc(memberId)
                                  .delete();

                              // Remove the member from the local list and update the UI
                              setState(() {
                                members.removeAt(index);
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Member deleted successfully')),
                              );
                            } catch (e) {
                              print("Error deleting member: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to delete member')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  )
                      : null,
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
      floatingActionButton:
      FirebaseAuth.instance.currentUser!.email == 'testuser@gmail.com'
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMember()),
          );
        },
        child: const Icon(Icons.add),
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
