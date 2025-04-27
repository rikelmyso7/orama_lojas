import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orama_lojas/routes/routes.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  //final CheckUpdates checkUpdates = CheckUpdates();
  //final FlutterAppInstaller flutterAppInstaller = FlutterAppInstaller();
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
    _startAnimaton();
  }

  Future<void> _checkLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await GetStorage().write('userId', user.uid); // Salva o UID
      Navigator.of(context).pushReplacementNamed(RouteName.relatorios);
    } else {
      Navigator.of(context).pushReplacementNamed(RouteName.login);
    }
  }

  Future<void> _startAnimaton() async {
    Timer(Duration(seconds: 5), _checkLoginStatus);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
          child: FadeTransition(
              opacity: _animation,
              child: Container(
                height: double.infinity,
                width: double.infinity,
                color: Color(0xff006764),
                child: Center(
                  child: Image.asset(
                    'lib/assets/splashscreen.png',
                  ),
                ),
              ))),
    );
  }
}
