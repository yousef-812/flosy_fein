import 'package:flutter/material.dart';

class CategoryModel {
  final String name;
  final IconData icon;
  final Color color;

  CategoryModel({
    required this.name,
    required this.icon,
    required this.color,
  });

  // Predesigned list of default categories for the app
  static List<CategoryModel> get defaultCategories => [
    CategoryModel(name: 'طعام وشراب', icon: Icons.fastfood, color: Colors.orange),
    CategoryModel(name: 'مواصلات', icon: Icons.directions_car, color: Colors.blue),
    CategoryModel(name: 'تسوق', icon: Icons.shopping_bag, color: Colors.purple),
    CategoryModel(name: 'سكن وفواتير', icon: Icons.home, color: Colors.red),
    CategoryModel(name: 'صحة وعلاج', icon: Icons.medical_services, color: Colors.teal),
    CategoryModel(name: 'ترفيه وسفر', icon: Icons.movie, color: Colors.pink),
    CategoryModel(name: 'تعليم', icon: Icons.school, color: Colors.indigo),
    CategoryModel(name: 'أخرى', icon: Icons.more_horiz, color: Colors.grey),
  ];
}
