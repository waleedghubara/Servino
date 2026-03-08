import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';

class FirestoreConfigService {
  static final FirestoreConfigService _instance =
      FirestoreConfigService._internal();
  factory FirestoreConfigService() => _instance;
  FirestoreConfigService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection and Document
  static const String _collection = 'app_config';
  static const String _document = 'keys';

  // Keys
  static const String _keyZegoAppId = 'zego_app_id';
  static const String _keyZegoAppSign = 'zego_app_sign';
  static const String _keyAgoraAppId = 'agora_app_id';

  // Defaults removed as per request. Keys must exist in Firestore.

  // Local Cache
  Map<String, dynamic> _configData = {};

  Future<void> initialize() async {
    try {
      final docSnapshot = await _firestore
          .collection(_collection)
          .doc(_document)
          .get(const GetOptions(source: Source.serverAndCache));

      if (docSnapshot.exists && docSnapshot.data() != null) {
        _configData = docSnapshot.data()!;
        // debugPrint('FirestoreConfigService: Fetched config: $_configData');
      } else {
        // debugPrint(
        //   'FirestoreConfigService: Config document not found in Firestore.',
        // );
      }
    } catch (e) {
      // debugPrint('FirestoreConfigService: Failed to fetch config. Error: $e');
    }
  }

  int get zegoAppId {
    final val = _configData[_keyZegoAppId];
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  String get zegoAppSign => _configData[_keyZegoAppSign] as String? ?? '';
  String get agoraAppId => _configData[_keyAgoraAppId] as String? ?? '';
}
