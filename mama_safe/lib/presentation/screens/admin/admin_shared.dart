import 'package:flutter/material.dart';

// Simple loading widget
class AdminLoading extends StatelessWidget {
  const AdminLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Colors.teal),
    );
  }
}

// Simple page wrapper
class AdminPage extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Widget child;

  const AdminPage({
    super.key,
    required this.title,
    this.actions = const [],
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: actions,
      ),
      body: child,
    );
  }
}

// Simple button widgets
class GhostBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const GhostBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}

class PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const PrimaryBtn({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// Color constants
const kTeal = Colors.teal;
const kGreen = Colors.green;
const kOrange = Colors.orange;
const kRed = Colors.red;
const kWhite = Colors.white;
const kBorder = Colors.grey;
const kBgPage = Color(0xFFF5F5F5);
const kDarkText = Colors.black87;
const kGray = Colors.grey;