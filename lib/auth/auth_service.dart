import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Retorna o stream de usuário para o AuthGate
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- Login com Google ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Abre o pop-up de login do Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // O usuário cancelou o login
        return null;
      }

      // Obtém as credenciais de autenticação
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Cria a credencial do Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Faz o login no Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Salva/Atualiza o usuário no Firestore
      // Usamos set com merge:true para criar se não existir ou atualizar se já existir
      if (userCredential.user != null) {
        await _saveUserToFirestore(
          userCredential.user!,
          userCredential.user!.displayName, // Google já fornece o nome
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print(e.message);
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // --- Registro com E-mail/Senha ---
  Future<UserCredential?> signUpWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print(e.message);
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // --- Login com E-mail/Senha ---
  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print(e.message);
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // --- Salvar/Atualizar Usuário no Firestore ---
  // Este método é chamado após o registro ou login com Google
  Future<void> _saveUserToFirestore(User user, String? displayName) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);

      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName ?? user.email?.split('@')[0], // Usa o nome ou parte do email
        'photoURL': user.photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge:true é crucial!

    } catch (e) {
      print("Erro ao salvar usuário no Firestore: $e");
    }
  }

  // --- Atualizar Perfil (usado na profile_setup_screen) ---
  Future<void> updateUserProfile(User user, String displayName, {String? photoURL}) async {
    try {
      // 1. Atualiza o perfil no Firebase Auth
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      
      // 2. Atualiza o documento no Firestore
      final userRef = _firestore.collection('users').doc(user.uid);
      await userRef.update({
        'displayName': displayName,
        'photoURL': photoURL ?? user.photoURL, // Mantém a foto antiga se nenhuma nova for fornecida
      });

    } catch (e) {
      print("Erro ao atualizar perfil: $e");
    }
  }


  // --- Logout ---
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
