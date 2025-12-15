import 'package:flutter/material.dart';
import 'package:orama_lojas/auth/authStateSwitcher.dart';
import 'package:orama_lojas/main.dart';
import 'package:orama_lojas/pages/checklist/add_checklist_page.dart';
import 'package:orama_lojas/pages/checklist/checklist_select_page.dart';
import 'package:orama_lojas/pages/add_rel_info.dart';
import 'package:orama_lojas/pages/formulario_page.dart';
import 'package:orama_lojas/pages/login_page.dart';
import 'package:orama_lojas/pages/relatorios_page.dart';
import 'package:orama_lojas/pages/splash_page.dart';

class RouteName {
  static const auth = '/';
  static const login = "/login";
  static const splash = "/splash";
  static const relatorios = "relatorios";
  static const home = "/home";
  static const add_info = "/add_info";
  static const add_checklist_info = "/add_checklist_info";
  static const add_checklist = "/add_checklist";
}

class Routes {
  Routes._();
  static final routes = {
    RouteName.auth: (BuildContext context) {
      return AuthStateSwitcher();
    },
    RouteName.splash: (BuildContext context) {
      return SplashScreen();
    },
    RouteName.login: (BuildContext context) {
      return LoginPage();
    },
    RouteName.home: (BuildContext context) {
      return FormularioPage(
        nome: '',
        data: '',
        reportData: {},
        city: '',
        loja: '',
        reportId: '',
        tipo_relatorio: '',
      );
    },
    RouteName.relatorios: (BuildContext context) {
      return RelatoriosPage();
    },
    RouteName.add_checklist: (BuildContext context) {
      return ChecklistSelectPage(
        storeName: '',
        periodo: '',
        funcionario: '',
      );
    },
    RouteName.add_checklist_info: (BuildContext context) {
      return AddChecklistPage();
    },
  };
}
