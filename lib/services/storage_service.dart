import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';

class StorageService {
  static const _key = 'portfoy_assets_v1';

  Future<List<UserAsset>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = json.decode(raw) as List;
    return list
        .map((e) => UserAsset.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<UserAsset> assets) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(assets.map((a) => a.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
