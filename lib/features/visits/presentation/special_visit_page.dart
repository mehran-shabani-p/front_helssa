import 'package:flutter/material.dart';

class SpecialVisitPage extends StatelessWidget {
  const SpecialVisitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ویزیت ویژه')),
      body: const SafeArea(child: Center(child: Text('خدمات ویژه به‌زودی...'))),
    );
  }
}
