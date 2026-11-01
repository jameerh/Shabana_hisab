import 'package:flutter/material.dart';
import '../../main.dart';
import '../../data/database/database.dart';
import 'package:drift/drift.dart' as drift;
import 'category_icon_helper.dart';

class CategoryView extends StatefulWidget {
  @override
  _CategoryViewState createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  
  void _deleteCategory(Category cat) {
    database.deleteCategory(cat);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('कॅटेगरी डिलीट केली')),
    );
  }

  void _showCategoryDialog({Category? existingCat}) {
    TextEditingController nameCtrl = TextEditingController(text: existingCat?.name ?? '');
    TextEditingController keywordsCtrl = TextEditingController(text: existingCat?.keywords ?? '');
    String selectedType = existingCat?.type ?? 'Expense';

    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: Text(existingCat == null ? 'नवीन कॅटेगरी' : 'कॅटेगरी एडिट करा'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'कॅटेगरीचे नाव (उदा. किराणा)')),
            TextField(
              controller: keywordsCtrl, 
              decoration: const InputDecoration(labelText: 'कीवर्ड्स (स्वल्पविरामाने वेगळे करा)'),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedType,
              items: ['Income', 'Expense', 'Udhaari'].map((t) {
                String display = t;
                if(t == 'Income') display = 'जमा';
                if(t == 'Expense') display = 'खर्च';
                if(t == 'Udhaari') display = 'उधारी';
                return DropdownMenuItem(value: t, child: Text(display));
              }).toList(),
              onChanged: (val) {
                if (val != null) selectedType = val;
              },
              decoration: const InputDecoration(labelText: 'प्रकार'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('कॅन्सल')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;

              if (existingCat == null) {
                database.addCategory(CategoriesCompanion.insert(
                  name: nameCtrl.text.trim(),
                  keywords: keywordsCtrl.text.trim(),
                  type: selectedType,
                ));
              } else {
                database.updateCategory(existingCat.copyWith(
                  name: nameCtrl.text.trim(),
                  keywords: keywordsCtrl.text.trim(),
                  type: selectedType,
                ));
              }
              Navigator.pop(context);
            },
            child: Text(existingCat == null ? 'तयार करा' : 'अपडेट करा'),
          )
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('कॅटेगरी व्यवस्थापन'),
      ),
      body: StreamBuilder<List<Category>>(
        stream: database.watchAllCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data ?? [];
          
          if (categories.isEmpty) {
            return const Center(
              child: Text('अद्याप कोणतीही कॅटेगरी नाही.\n"किराणा" किंवा "इंधन" जोडण्यासाठी + वर टॅप करा!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final color = cat.type == 'Income' ? Colors.green : (cat.type == 'Expense' ? Colors.red : Colors.orange);

              return Dismissible(
                key: ValueKey(cat.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteCategory(cat),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.15), 
                      child: Icon(CategoryIconHelper.getIconForCategory(cat.name, cat.keywords), color: color)
                    ),
                    title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(cat.keywords.isEmpty ? "कोणतेही कीवर्ड जोडलेले नाहीत" : cat.keywords),
                    trailing: const Icon(Icons.edit, size: 20, color: Colors.grey),
                    onTap: () => _showCategoryDialog(existingCat: cat),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
