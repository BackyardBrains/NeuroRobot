import 'dart:io';

import 'package:auto_orientation/auto_orientation.dart';
import 'package:fialogs/fialogs.dart';
import 'package:flutter/material.dart';
import 'package:neurorobot/brands/brandguide.dart';
import 'package:neurorobot/pages/createbrain_page.dart';
import 'package:neurorobot/pages/designbrain_page.dart';
import 'package:neurorobot/pages/welcome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux){
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(800, 600),
      size: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

  }else{
    AutoOrientation.landscapeLeftMode();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'NeuroRobot'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  TextEditingController ctlBrainName = TextEditingController(text:"");
  TextEditingController ctlBrainDescription = TextEditingController(text:"");

  int isInitialized = 0;
  late SharedPreferences prefs;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Widget welcomePage() {
    return WelcomePage(callback:(){
      print("Set String");
      setState(() {
      });
    });
  }

  Widget defaultPage(){
    return CreateBrainPage(callback:(action){
      if (action == "add_brain"){
        customDialog(  
            context,  
            content: Column(  
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [  
                const Text("Name of Brain", style: TextStyle(fontWeight: FontWeight.bold),),
                TextField(  
                  decoration: const InputDecoration(labelText: "Name of brain"),  
                  controller: ctlBrainName,
                ),  
                const SizedBox(
                  height:20,
                ),
                const Text(
                  "Description of Brain", style: TextStyle(fontWeight: FontWeight.bold)
                ),
                TextField(  
                  decoration: const InputDecoration(labelText: "Description of brain"),  
                  controller: ctlBrainDescription,
                ), 
                const SizedBox(
                  height:20,
                ),
                Row(              
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: (){
                        Navigator.pop(context);
                      }, 
                      child: const Text("Cancel")
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                      ),
                      onPressed: (){
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DesignBrainPage(),
                          ),
                        );
                      }, 
                      child: const Text("Save Brain", style: TextStyle(color: Colors.white),),
                    ),
                  ],
                )
              ]
            ),  
            positiveButtonText: "",  
            positiveButtonAction: () {},  
            negativeButtonText: "",
            negativeButtonAction: () {},  
            neutralButtonAction: () {  
            },  
            hideNeutralButton: true,  
            closeOnBackPress: true,  
        );
      }
    });
  }

  @override
  void initState(){
    super.initState();
    SharedPreferences.getInstance().then((sp) {
      prefs = sp;
      isInitialized = 1;
      setState(() => {});
    });

  }
  @override
  Widget build(BuildContext context) {
    print("isInitialized");
    print(isInitialized);
    if (isInitialized==1){
      isInitialized = 2;
      print(prefs.getString("welcome"));
      if (prefs.getString("welcome") == null){
        // prefs.setString("welcome", "home");
        return DesignBrainPage();
      }else{ 
        // return defaultPage();
        return DesignBrainPage();
      }

    }else
    if(isInitialized >= 2){
      // return defaultPage();
      return DesignBrainPage();
    }

    return const SizedBox();

  }
  
}
