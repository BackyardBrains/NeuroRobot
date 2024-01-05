import 'package:fialogs/fialogs.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neurorobot/brands/brandguide.dart';
import 'package:neurorobot/pages/createbrain_page.dart';
import 'package:neurorobot/pages/designbrain_page.dart';
import 'package:neurorobot/pages/welcome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
// WEB CHANGE
/*
import 'dart:io';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
*/
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

const this_is_small_change = true;

const _kShouldTestAsyncErrorOnInit = false;
const _kTestingCrashlytics = false;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // WEB CHANGE
  /*
  const fatalError = true;
  // Non-async exceptions
  FlutterError.onError = (errorDetails) {
    if (fatalError) {
      // If you want to record a "fatal" exception
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      // ignore: dead_code
    } else {
      // If you want to record a "non-fatal" exception
      // FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
    }
  };
  // Async exceptions
  PlatformDispatcher.instance.onError = (error, stack) {
    if (fatalError) {
      // If you want to record a "fatal" exception
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      // ignore: dead_code
    } else {
      // If you want to record a "non-fatal" exception
      // FirebaseCrashlytics.instance.recordError(error, stack);
    }
    return true;
  };
  */
  // WEB CHANGE
  /*
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
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
  } else {
    AutoOrientation.landscapeLeftMode();
  }
  */

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'NeuroRobot'),
      // home: DesignBrainPage(),
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
  TextEditingController ctlBrainName = TextEditingController(text: "");
  TextEditingController ctlBrainDescription = TextEditingController(text: "");
  // WEB CHANGE
  /*
  late Future<void> _initializeFlutterFireFuture;
  */

  int isInitialized = 0;
  late SharedPreferences prefs;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Widget welcomePage() {
    return WelcomePage(callback: () {
      print("Set String");
      setState(() {});
    });
  }

  Widget defaultPage() {
    return CreateBrainPage(callback: (action) {
      if (action == "add_brain") {
        customDialog(
          context,
          content:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              "Name of Brain",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Name of brain"),
              controller: ctlBrainName,
            ),
            const SizedBox(
              height: 20,
            ),
            const Text("Description of Brain",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              decoration:
                  const InputDecoration(labelText: "Description of brain"),
              controller: ctlBrainDescription,
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DesignBrainPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Save Brain",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            )
          ]),
          positiveButtonText: "",
          positiveButtonAction: () {},
          negativeButtonText: "",
          negativeButtonAction: () {},
          neutralButtonAction: () {},
          hideNeutralButton: true,
          closeOnBackPress: true,
        );
      }
    });
  }

  Future<void> _testAsyncErrorOnInit() async {
    Future<void>.delayed(const Duration(seconds: 2), () {
      final List<int> list = <int>[];
      print(list[100]);
    });
  }

  Future<void> _initializeFlutterFire() async {
    // WEB CHANGE
    /*
    if (_kTestingCrashlytics) {
      // Force enable crashlytics collection enabled if we're testing it.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    } else {
      // Else only enable it in non-debug builds.
      // You could additionally extend this to allow users to opt-in.
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
    }
    */

    if (_kShouldTestAsyncErrorOnInit) {
      await _testAsyncErrorOnInit();
    }
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((sp) {
      prefs = sp;
      isInitialized = 1;
      setState(() => {});
    });
    // WEB CHANGE
    /*
    _initializeFlutterFireFuture = _initializeFlutterFire();
    */
  }

  @override
  Widget build(BuildContext context) {
    // print("isInitialized");
    // print(isInitialized);
    if (isInitialized == 1) {
      isInitialized = 2;
      // print(prefs.getString("welcome"));
      if (prefs.getString("welcome") == null) {
        // prefs.setString("welcome", "home");
        return DesignBrainPage();
      } else {
        // return defaultPage();
        return DesignBrainPage();
      }
    } else if (isInitialized >= 2) {
      // return defaultPage();
      return DesignBrainPage();
    }

    return const SizedBox();
  }
}
