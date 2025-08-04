// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

import 'visit/visit_page.dart';

import 'profile/profile_screen.dart';
import '../widgets/contact_info.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;

  static final List<Widget> _widgetOptions = <Widget>[
    ContactInfo(),
    VisitPage(),
   
    Profile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: ConvexAppBar(
        // «ناوبار برجسته» (Convex) با پس‌زمینه سفید
        style: TabStyle.react,          // افکت انیمیشن واکنشی
        backgroundColor: Colors.white,  // پس‌زمینهٔ سفید
        activeColor: Colors.blueAccent, // آیکن/متن فعال
        color: Colors.grey,             // آیکن/متن غیرفعال
        initialActiveIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          TabItem(icon: Icons.call, title: 'تماس'),
          TabItem(icon: Icons.local_hospital, title: 'ویزیت'),
          TabItem(icon: Icons.person, title: 'پروفایل'),
        ],
      ),
    );
  }
}
