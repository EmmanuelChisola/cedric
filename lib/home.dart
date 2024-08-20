import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:securecom/features/user_auth/presentation/pages/calendar.dart';
import 'package:securecom/features/user_auth/presentation/pages/edit_profile.dart';
import 'package:securecom/features/user_auth/presentation/pages/login_pg.dart';
import 'package:securecom/features/user_auth/presentation/pages/members.dart';
import 'package:securecom/features/user_auth/presentation/pages/ministries.dart';
import 'package:securecom/features/user_auth/presentation/pages/ministry_screen.dart';
import 'package:securecom/forms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class Announcements {
  final String id;
  final String title;
  final String details;

  Announcements({
    required this.id,
    required this.title,
    required this.details,
  });
}


class ChurchHomePage extends StatefulWidget {
  ChurchHomePage({super.key});

  @override
  _ChurchHomePageState createState() => _ChurchHomePageState();
}

class _ChurchHomePageState extends State<ChurchHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  List<Map<String, String>> sermonLinks = [];
  List<Announcements> announcements = [];

  @override
  void initState() {
    super.initState();
    _fetchSermonLinksFromFirestore();
    _fetchAnnouncementsFromFirestore();
  }

  Future<void> _fetchSermonLinksFromFirestore() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('sermonLinks')
          .get();

      setState(() {
        sermonLinks = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();

          String title = data["title"] as String? ?? "No Title";
          String url = data["url"] as String? ?? "No URL";
          String preacher = data["preacher"] as String? ?? "No Preacher";

          return {
            "id": doc.id,
            "title": title,
            "url": url,
            "preacher": preacher,
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching sermon links: $e"),
        ),
      );
    }
  }


  Future<void> _addSermonLink(String title, String preacher, String url) async {
    try {
      // Save to Firestore
      await FirebaseFirestore.instance.collection('sermonLinks').add({
        "title": title,
        "url": url,
        "preacher": preacher,
      });

      // Fetch the updated sermon links to display
      _fetchSermonLinksFromFirestore();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding sermon link: $e"),
        ),
      );
    }
  }
  void _editSermonLinkDialog(Map<String, String> sermon) {
    String title = sermon["title"] ?? '';
    String preacher = sermon["preacher"] ?? '';
    String url = sermon["url"] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Sermon Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                onChanged: (value) {
                  title = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Title',
                ),
                controller: TextEditingController(text: title),
              ),
              TextField(
                onChanged: (value) {
                  preacher = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Preacher',
                ),
                controller: TextEditingController(text: preacher),
              ),
              TextField(
                onChanged: (value) {
                  url = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Sermon Link URL',
                ),
                controller: TextEditingController(text: url),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Update'),
              onPressed: () {
                if (title.isNotEmpty && preacher.isNotEmpty && url.isNotEmpty) {
                  _updateSermonInfo(sermon["id"]!, title, preacher, url);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateSermonInfo(String id, String title, String preacher,
      String url) async {
    try {
      await FirebaseFirestore.instance.collection('sermonLinks').doc(id).update({
        "title": title,
        "preacher": preacher,
        "url": url,
      });
      _fetchSermonLinksFromFirestore();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating sermon link: $e"),
        ),
      );
    }
  }

  void _editSermonInfoDialog() {
    String title = '';
    String preacher = '';
    String url = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a New Sermon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                onChanged: (value) {
                  title = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Title',
                ),
              ),
              TextField(
                onChanged: (value) {
                  preacher = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Preacher',
                ),
              ),
              TextField(
                onChanged: (value) {
                  url = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Sermon Link URL',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                if (title.isNotEmpty && preacher.isNotEmpty && url.isNotEmpty) {
                  _addSermonLink(title, preacher, url);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSermonInfo(String id) async {
    try {
      await FirebaseFirestore.instance.collection('sermonLinks').doc(id).delete();
      _fetchSermonLinksFromFirestore();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error removing sermon link: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String email = user?.email ?? 'User';
    String firstLetter = email.isNotEmpty ? email[0].toUpperCase() : 'U';
    String? photoURL = user?.photoURL;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('KBConnect'),
        backgroundColor: Colors.blue[500],
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CircleAvatar(
                backgroundImage: photoURL != null
                    ? NetworkImage(photoURL)
                    : null,
                backgroundColor: Colors.brown[100],
                child: photoURL == null
                    ? Text(
                  firstLetter,
                  style: const TextStyle(fontSize: 20.0, color: Colors.brown),
                )
                    : null,
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, user, email, firstLetter, photoURL),
      body: _buildPageContent(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.brown[600],
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_form_sharp),
            label: 'Forms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.import_contacts_rounded),
            label: 'Members',
          ),
        ],
        selectedItemColor: Colors.blue,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        onPressed: () {
          _editSermonInfoDialog();
        },
        child: const Icon(Icons.edit),
      )
          : null,
    );
  }

  Drawer _buildDrawer(BuildContext context, User? user, String email,
      String firstLetter, String? photoURL) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(email),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
              backgroundColor: Colors.white,
              child: photoURL == null
                  ? Text(
                firstLetter,
                style: const TextStyle(fontSize: 40.0, color: Colors.blue),
              )
                  : null,
            ),
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            otherAccountsPictures: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(user: user),
                    ),
                  );
                },
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 35,
                ),
              ),
            ],
          ),
          const Text('Settings',
            style: TextStyle(
                fontSize: 17.0,
                fontWeight: FontWeight.bold),),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 0;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings page
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to profile page
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings page
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPg()),
                    (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.grey[700],
                  content: const Text("Account logged out successfully"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeSection(),
              _buildAnnouncementsSection(),
              _buildUpcomingEventsSection(),
              _buildMinistriesSection(),
              _buildSermonLinksSection(),
              _buildContactUsSection(),
            ],
          ),
        );
      case 1:
        return const Center(
          child: Calendar(),
        );
      case 2:
        return const Center(
          child: FormsPage(),
        );
      case 3:
        return Center(
            child: MembersPage()
        );
      default:
        return Container();
    }
  }

  Widget _buildWelcomeSection() {
    return Container(
      color: Colors.brown,
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Welcome to Kabwata Baptist Church!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.0),
          Text(
            'Join us for worship every Sunday at 10:00 AM.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addAnnouncement(String title, String details) async {
    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'details': details,
        'date': Timestamp.now(),
      });
      // Refresh or fetch updated announcements list
      // _fetchAnnouncements();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding announcement: $e"),
        ),
      );
    }
  }

  Future<void> _fetchAnnouncementsFromFirestore() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('announcements').get();
      List<Announcements> fetchedAnnouncements = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;

        return Announcements(
          id: doc.id,
          title: data['title'] ?? 'N/A',
          details: data['details'] ?? 'N/A',
        );
      }).toList();

      setState(() {
        announcements = fetchedAnnouncements;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching announcement: $e"),
        ),
      );
    }
  }


  void _addAnnouncementDialog() {
    String announcementTitle = '';
    String announcementDetails = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Announcement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                onChanged: (value) {
                  announcementTitle = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Announcement Title',
                ),
              ),
              Container(
                height: 100.0, // Set the height to your desired value
                child: TextField(
                  onChanged: (value) {
                    announcementDetails = value;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Announcement Details',
                    border: OutlineInputBorder(), // Optional: Add a border to the TextField
                  ),
                  maxLines: null, // Allows the TextField to expand vertically
                ),
              )

            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                if (announcementTitle.isNotEmpty &&
                    announcementDetails.isNotEmpty) {
                  // Add the announcement to Firebase or your data source
                  _addAnnouncement(announcementTitle, announcementDetails);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnnouncementsSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Announcements',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _addAnnouncementDialog();
                },
                child: const Text('Add Announcement'),
              )
            ],
          ),
          const SizedBox(height: 10.0),
          ...announcements.map((announcement) => _buildAnnouncementsCard(
            announcement.title,
            announcement.details,
          )).toList(),
        ],
      ),
    );
  }




  Widget _buildAnnouncementsCard(String title, String announcement) {
    return Card(
      child: ExpansionTile(
        iconColor: Colors.blueGrey,
        title: Text(title),
        subtitle: Text(announcement.split('\n')[0]), // Shows only the first sentence
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              announcement, // Full announcement
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildUpcomingEventsSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Events',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10.0),
          _buildEventCard('Youth Conference', 'August 25, 2024'),
          _buildEventCard('Women\'s Fellowship', 'September 10, 2024'),
          _buildEventCard('Bible Study', 'September 17, 2024'),
        ],
      ),
    );
  }

  Widget _buildEventCard(String title, String date) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(date),
        trailing: const Icon(Icons.arrow_forward_ios_rounded),
        onTap: () {
          // Navigate to event details page
        },
      ),
    );
  }

  Widget _buildMinistriesSection() {
    return Container(
      color: Colors.blue,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ministries',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to the all ministries page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MinistriesPage(),
                    ),
                  );
                },
                child: const Text(
                  'View Ministries',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          _buildMinistryCard('Youth Ministry', Icons.group),
          _buildMinistryCard('Women\'s Ministry', Icons.group),
          _buildMinistryCard('Men\'s Ministry', Icons.group),
        ],
      ),
    );
  }


  Widget _buildMinistryCard(String title, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios_rounded),
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => MinistriesPage()));
        },
      ),
    );
  }

  Widget _buildSermonLinksSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Row(
            children: [
              Text(
                'Sermon Links',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...sermonLinks.map((sermon) => ListTile(
            title: Text('Title: ${sermon["title"] ?? "No title"}'),
            subtitle: Text('Preacher: ${sermon["preacher"] ?? "Unknown"}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    _editSermonLinkDialog(sermon);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _deleteSermonInfo(sermon["id"]!);
                  },
                ),
                TextButton(
                  onPressed: () {
                    if (sermon["url"] != null && sermon["url"]!.isNotEmpty) {
                      _launchURL(sermon["url"]!);
                    } else {
                      // Handle the case where the URL is missing
                      print("URL is missing for this sermon");
                    }
                  },
                  child: const Text('Listen'),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _openSermonLink(String url) {
    // Implement functionality to open the sermon link (e.g., launch a URL in the browser or a video player)
  }

  Widget _buildContactUsSection() {
    return Container(
      color: Colors.blueGrey[600],
      padding: const EdgeInsets.all(20.0),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Contact Us',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
           SizedBox(height: 10.0),
           Text(
            'Email: pastoroffice@kabwatabaptistchurch.com',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
           Text(
            'Phone: +260 123 456 789',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    // Use the url_launcher package to open URLs
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }

    void _editSermonLinksDialog() {
      String title = '';
      String preacher = '';
      File? sermonFile;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add a New Sermon'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  onChanged: (value) {
                    title = value;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Title',
                  ),
                ),
                TextField(
                  onChanged: (value) {
                    preacher = value;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Preacher',
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              ElevatedButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: const Text('Add'),
                onPressed: () {
                  if (title.isNotEmpty && preacher.isNotEmpty &&
                      url.isNotEmpty) {
                    _addSermonLink(title, preacher, url);
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all fields.'),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }
}