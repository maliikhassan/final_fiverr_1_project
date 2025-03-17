import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  _ManageCategoriesScreenState createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final supabase = Supabase.instance.client;
  final _categoryListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categoriesResponse = await supabase.from('categories').select();
      setState(() {});
    } catch (e) {
      Get.snackbar("Error", "Failed to load categories: $e");
    }
  }

  Future<void> _addCategory() async {
    if (_categoryController.text.isNotEmpty) {
      try {
        await supabase.from('categories').insert({
          'categories': _categoryController.text.trim(),
        });
        _categoryController.clear();
        _fetchCategories();
        ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Success: Category added successfully")));
      } catch (e) {
        ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to add category (Check Internet Connection)")));
      }
    }
  }

  Future<void> _deleteCategory(int id) async {
  try {
    // Fetch the category name before deleting it
    final categoryResponse = await supabase
        .from('categories')
        .select('categories')
        .eq('id', id)
        .single();

    final categoryName = categoryResponse['categories'];

    // Delete all tasks associated with this category
    await supabase
        .from('tasks')
        .delete()
        .eq('category', categoryName); // Assuming 'category' is the field in tasks table

    // Delete the category itself
    await supabase.from('categories').delete().eq('id', id);

    _fetchCategories();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Success: Category and related tasks deleted successfully")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to delete category and tasks (Check Internet Connection)")),
    );
  }
}

Future<void> _editCategory(int id, String newName) async {
  try {
    // Fetch the old category name before updating
    final categoryResponse = await supabase
        .from('categories')
        .select('categories')
        .eq('id', id)
        .single();

    final oldName = categoryResponse['categories'];

    // Update the category in the categories table
    await supabase
        .from('categories')
        .update({'categories': newName.trim()})
        .eq('id', id);

    // Update all tasks with the old category name to the new name
    await supabase
        .from('tasks')
        .update({'category': newName.trim()})
        .eq('category', oldName); // Assuming 'category' is the field in tasks table

    _fetchCategories();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Success: Category and related tasks updated successfully")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to update category and tasks (Check Internet Connection)")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        title: const Text("Manage Categories"),
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20,horizontal: 50),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add or Remove Practice Categories"),
            Row(
              spacing: 5,
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                              labelText: 'Add a new Category.',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon:  HugeIcon(icon: HugeIcons.strokeRoundedPlayListAdd, color: Colors.black),
                            ),
                  ),
                ),

                InkWell(
                  onTap: _addCategory,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 30,vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: Row(
                      spacing: 5,
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedAddCircle, color: Colors.white),
                        Text("Add Category",style: TextStyle(color: Colors.white),)
                      ],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                key: _categoryListKey,
                future: supabase.from('categories').select(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data![index];
                      TextEditingController _editController =
                          TextEditingController(text: doc['categories']);
                      bool _isEditing = false;
                      return StatefulBuilder(
                        builder: (context, setInnerState) {
                          return Card(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: ListTile(
                                title: _isEditing
                                    ? TextField(
                                        controller: _editController,
                                        autofocus: true,
                                        decoration: InputDecoration(
                                labelText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                //prefixIcon: const Icon(Icons.title),
                              ),
                                      )
                                    : Text(doc['categories'],style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _isEditing
                                        ? IconButton(
                                            icon: HugeIcon(icon: HugeIcons.strokeRoundedCheckList, color: Colors.black),
                                            onPressed: () async {
                                              await _editCategory(doc['id'], _editController.text);
                                              setInnerState(() => _isEditing = false);
                                            },
                                          )
                                        : IconButton(
                                            icon: HugeIcon(icon: HugeIcons.strokeRoundedEdit02, color: Colors.black),
                                            onPressed: () => setInnerState(() => _isEditing = true),
                                          ),
                                    IconButton(
                                      icon: HugeIcon(icon:  HugeIcons.strokeRoundedDelete01, color: Colors.red),
                                      onPressed: () => _deleteCategory(doc['id']),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}