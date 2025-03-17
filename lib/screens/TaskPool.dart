import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:final_fiverr_1_project/screens/Popups/addTask.dart';
import 'package:final_fiverr_1_project/screens/Popups/editTask.dart';
import 'package:final_fiverr_1_project/screens/Popups/manageCat.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class MainTaskPool extends StatefulWidget {
  const MainTaskPool({super.key});

  @override
  State<MainTaskPool> createState() => _MainTaskPoolState();
}

class _MainTaskPoolState extends State<MainTaskPool> {

  String? _selectedCategoryForFilter;

  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _youtubeUrlController = TextEditingController();
  final TextEditingController _bgmFromController = TextEditingController();
  final TextEditingController _bgmToController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  String? _selectedCategory;
  bool _isFileUpload = true;
  List<PlatformFile> _attachedFiles = [];
  List<String> _attachedLinks = [];

  int _categoryVersion = 0;  // Add this line
  int _taskVersion = 0;
  

  

  List<Map<String, dynamic>> _allTasks = [];
  List<String> _categoryNames = ['All']; // Start with "All" tab

  final supabase = Supabase.instance.client;

  // Add a key to force FutureBuilder to rebuild
  final _categoryListKey = GlobalKey();

  Future<void> _fetchInitialData() async {
    try {
      // Fetch all tasks
      final tasksResponse = await supabase.from('tasks').select().order('created_at', ascending: false);
      final categoriesResponse = await supabase.from('categories').select('categories');

      setState(() {
        _allTasks = tasksResponse;
        _categoryNames = ['All'] + categoriesResponse.map((c) => c['categories'] as String).toList();
      });
    } catch (e) {
      //Get.snackbar("Error", "Failed to load initial data: $e");
    }
  }

  Future<void> _showAddTaskDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Add New Task"),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Add a new guitar practice task to your pool.",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      _buildFormRow("Name", TextField(
                        controller: _taskNameController,
                        decoration: const InputDecoration(hintText: "Enter task name"),
                      )),
                      _buildFormRow("Category", FutureBuilder<List<Map<String, dynamic>>>(
                        future: supabase.from('categories').select('categories'),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          return DropdownButton<String>(
                            value: _selectedCategory,
                            items: snapshot.data!.map((doc) {
                              return DropdownMenuItem<String>(
                                value: doc['categories'],
                                child: Text(doc['categories']),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedCategory = value),
                            hint: const Text("Select Category"),
                          );
                        },
                      )),
                      _buildFormRow("YouTube URL", TextField(
                        controller: _youtubeUrlController,
                        decoration: const InputDecoration(hintText: "Enter YouTube URL"),
                      )),
                      _buildFormRow("BPM Range", Row(
                        children: [
                          _buildNumberField(_bgmFromController, setState),
                          const Text(" to "),
                          _buildNumberField(_bgmToController, setState),
                        ],
                      )),
                      _buildFormRow("Duration (Min)", Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => _adjustDuration(-1, setState),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _adjustDuration(1, setState),
                          ),
                        ],
                      )),
                      _buildFormRow("Notes", TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(hintText: "Enter notes"),
                      )),
                      _buildFormRow("Attachment", ToggleButtons(
                        isSelected: [_isFileUpload, !_isFileUpload],
                        onPressed: (index) => setState(() => _isFileUpload = index == 0),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text("Upload File"),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text("Attach Link"),
                          ),
                        ],
                      )),
                      _isFileUpload
                          ? _buildFileUploadSection(setState)
                          : _buildLinkAttachmentSection(setState),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveTask,
                        child: const Text("Add Task"),
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
  }

  Widget _buildFormRow(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label)),
          Expanded(child: field),
        ],
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, StateSetter setState) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () => _adjustNumber(controller, -1, setState),
        ),
        SizedBox(
          width: 60,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _adjustNumber(controller, 1, setState),
        ),
      ],
    );
  }

  void _adjustNumber(TextEditingController controller, int delta, StateSetter setState) {
    int current = int.tryParse(controller.text) ?? 0;
    setState(() => controller.text = (current + delta).toString());
  }

  void _adjustDuration(int delta, StateSetter setState) {
    int current = int.tryParse(_durationController.text) ?? 0;
    setState(() => _durationController.text = (current + delta).toString());
  }

  Widget _buildFileUploadSection(StateSetter setState) {
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpg', 'png', 'pdf', 'doc', 'docx', 'txt'],
                  );
                  if (result != null) {
                    setState(() => _attachedFiles.addAll(result.files));
                  }
                } catch (e) {
                  Get.snackbar("Error", "Failed to pick file: $e");
                }
              },
              child: const Text("Choose File"),
            ),
            const SizedBox(width: 10),
            const Text("Supported formats: img, pdf, word, text"),
          ],
        ),
        _buildAttachmentList(_attachedFiles.map((file) => file.name).toList(), setState, isFile: true),
      ],
    );
  }

  Widget _buildLinkAttachmentSection(StateSetter setState) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _linkController,
                decoration: const InputDecoration(hintText: "Put link here"),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (_linkController.text.isNotEmpty) {
                  setState(() => _attachedLinks.add(_linkController.text));
                  _linkController.clear();
                }
              },
            ),
          ],
        ),
        _buildAttachmentList(_attachedLinks, setState, isFile: false),
      ],
    );
  }

  Widget _buildAttachmentList(List<String> items, StateSetter setState, {required bool isFile}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(items[index]),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => isFile ? _attachedFiles.removeAt(index) : _attachedLinks.removeAt(index)),
          ),
        );
      },
    );
  }

  Future<void> _saveTask() async {
    if (_taskNameController.text.isEmpty || _selectedCategory == null || _durationController.text.isEmpty) {
      Get.snackbar("Error", "Please fill all required fields");
      return;
    }

    try {
      List<String> uploadedFileUrls = [];
      if (_isFileUpload && _attachedFiles.isNotEmpty) {
        for (PlatformFile file in _attachedFiles) {
          String filePath = 'tasks/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          if (kIsWeb) {
            if (file.bytes == null) {
              Get.snackbar("Error", "File bytes not available");
              return;
            }
            await supabase.storage.from('task-attachments').uploadBinary(filePath, file.bytes!);
          } else {
            if (file.path == null) {
              Get.snackbar("Error", "File path not available");
              return;
            }
            await supabase.storage.from('task-attachments').upload(filePath, File(file.path!));
          }
          String downloadUrl = supabase.storage.from('task-attachments').getPublicUrl(filePath);
          uploadedFileUrls.add(downloadUrl);
        }
      }

      await supabase.from('tasks').insert({
        'name': _taskNameController.text,
        'category': _selectedCategory,
        'youtube_url': _youtubeUrlController.text,
        'bgm_range': {
          'from': _bgmFromController.text,
          'to': _bgmToController.text,
        },
        'duration': int.parse(_durationController.text),
        'notes': _notesController.text,
        'attachments': _isFileUpload ? uploadedFileUrls : _attachedLinks,
        'attachment_type': _isFileUpload ? 'file' : 'link',
      });
      setState(() {
        _taskVersion++;
        _fetchInitialData();
      });
      Get.snackbar("Success", "Task added successfully");
      Navigator.of(context).pop();
      _clearForm();
    } catch (e) {
      Get.snackbar("Error", "Failed to save task: $e");
    }
  }

  void _clearForm() {
    _taskNameController.clear();
    _selectedCategory = null;
    _youtubeUrlController.clear();
    _bgmFromController.clear();
    _bgmToController.clear();
    _durationController.clear();
    _notesController.clear();
    _attachedFiles.clear();
    _attachedLinks.clear();
    _isFileUpload = true;
    setState(() {});
  }

  Future<void> _addCategory(StateSetter setDialogState) async {
    if (_categoryController.text.isNotEmpty) {
      try {
        await supabase.from('categories').insert({
          'categories': _categoryController.text.trim(),
        });
        _categoryController.clear();
        setDialogState(() {}); // Trigger dialog rebuild
        setState(() {
        _categoryVersion++;
        _fetchInitialData();
      });
      } catch (e) {
        Get.snackbar("Error", "Failed to add category: $e");
      }
    }
  }

  Future<void> _editCategory(int id, String newName, StateSetter setDialogState) async {
    try {
      await supabase.from('categories').update({
        'categories': newName.trim(),
      }).eq('id', id);
      setDialogState(() {});
      setState(() {
        _categoryVersion++;
        _fetchInitialData();
      });  // Trigger dialog rebuild
    } catch (e) {
      Get.snackbar("Error", "Failed to edit category: $e");
    }
  }

  Future<void> _deleteCategory(int id, StateSetter setDialogState) async {
    try {
      await supabase.from('categories').delete().eq('id', id);
      setDialogState(() {});
      setState(() {
        _categoryVersion++;
        _fetchInitialData();
      });
        // Trigger dialog rebuild
    } catch (e) {
      Get.snackbar("Error", "Failed to delete category: $e");
    }
  }

//   Widget _buildYouTubePlayer(String url) {
//   final videoId = YoutubePlayer.convertUrlToId(url);
//   if (videoId == null) {
//     return const Text('Invalid YouTube URL');
//   }

//   return Container(
//     constraints: const BoxConstraints(
//       maxHeight: 300, // Adjust this value as needed
//     ),
//     child: YouTubePlayerWidget(videoId: videoId),
//   );
// }
  
  Widget _buildAttachmentContainer(String attachmentUrl) {
  // Extract the file name from the URL (for display purposes)
  String fileName = attachmentUrl.split('/').last;

  return InkWell(
    onTap: () => _showFilePreviewDialog(attachmentUrl),
    child: Container(
      width: 150,
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        spacing: 4,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file, size: 16),
          
          Text(
            fileName.length > 20 ? '${fileName.substring(0, 12)}...' : fileName,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    ),
  );
}
  
  Future<void> _showFilePreviewDialog(String attachmentUrl) async {
  // Determine the file type based on the URL extension
  bool isImage = attachmentUrl.toLowerCase().endsWith('.png') ||
      attachmentUrl.toLowerCase().endsWith('.jpg') ||
      attachmentUrl.toLowerCase().endsWith('.jpeg');

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('File Preview'),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height * 0.5,
          child: isImage
              ? Image.network(
                  attachmentUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 40),
                      SizedBox(height: 10),
                      Text('Failed to load image'),
                    ],
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insert_drive_file, size: 50, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      'Preview not available for this file type',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // You can implement a way to open the link in a browser
                        // For Flutter, you might need a package like url_launcher
                        // For now, we'll just show a snackbar
                        Get.snackbar('Info', 'Open link: $attachmentUrl');
                      },
                      child: Text('Open File'),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      );
    },
  );
}


  // Method to update the task in the database
  Future<void> _updateTask(Map<String, dynamic> existingTask) async {
    if (_taskNameController.text.isEmpty || _selectedCategory == null || _durationController.text.isEmpty) {
      Get.snackbar("Error", "Please fill all required fields");
      return;
    }

    try {
      List<String> updatedAttachments = [];
      if (_isFileUpload && _attachedFiles.isNotEmpty) {
        for (PlatformFile file in _attachedFiles) {
          String filePath = 'tasks/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          if (kIsWeb) {
            if (file.bytes == null) {
              Get.snackbar("Error", "File bytes not available");
              return;
            }
            await supabase.storage.from('task-attachments').uploadBinary(filePath, file.bytes!);
          } else {
            if (file.path == null) {
              Get.snackbar("Error", "File path not available");
              return;
            }
            await supabase.storage.from('task-attachments').upload(filePath, File(file.path!));
          }
          String downloadUrl = supabase.storage.from('task-attachments').getPublicUrl(filePath);
          updatedAttachments.add(downloadUrl);
        }
      } else if (!_isFileUpload && _attachedLinks.isNotEmpty) {
        updatedAttachments = List<String>.from(_attachedLinks);
      } else {
        updatedAttachments = List<String>.from(existingTask['attachments'] ?? []);
      }

      await supabase.from('tasks').update({
        'name': _taskNameController.text,
        'category': _selectedCategory,
        'youtube_url': _youtubeUrlController.text,
        'bgm_range': {
          'from': _bgmFromController.text,
          'to': _bgmToController.text,
        },
        'duration': int.parse(_durationController.text),
        'notes': _notesController.text,
        'attachments': updatedAttachments,
        'attachment_type': _isFileUpload ? 'file' : 'link',
      }).eq('id', existingTask['id']);

      setState(() {
        _taskVersion++;
        _fetchInitialData();
      });
      Get.snackbar("Success", "Task updated successfully");
      Navigator.of(context).pop();
      _clearForm();
    } catch (e) {
      Get.snackbar("Error", "Failed to update task: $e");
    }
  }

  // Method to delete the task
  Future<void> _deleteTask(int taskId) async {
    try {
      await supabase.from('tasks').delete().eq('id', taskId);
      setState(() {
        _taskVersion++;
        _fetchInitialData();
      });
      Get.snackbar("Success", "Task deleted successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to delete task: $e");
    }
  }


@override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchInitialData();
  }

@override
Widget build(BuildContext context) {
  setState(() {
    _fetchInitialData();
  });
  return Padding(
    padding: const EdgeInsets.only(left: 50,right: 50,top: 15),
    child: Column(
      mainAxisSize: MainAxisSize.min, // Use min to avoid taking max height unnecessarily
      children: [
        Row(
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Task Pool", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                Text("Manage your guitar practice exercises"),
              ],
            ),
            const Spacer(),
            InkWell(
              onTap: (){
                Get.to(ManageCategoriesScreen(),transition: Transition.upToDown,duration: Duration(seconds: 1));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(width: 1, color: Colors.black)),
                child:  Row(children: [HugeIcon(icon: HugeIcons.strokeRoundedSettings03,color: Colors.black,), SizedBox(width: 8), Text("Manage Categories")]),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: (){
                Get.to(AddTaskScreen(),transition: Transition.upToDown,duration: Duration(seconds: 1));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: Colors.black),
                child:  Row(children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedAddCircle, color: Colors.white),
                  SizedBox(width: 8),
                  Text("Add Task", style: TextStyle(color: Colors.white)),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_categoryNames.isEmpty)
          const CircularProgressIndicator()
        else
          DefaultTabController(
            length: _categoryNames.length,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Keep this column minimal too
              children: [
                SizedBox(
                  height: 50,
                  child: TabBar(
                    isScrollable: true,
                    tabs: _categoryNames.map((name) => Tab(text: name)).toList(),
                  ),
                ),
                Container( // Wrap TabBarView in a Container to control its height dynamically
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7, // Cap the height, but allow scrolling
                  ),
                  child: TabBarView(
                    children: _categoryNames.map((category) {
                      final tasks = category == 'All'
                          ? _allTasks
                          : _allTasks.where((task) => task['category'] == category).toList();
                      return tasks.isEmpty
                          ?  Center(child: Column(
                            spacing: 10,
                            children: [
                              SizedBox(height: 120,),
                              HugeIcon(icon:  HugeIcons.strokeRoundedMusicNote01, color: Colors.black,size: 120,),
                              Text("No items available for this category"),
                            ],
                          ))
                          : LayoutBuilder(
                            
                            builder: (context, constraints) {
                              double itemWidth = constraints.maxWidth / 2; // Adjust column count if needed
                              double itemHeight = itemWidth * 1.4; // Adjust based on content
                              double aspectRatio = itemWidth / itemHeight;
                              return GridView.builder(
                                shrinkWrap: true, // Let GridView size itself within the scroll view
                                //physics: const NeverScrollableScrollPhysics(), // Disable GridView’s own scrolling
                                padding: const EdgeInsets.all(16),
                                gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio:aspectRatio,
                                ),
                                itemCount: tasks.length,
                                itemBuilder: (context, index) {
                                  final task = tasks[index];
                                  return Card(
                                    color: Colors.white,
                                    elevation: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 14),
                                      child: Column(
                                        spacing: 8,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                task['name'] ?? 'Unnamed Task',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                              Spacer(),
                                              IconButton(onPressed: (){
                                                Get.to(EditTaskScreen(task: task));
                                              }, icon: HugeIcon(icon: HugeIcons.strokeRoundedEdit02, color: Colors.black),),
                                              IconButton(onPressed: (){
                                                setState(() {
                                                  _deleteTask(task['id']);
                                                });
                                              }, icon: HugeIcon(icon:  HugeIcons.strokeRoundedDelete01, color: Colors.red),)
                                            ],
                                          ),
                                          
                                          Row(
                                            spacing: 5,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 10,vertical: 3),
                                                decoration: BoxDecoration(
                                                  border: Border.all(width: 1,color: Colors.black),
                                                  borderRadius: BorderRadius.circular(30)
                                                ),
                                                child: Text('${task['category'] ?? 'N/A'}')),
                                                HugeIcon(icon:  HugeIcons.strokeRoundedClock01, color: Colors.black),
                                                Text('${task['duration'] ?? 0} min'),
                                            ],
                                          ),
                                          
                                          if (task['youtube_url']?.isNotEmpty ?? false)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: VideoPlayerScreen(videoUrl: task["youtube_url"],)),
                                        ),
                                          Row(
                                            spacing: 5,
                                            children: [
                                              HugeIcon(icon:  HugeIcons.strokeRoundedEdit01, color: Colors.black),
                                              Text("Notes")
                                            ],
                                          ),
                                          Text(task["notes"],maxLines: 2,overflow:  TextOverflow.ellipsis),
                                          
                                            
                                            
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Wrap(
                                                spacing: 8.0,
                                                runSpacing: 8.0,
                                                children: (task['attachments'] as List).map((attachment) {
                                                  return _buildAttachmentContainer(attachment);
                                                }).toList(),
                                              ),
                                            ),
                                          
                                        if (task['bgm_range'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Row(
                                                spacing: 8,
                                                children: [
                                                  HugeIcon(icon:  HugeIcons.strokeRoundedMusicNote01, color: Colors.black),
                                                  Text(
                                                    'BPM Range: ${task['bgm_range']['from'] ?? 'N/A'} to ${task['bgm_range']['to'] ?? 'N/A'}',
                                                    style: TextStyle(fontSize: 14),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

  Future<void> _showMyDialog1() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Manage Categories"),
              content: Container(
                width: MediaQuery.of(context).size.width * (1.5 / 4),
                height: MediaQuery.of(context).size.height * (2.5 / 3),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Add or Remove Practice Categories"),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _categoryController,
                              decoration: const InputDecoration(hintText: "Add a New Category"),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _addCategory(setDialogState),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        key: _categoryListKey,
                        future: supabase.from('categories').select(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return Column(
                            children: snapshot.data!.map((doc) {
                              TextEditingController _editController =
                                  TextEditingController(text: doc['categories']);
                              bool _isEditing = false;
                              return StatefulBuilder(
                                builder: (context, setInnerState) {
                                  return ListTile(
                                    title: _isEditing
                                        ? TextField(
                                            controller: _editController,
                                            autofocus: true,
                                          )
                                        : Text(doc['categories']),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _isEditing
                                            ? IconButton(
                                                icon: const Icon(Icons.check),
                                                onPressed: () async {
                                                  await _editCategory(doc['id'], _editController.text, setDialogState);
                                                  setInnerState(() => _isEditing = false);
                                                },
                                              )
                                            : IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () => setInnerState(() => _isEditing = true),
                                              ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteCategory(doc['id'], setDialogState),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          );
                        },
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
  }
}


class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isVideoLoaded = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    String videoId = extractYouTubeVideoId(widget.videoUrl);
    _controller = YoutubePlayerController(
      params: YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );
    if (videoId.isNotEmpty) {
      _controller.loadVideoById(videoId: videoId);
      _isVideoLoaded = true;
      _controller.stopVideo();
    }
    
    //   _controller.listen((_){
    //   _controller.pauseVideo();
    // });
    
  }

  String extractYouTubeVideoId(String url) {
    RegExp regExp = RegExp(
      r"(?:(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^\&?\/\s]{11}))",
      caseSensitive: false,
      multiLine: false,
    );

    RegExpMatch? match = regExp.firstMatch(url);
    return match != null ? match.group(1)! : "";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: YoutubePlayer(
        controller: _controller,
      ),
    );
  }
}