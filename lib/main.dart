import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_food/presentations/screens/auth/login_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/home_screen.dart';
import 'package:simple_food/presentations/screens/cookers_screen.dart/index_screen.dart';
import 'package:simple_food/presentations/screens/livreur_screen.dart/index_screen.dart';
import 'package:simple_food/presentations/screens/welcome_screen/onboarding_screen.dart';
import 'package:simple_food/services/api_service.dart';
import 'package:simple_food/services/cart_service.dart';
import 'package:simple_food/services/cart_storage.dart';
import 'package:simple_food/services/auth_service.dart';
import 'package:simple_food/models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ApiService.init();
  } catch (e) {
    // log and continue to avoid blocking UI at startup
    // ignore: avoid_print
    print('ApiService.init error: $e');
  }
  try {
    await CartStorage.load();
  } catch (e) {
    // ignore: avoid_print
    print('CartStorage.load error: $e');
  }
  // Sauvegarde automatique du panier à chaque changement
  CartService.instance.items.addListener(() async {
    await CartStorage.save();
  });
  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  final bool loggedIn = ApiService.isAuthenticated;
  runApp(MyApp(isLoggedIn: loggedIn, hasSeenOnboarding: hasSeenOnboarding));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final bool hasSeenOnboarding;
  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.hasSeenOnboarding,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _loading = true;
  bool _loggedIn = false;
  bool _hasSeenOnboarding = false;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loggedIn = widget.isLoggedIn;
    _hasSeenOnboarding = widget.hasSeenOnboarding;
    _validate();
  }

  Future<void> _validate() async {
    if (_loggedIn) {
      final res = await AuthService.getProfile();
      if (mounted) {
        if (res['success'] == true) {
          final user = res['user'] as User;
          _role = user.role;
        } else {
          await ApiService.clearToken();
          _loggedIn = false;
        }
        setState(() => _loading = false);
      }
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFFDFBF6)),
        ),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFFDFBF6)),
      ),
      // Après l’onboarding, on affiche toujours la partie client.
      // Les écrans/flux qui nécessitent une connexion (commandes, profil,
      // création de commande, etc.) gèrent eux-mêmes la redirection ou
      // l’affichage d’un message invitant à se connecter.
      home: !_hasSeenOnboarding
          ? OnboardingScreen(onFinished: _completeOnboarding)
          : _loggedIn && _role == 'cuisinier'
          ? CookerDashboard()
          : _loggedIn && _role == 'livreur'
          ? LivreurDashboard()
          : const HomeScreenClient(),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    setState(() {
      _hasSeenOnboarding = true;
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
