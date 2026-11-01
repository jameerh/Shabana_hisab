import 'package:flutter/material.dart';

class GoalTemplate {
  final String id;
  final String title;
  final IconData icon;
  final String defaultFundingStrategy;
  final int basePriority; // For recommendations
  final Color themeColor;

  const GoalTemplate({
    required this.id,
    required this.title,
    required this.icon,
    this.defaultFundingStrategy = 'SAFE_TO_SPEND',
    this.basePriority = 50,
    this.themeColor = Colors.blueAccent,
  });

  static const List<GoalTemplate> all = [
    GoalTemplate(id: 'bike', title: 'Bike', icon: Icons.motorcycle, themeColor: Colors.orange, basePriority: 40),
    GoalTemplate(id: 'car', title: 'Car', icon: Icons.directions_car, themeColor: Colors.blue, basePriority: 60),
    GoalTemplate(id: 'house', title: 'House', icon: Icons.home, themeColor: Colors.teal, basePriority: 80),
    GoalTemplate(id: 'phone', title: 'Phone', icon: Icons.smartphone, themeColor: Colors.purple, basePriority: 30),
    GoalTemplate(id: 'education', title: 'Education', icon: Icons.school, themeColor: Colors.indigo, basePriority: 85),
    GoalTemplate(id: 'child_education', title: 'Child Education', icon: Icons.child_care, themeColor: Colors.pink, basePriority: 90),
    GoalTemplate(id: 'vacation', title: 'Vacation', icon: Icons.flight_takeoff, themeColor: Colors.cyan, basePriority: 40),
    GoalTemplate(id: 'wedding', title: 'Wedding', icon: Icons.favorite, themeColor: Colors.redAccent, basePriority: 70),
    GoalTemplate(id: 'emergency', title: 'Emergency Fund', icon: Icons.health_and_safety, defaultFundingStrategy: 'AUTO_TRANSFER', themeColor: Colors.red, basePriority: 100),
    GoalTemplate(id: 'investment', title: 'Investment', icon: Icons.trending_up, defaultFundingStrategy: 'RECURRING', themeColor: Colors.green, basePriority: 75),
    GoalTemplate(id: 'medical', title: 'Medical Fund', icon: Icons.medical_services, defaultFundingStrategy: 'AUTO_TRANSFER', themeColor: Colors.red, basePriority: 95),
    GoalTemplate(id: 'business', title: 'Business', icon: Icons.business_center, themeColor: Colors.blueGrey, basePriority: 80),
    GoalTemplate(id: 'retirement', title: 'Retirement', icon: Icons.elderly, defaultFundingStrategy: 'RECURRING', themeColor: Colors.deepPurple, basePriority: 90),
    GoalTemplate(id: 'home_renovation', title: 'Home Renovation', icon: Icons.handyman, themeColor: Colors.brown, basePriority: 50),
    GoalTemplate(id: 'festival', title: 'Festival', icon: Icons.celebration, themeColor: Colors.amber, basePriority: 40),
    GoalTemplate(id: 'custom', title: 'Custom', icon: Icons.star, themeColor: Colors.grey, basePriority: 50),
  ];
}
