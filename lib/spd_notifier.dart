import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Data {
  final String link;
  final String block;

  Data({required this.link, required this.block});
}

class SpdNotifier {
  static const notifierKey = 'notifierKey';
  static const integrationKey = 'integrationKey';
  static const limitedKey = 'limitedKey';

  SpdNotifier._internal();

  static final SpdNotifier instance = SpdNotifier._internal();

  bool _isStringOnlyLetters(String str) {
    return str.trim().isNotEmpty &&
        str.split('').every((char) => RegExp(r'^[a-zA-Z]+$').hasMatch(char));
  }

  Future<void> initNotifier({
    required bool isEnabled,
    required String name,
    required String id,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(notifierKey, isEnabled);

    if (isEnabled) {
      await Firebase.initializeApp();
      late final collection =
          FirebaseFirestore.instance.collection(name).withConverter<Data>(
        fromFirestore: (snapshot, options) {
          final json = snapshot.data()!;



          return Data(
            link: json.keys.where((element) => element.startsWith('_')).first,
            block: json.keys.where((element) => _isStringOnlyLetters(element)).first,
          );
        },
        toFirestore: (app, _) {
          return {};
        },
      );

      final doc = await collection.doc(id).get();

      final model = doc.data() as Data;

  

    
        await prefs.setString(
          integrationKey,
          model.link,
        );
    
        await prefs.setString(
          limitedKey,
          model.block,
        );
      
    }
  }
}
