import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orama_lojas/routes/routes.dart';
import 'package:orama_lojas/stores/stock_store.dart';
import 'package:provider/provider.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  String storeName = "Loja";

  @override
  void initState() {
    super.initState();
    validateAndSyncUserId();
  }

  Future<void> validateAndSyncUserId() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      await GetStorage().write('userId', currentUser.uid);
      updateStoreName(currentUser.uid);
    } else {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed(RouteName.login);
    }
  }

  void updateStoreName(String userId) {
    const storeNames = {
      "h0g6nwqiRKcM3VSFk6Wu4JFWe9k2": "Orama Paineiras",
      "gwYkGevTSZUuGpMQsKLQSlFHZpm2": "Orama Itupeva",
      "VNlSNV0SKEOACk9Cxcxwe4E2Rtm2": "Orama Retiro",
      "NQ9PFI86vvaWmQqARzygTylxqzh1": "Platz"
    };

    setState(() {
      storeName = storeNames[userId] ?? "Loja";
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StockStore>(context);

    return Drawer(
      child: _buildMenuContent(context),
    );
  }

  Widget _buildMenuContent(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          height: MediaQuery.of(context).size.height / 8,
          child: DrawerHeader(
            decoration: BoxDecoration(
              color: const Color(0xff60C03D),
            ),
            child: Text(
              storeName,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 26),
            ),
          ),
        ),
        ListTile(
          title: Row(
            children: [
              Text(
                'Relatórios',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
              ),
              SizedBox(width: 5),
              FaIcon(
                FontAwesomeIcons.folderOpen,
                size: 20,
              ),
            ],
          ),
          onTap: () {
            Navigator.of(context).pushNamed(RouteName.relatorios);
          },
        ),
        Divider(),
        // ListTile(
        //   title: Row(
        //     children: [
        //       Text(
        //         'Específico',
        //         style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
        //       ),
        //       SizedBox(width: 5),
        //       FaIcon(
        //         FontAwesomeIcons.solidPenToSquare,
        //         size: 20,
        //       ),
        //     ],
        //   ),
        //   onTap: () {
        //     Navigator.of(context).pushNamed(RouteName.especifico_view);
        //   },
        // ),
        // Divider(),
        ListTile(
          title: Row(
            children: [
              Text(
                'Trocar Conta',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
              ),
              SizedBox(width: 5),
              FaIcon(
                FontAwesomeIcons.arrowRightFromBracket,
                size: 20,
              ),
            ],
          ),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pushReplacementNamed(RouteName.login);
          },
        ),
        Divider(),
      ],
    );
  }
}
