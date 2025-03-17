import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
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
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _taskNameController.dispose();
    _youtubeUrlController.dispose();
    _bgmFromController.dispose();
    _bgmToController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _adjustNumber(TextEditingController controller) {
    int current = int.tryParse(controller.text) ?? 0;
    setState(() => controller.text = (current + 1).toString());
  }

  void _adjustDuration(int delta) {
    int current = int.tryParse(_durationController.text) ?? 0;
    setState(() => _durationController.text = (current + delta).toString());
  }

  Widget _buildFileUploadSection() {
    return Column(
      children: [
        SizedBox(height: 5,),
        Row(
          children: [
            SizedBox(width: 100,),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
                )
              ),
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
              child: Row(
                spacing: 5,
                children: [
                  Icon(Icons.upload_rounded,color: Colors.white,)
                  , Text("Choose File",style: TextStyle(color: Colors.white),),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text("Supported formats: img, pdf, word, text"),
          ],
        ),
        _buildAttachmentList(_attachedFiles.map((file) => file.name).toList(), true),
      ],
    );
  }

  Widget _buildLinkAttachmentSection() {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(width: 100,),
            Expanded(
              child: TextField(
                controller: _linkController,
                decoration: InputDecoration(
                              labelText: 'Put Link Here.',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.title),
                            ),
              ),
            ),
            ElevatedButton(
              child: Row(
                spacing: 5,
                children: [
                  Icon(Icons.link,color: Colors.white,)
                  , Text("Add Link",style: TextStyle(color: Colors.white),),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
                )
              ),
              onPressed: () {
                if (_linkController.text.isNotEmpty) {
                  setState(() => _attachedLinks.add(_linkController.text));
                  _linkController.clear();
                }
              },
            ),
          ],
        ),
        _buildAttachmentList(_attachedLinks, false),
      ],
    );
  }

  Widget _buildAttachmentList(List<String> items, bool isFile) {
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
      Get.snackbar("Success", "Task added successfully");
      Navigator.pop(context); // Return to the main screen
      setState(() {}); // Refresh the parent state if needed
    } catch (e) {
      Get.snackbar("Error", "Failed to save task: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        title: const Text("Add New Task"),
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          double height = constraints.maxHeight;
          return Row(
            children: [
              Expanded(
                flex: width>1300? 3 : 4,
                child: Container(
                  padding: EdgeInsets.only(top: 12,left: 12,right: 5),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        
                        _buildFormRow("Name", TextField(
                          controller: _taskNameController,
                          decoration: InputDecoration(
                                        labelText: 'Enter exercise name here.',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        prefixIcon: const Icon(Icons.title),
                                      ),
                        )),
                        _buildFormRow("Select Category", FutureBuilder<List<Map<String, dynamic>>>(
                      future: supabase.from('categories').select('categories'),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        
                        return DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          items: snapshot.data!.map((doc) {
                            return DropdownMenuItem<String>(
                    value: doc['categories'],
                    child: Text(
                      doc['categories'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500, // Bold similar to image
                        color: Colors.black, // Adjust color if needed
                      ),
                    ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedCategory = value),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                            border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded border
                    borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                            ),
                          ),
                          dropdownColor: Colors.white, // Background color of dropdown
                          borderRadius: BorderRadius.circular(8), // Rounded dropdown
                        );
                      },
                    )
                    ),
                        _buildFormRow("YouTube URL", TextField(
                          controller: _youtubeUrlController,
                          decoration: InputDecoration(
                                        labelText: 'Enter Youtube URL.',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        prefixIcon: const Icon(Icons.link),
                                      ),
                        )),
                        _buildFormRow("BPM Range", Row(
                          children: [
                            SizedBox(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => _adjustNumber(_bgmFromController),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: TextField(
                                      controller: _bgmFromController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        labelText: '-',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        //prefixIcon: const Icon(Icons.title),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _adjustNumber(_bgmFromController),
                                  ),
                                ],
                              ),
                            ),
                            const Text(" to "),
                            SizedBox(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => _adjustNumber(_bgmToController),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: TextField(
                                      controller: _bgmToController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        labelText: '-',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        //prefixIcon: const Icon(Icons.title),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _adjustNumber(_bgmToController),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )),
                        _buildFormRow("Duration (Min)", Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => _adjustDuration(-1),
                            ),
                            //const SizedBox(width: 8),
                            SizedBox(
                              width: 220,
                              child: TextField(
                                controller: _durationController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                        labelText: 'Time in minutes',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        //prefixIcon: const Icon(Icons.title),
                                      ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _adjustDuration(1),
                            ),
                          ],
                        )),
                        _buildFormRow("Notes", SizedBox(
                          height: 100,
                          child: TextField(
                            maxLines: 3,
                            controller: _notesController,
                            decoration: InputDecoration(
                                          labelText: 'Enter your notes here',
                                          
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          prefixIcon: const Icon(Icons.note),
                                        ),
                          ),
                        )),
                        _buildFormRow("Attachment", ToggleButtons(
                          selectedColor: Colors.blue.shade400,
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
                        _isFileUpload ? _buildFileUploadSection() : _buildLinkAttachmentSection(),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15,horizontal: 30),
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)
                          )
                        ),
                          onPressed: (){
                            _saveTask();
                            Navigator.pop(context);
                          },
                          child: const Text("Add Task",style: TextStyle(color: Colors.white),),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              width>1300? Expanded(
                flex: 3,
                child: Container(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Image.network("https://i.im.ge/2025/03/17/pDlYcL.WhatsApp-Image-2025-03-17-at-14-10-18-818de6e5-removebg-preview.png")
                            ,Text("Add a new guitar practice task to your pool.",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                            
                          ],
                          
                        ),
                      )):SizedBox(width:1)
            ],
          );
        }
      ),
    );
  }

  Widget _buildFormRow(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100, child: Text(label)),
          Expanded(child: field),
        ],
      ),
    );
  }
}