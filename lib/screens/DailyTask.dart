import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:final_fiverr_1_project/screens/Popups/metronome.dart';
import 'package:final_fiverr_1_project/screens/TaskPool.dart';
import 'package:final_fiverr_1_project/screens/componenets/metronome.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/get_core.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DailyTask extends StatefulWidget {
  const DailyTask({super.key});

  @override
  State<DailyTask> createState() => _DailyTaskState();
}

class _DailyTaskState extends State<DailyTask> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> allTasks = [];
  List<Map<String, dynamic>> displayedTasks = [];

  String getFormattedDate() {
    // Get current date and time
    DateTime now = DateTime.now();
    // Format the date as "day of week, month name, date, year"
    String formattedDate = DateFormat('EEEE, MMMM, d, yyyy').format(now);
    return formattedDate;
  }

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final tasksResponse = await supabase
          .from('tasks')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        allTasks = tasksResponse;
        _shuffleTasks(); // Set initial 3 random tasks
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load tasks: $e")));
    }
  }

  void _shuffleTasks() {
    setState(() {
      if (allTasks.isEmpty) {
        displayedTasks = [];
        return;
      }
      // Shuffle and pick 3 random tasks
      final shuffled = List<Map<String, dynamic>>.from(allTasks)..shuffle();
      displayedTasks = shuffled.take(3).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    //print(allTasks);

    return LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          double height = constraints.maxHeight;
        
        return Padding(
          padding: const EdgeInsets.only(left: 50,right: 50,top: 15),
          child: Column(
            spacing: 20,
            children: [
              Row(
                spacing: 8,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Daily Tasks",
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        getFormattedDate()
                      ),
                    ],
                  ),
                  Spacer(),
                ],
              ),
              width>=800? Row(
                spacing: 10,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _shuffleTasks();
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.black,
                      ),
                      child: Row(
                        spacing: 8,
                        children: [
                          HugeIcon(icon:  HugeIcons.strokeRoundedShuffle, color: Colors.white),
                          Text(
                            "Shuffle Tasks",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // InkWell(
                  //   onTap: () {
                  //     Get.to(MyApp());
                  //   },
                  //   child: Container(
                  //     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  //     decoration: BoxDecoration(
                  //       borderRadius: BorderRadius.circular(5),
                  //       border: Border.all(width: 1, color: Colors.black),
                  //     ),
                  //     child: Row(
                  //       spacing: 8,
                  //       children: [
                  //         Icon(Icons.add_box, color: Colors.black),
                  //         Text(
                  //           "Add Another Task",
                  //           style: TextStyle(color: Colors.black),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  Spacer(),
                  MetronomeApp(input1: 40, input2: 360)
                ],
              ):Column(
                spacing: 10,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _shuffleTasks();
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.black,
                      ),
                      child: Row(
                        spacing: 8,
                        children: [
                          HugeIcon(icon:  HugeIcons.strokeRoundedShuffle, color: Colors.white),
                          Text(
                            "Shuffle Tasks",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // InkWell(
                  //   onTap: () {
                  //     Get.to(MyApp());
                  //   },
                  //   child: Container(
                  //     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  //     decoration: BoxDecoration(
                  //       borderRadius: BorderRadius.circular(5),
                  //       border: Border.all(width: 1, color: Colors.black),
                  //     ),
                  //     child: Row(
                  //       spacing: 8,
                  //       children: [
                  //         Icon(Icons.add_box, color: Colors.black),
                  //         Text(
                  //           "Add Another Task",
                  //           style: TextStyle(color: Colors.black),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  
                  MetronomeApp(input1: 40, input2: 360)
                ],
              ),
              //Container(child: MetronomeWidget(startValue: 20, endValue: 80)),
              SizedBox(
                height: 400,
                child: ListView.builder(
                  itemCount: displayedTasks.length, // Fixed to 3 items
                  //physics: NeverScrollableScrollPhysics(), // Disable scrolling
                  itemBuilder: (context, index) {
                    if (displayedTasks.length <= index) {
                      return ListTile(
                        title: Text("No tasks available"),
                        subtitle: Text("Add more tasks to shuffle"),
                      );
                    }
                    final task = displayedTasks[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Card(
                        color: Colors.white,
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return CustomDialog(task: task);
                              },
                            );
                          },
                          child: ListTile(
                            subtitle: Container(
                              padding: EdgeInsets.symmetric(vertical: 5),
                              child: Column(
                                spacing: 10,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    spacing: 5,
                                    children: [
                                      Text('${task['name'] ?? 'Unnamed'}'),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            width: 1,
                                            color: Colors.black,
                                          ),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Text('${task['category'] ?? 'N/A'}'),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    spacing: 5,
                                    children: [
                                      HugeIcon(icon:  HugeIcons.strokeRoundedClock01, color: Colors.black),
                                      Text('${task['duration'] ?? 0} min'),
                                      SizedBox(width: 5),
                                      HugeIcon(icon:  HugeIcons.strokeRoundedMusicNote04, color: Colors.black),
        
                                      Text(
                                        'BPM Range: ${task['bgm_range']['from'] ?? 'N/A'} to ${task['bgm_range']['to'] ?? 'N/A'}',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              icon: HugeIcon(icon:  HugeIcons.strokeRoundedDelete02, color: Colors.red),
                              onPressed: () {
                                setState(() {
          displayedTasks.removeAt(index);
        });
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class CustomDialog extends StatelessWidget {

  final Map<String, dynamic> task;

  const CustomDialog({Key? key, required this.task}) : super(key: key);

  Future<void> _showFilePreviewDialog(BuildContext context,String attachmentUrl) async {
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

   Widget _buildAttachmentContainer(BuildContext context,String attachmentUrl) {
  // Extract the file name from the URL (for display purposes)
  String fileName = attachmentUrl.split('/').last;

  return InkWell(
    onTap: () => _showFilePreviewDialog(context,attachmentUrl),
    child: Container(
      width: 150,
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file, size: 16),
          SizedBox(width: 5),
          Text(
            fileName.length > 20 ? '${fileName.substring(0, 12)}...' : fileName,
            style: TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(
        10,
      ), // Optional: Add padding around the dialog
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          double height = constraints.maxHeight;
          return Container(
            width: width>=1400? MediaQuery.of(context).size.width * 0.6 :MediaQuery.of(context).size.width * 0.8, // 80% of screen width
            height:
                MediaQuery.of(context).size.height * 0.80, // 80% of screen height
            padding: EdgeInsets.all(20), // Inner padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
            child: width <1050 ? SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    
                    child: Column(
                      spacing: 8,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task["name"],style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                        Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            width: 1,
                                            color: Colors.black,
                                          ),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Text('${task['category'] ?? 'N/A'}'),
                                      ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: VideoPlayerScreen(
                            videoUrl: task["youtube_url"],
                          ),
                        ),
                        Row(
                          spacing: 8,
                          children: [
                            HugeIcon(icon:  HugeIcons.strokeRoundedEdit01, color: Colors.black),
                            Text("Notes")
                            
                          ],
                        )
                        ,Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 10,vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(task["notes"],overflow: TextOverflow.ellipsis,maxLines: 2,),
                        ),
                        Wrap(
                                                    spacing: 8.0,
                                                    runSpacing: 8.0,
                                                    children: (task['attachments'] as List).map((attachment) {
                                                      return _buildAttachmentContainer(context,attachment);
                                                    }).toList(),
                                                  ),
                      ],
                    ),
                  ),
                  Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        spacing: 12,
                        children: [
                          SizedBox(height: 50,),
                          MetronomeApp(input1: int.parse( task['bgm_range']['from']), input2: int.parse( task['bgm_range']['to'])),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 8,
                              children: [
                                HugeIcon(icon:  HugeIcons.strokeRoundedClock01, color: Colors.black),
                                                      Text('Duration: ${task['duration'] ?? 0} min'),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 8,
                              children: [
                                HugeIcon(icon:  HugeIcons.strokeRoundedAttachment, color: Colors.black),
                                TextButton(onPressed: () async {
                                  final Uri url = Uri.parse(task["youtube_url"]);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      throw "Could not launch $url";
                    }
                                }, child: Text("In Youtube",style: TextStyle(color: Colors.blueAccent),)),
                              ],
                            ),
                          )
                        
                        ],
                      ),
                      ),
                ],
              ),
            ):SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Container(
                          
                          child: Column(
                            spacing: 8,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task["name"],style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                              Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  width: 1,
                                                  color: Colors.black,
                                                ),
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                              child: Text('${task['category'] ?? 'N/A'}'),
                                            ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: VideoPlayerScreen(
                                  videoUrl: task["youtube_url"],
                                ),
                              ),
                              Row(
                                spacing: 8,
                                children: [
                                  HugeIcon(icon:  HugeIcons.strokeRoundedEdit01, color: Colors.black),
                                  Text("Notes")
                            
                                ],
                              )
                              ,Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(horizontal: 10,vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10)
                                ),
                                child: Text(task["notes"],overflow: TextOverflow.ellipsis,maxLines: 2,),
                              ),
                              Wrap(
                                                          spacing: 8.0,
                                                          runSpacing: 8.0,
                                                          children: (task['attachments'] as List).map((attachment) {
                                                            return _buildAttachmentContainer(context,attachment);
                                                          }).toList(),
                                                        ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(flex: 3, child: Container(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            spacing: 12,
                            children: [
                              SizedBox(height: 50,),
                              MetronomeApp(input1: int.parse( task['bgm_range']['from']), input2: int.parse( task['bgm_range']['to'])),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10)
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10)
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 8,
                                  children: [
                                    HugeIcon(icon:  HugeIcons.strokeRoundedClock01, color: Colors.black),
                                                          Text('Duration: ${task['duration'] ?? 0} min'),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10)
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 8,
                                  children: [
                                    HugeIcon(icon:  HugeIcons.strokeRoundedAttachment, color: Colors.black),
                                    TextButton(onPressed: () async {
                                      final Uri url = Uri.parse(task["youtube_url"]);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          throw "Could not launch $url";
                        }
                                    }, child: Text("In Youtube",style: TextStyle(color: Colors.blueAccent),)),
                                  ],
                                ),
                              )
                            
                            ],
                          ),
                          )),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

