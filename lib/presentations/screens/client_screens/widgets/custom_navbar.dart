import 'package:flutter/material.dart';
import 'package:simple_food/presentations/screens/client_screens/commandes_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/favorite_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/home_screen.dart';
import 'package:simple_food/presentations/screens/client_screens/profile_screen.dart';

Widget customNavBar(
  int currentIndex,
  Color? backgroundColor,
  BuildContext context,
) {
  List<Widget> screens = [
    const HomeScreenClient(),
    const CommandesScreen(),
    const FavorisScreen(),
    const ProfileScreen(),
  ];
  return BottomNavigationBar(
    backgroundColor: backgroundColor ?? Colors.green[200],
    items: [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
      BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Commandes"),
      BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favoris"),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
    ],
    onTap: (value) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screens[value]),
      );
    },
    currentIndex: currentIndex,
    showSelectedLabels: true,
    selectedItemColor: Colors.blue,
    selectedLabelStyle: TextStyle(
      color: Colors.blue,
      fontWeight: FontWeight.bold,
      fontSize: 15,
    ),
    unselectedItemColor: Colors.white,
    showUnselectedLabels: true,
    unselectedFontSize: 14,
    iconSize: 30,

    type: BottomNavigationBarType.fixed,
  );
}
