import 'package:final_fiverr_1_project/screens/DailyTask.dart';
import 'package:final_fiverr_1_project/screens/TaskPool.dart';
import 'package:final_fiverr_1_project/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Future<void> _logout(BuildContext context) async {
  final supabase = Supabase.instance.client;
  final prefs = await SharedPreferences.getInstance();
  
  await supabase.auth.signOut();
  await prefs.remove('session_expiration');
  
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const LoginScreen()),
  );
}
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20,),
            Center(
              child: Row(
                spacing: 10,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ToggleButtons(
                    selectedColor: Colors.white,
                    selectedBorderColor: Colors.black,
                    fillColor: Colors.black,
                    constraints: BoxConstraints.expand(width: MediaQuery.of(context).size.width / 3),
                    borderRadius: BorderRadius.circular(10),
                    isSelected: [selectedIndex == 0, selectedIndex == 1],
                    onPressed: (int index) {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    
                    children: [
                      Padding(padding: EdgeInsets.all(8.0), child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 10,
                        children: [
                          HugeIcon(icon:  HugeIcons.strokeRoundedTaskDaily01, color: selectedIndex==0? Colors.white:Colors.black),
                          Text("Daily Exercises"),
                        ],
                      )),
                      Padding(padding: EdgeInsets.all(8.0), child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 10,
                        children: [
                          HugeIcon(icon:  HugeIcons.strokeRoundedPlayListFavourite01, color: selectedIndex==0? Colors.black:Colors.white),
                          Text("Tasks Pool"),
                        ],
                      )),
                    ],
                  ),
                  InkWell(
                    onTap: () => _logout(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8,horizontal: 15),
                      child: Row(
                        spacing: 5,
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedLogout01, color: Colors.white),
                          Text("Logout",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Load the selected widget dynamically
            selectedIndex == 0 ? DailyTask() : MainTaskPool(),
          ],
        ),
      ),
    );
  }
}

