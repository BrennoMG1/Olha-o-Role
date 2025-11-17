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

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print(e.message);
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<String> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return "Sucesso";
    } on FirebaseAuthException catch (e) {
      // Retorna uma mensagem de erro amigável
      if (e.code == 'user-not-found') {
        return "Nenhuma conta encontrada com este e-mail.";
      } else {
        return "Erro: ${e.message}";
      }
    } catch (e) {
      return "Erro: Ocorreu um problema inesperado.";
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
  Future<void> saveUserToFirestore(
    User user,
    String? displayName,
    String friendCode, // <-- 1. ADICIONE O NOVO PARÂMETRO
    String? photoURL,
  ) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);

      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName ?? user.email?.split('@')[0],
        'photoURL': photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
        'friendCode': friendCode, // <-- 2. ADICIONE O CAMPO NO MAPA
      }, SetOptions(merge: true));


    } catch (e) {
      print("Erro ao salvar usuário no Firestore: $e");
    }
  }

  // --- Atualizar Perfil (usado na profile_setup_screen) ---
  Future<void> updateUserProfile(User user, String displayName,
      {String? photoURL}) async {
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
        'photoURL':
            photoURL ?? user.photoURL, // Usa a nova foto ou a antiga
      });
    } catch (e) {
      print("Erro ao atualizar perfil: $e");
    }
  }


  // --- Logout ---
 Future<void> signOut() async {
  try {
    // 1. Tenta fazer o logout do Google.
    // Se o usuário não estava logado com o Google, isso pode
    // falhar, e nós vamos "pegar" o erro (catch).
    await _googleSignIn.signOut();
    
  } catch (e) {
    // 2. O "catch" pega o erro e o ignora,
    // permitindo que o código continue.
    print("Nenhum usuário do Google para deslogar (isso é normal): $e");
  }

  // 3. Este é o logout principal do Firebase.
  // Como o erro do Google foi pego, esta linha agora
  // será executada EM TODOS OS CASOS (Google ou E-mail).
  await _auth.signOut();
}
}
