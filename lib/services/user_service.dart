import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserSessionService {
  UserSessionService._();

  static final UserSessionService instance = UserSessionService._();

  User? get currentAuthUser => FirebaseAuth.instance.currentUser;

  Future<UserModel?> getCurrentUser() async {
    final authUser = currentAuthUser;
    if (authUser == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(authUser.uid)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return UserModel.fromFirebaseUser(authUser);
    }

    return UserModel.fromMap(authUser.uid, snapshot.data()!);
  }

  Stream<UserModel?> watchCurrentUser() {
    return FirebaseAuth.instance.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return getCurrentUser();
    });
  }

  Future<void> syncCurrentUser({String telefone = ''}) async {
    final user = currentAuthUser;
    if (user == null) return;

    final userModel = UserModel.fromFirebaseUser(user, telefone: telefone);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(userModel.toMap(), SetOptions(merge: true));
  }
}
