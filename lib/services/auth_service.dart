import 'dart:convert';

import 'package:chat_app/models/login_response.dart';
import 'package:chat_app/models/usuario.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/global/environment.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService with ChangeNotifier {
  Usuario usuario;
  bool _autenticando = false;

  bool get autenticando => this._autenticando;

  set autenticando(bool valor) {
    this._autenticando = valor;
    notifyListeners();
  }

  final _storage = new FlutterSecureStorage();

  static Future<String> getToken() async {
    final _storage = new FlutterSecureStorage();
    final token = await _storage.read(key: 'token');
    return token;
  }

  static Future<void> deleteToken() async {
    final _storage = new FlutterSecureStorage();
    await _storage.delete(key: 'token');
  }

  Future<bool> login(String email, String password) async {
    this.autenticando = true;

    final data = {'email': email, 'password': password};

    final res = await http.post('${Environment.apiUrl}/auth/login',
        body: jsonEncode(data), headers: {'Content-Type': 'application/json'});

    this.autenticando = false;

    if (res.statusCode == 200) {
      final loginResponse = loginResponseFromJson(res.body);

      this.usuario = loginResponse.usuario;

      await this._guardartoken(loginResponse.token);

      return true;
    } else {
      return false;
    }
  }

  Future register(String nombre, String email, String password) async {
    this.autenticando = true;

    final body = {'nombre': nombre, 'email': email, 'password': password};

    final res = await http.post('${Environment.apiUrl}/auth/new',
        body: jsonEncode(body), headers: {'Content-Type': 'application/json'});

    this.autenticando = false;

    if (res.statusCode == 200) {
      final loginResponse = loginResponseFromJson(res.body);

      this.usuario = loginResponse.usuario;

      await this._guardartoken(loginResponse.token);

      return true;
    } else {
      final respBody = jsonDecode(res.body);
      return respBody['msg'];
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await this._storage.read(key: 'token');

    final res = await http.get('${Environment.apiUrl}/auth/renew-token',
        headers: {'Content-Type': 'application/json', 'x-token': token});

    this.autenticando = false;

    if (res.statusCode == 200) {
      final loginResponse = loginResponseFromJson(res.body);

      this.usuario = loginResponse.usuario;

      await this._guardartoken(loginResponse.token);

      return true;
    } else {
      this.logout();

      return false;
    }
  }

  Future _guardartoken(String token) async {
    return await _storage.write(key: 'token', value: token);
  }

  Future logout() async {
    await _storage.delete(key: 'token');
  }
}
