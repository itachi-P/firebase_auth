import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter_twitter_login/flutter_twitter_login.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum EnumAuth {
  google,
  facebook,
  twitter,
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SNS auth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthPage(
        title: 'Auth with Firebase',
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  AuthPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookLogin _facebookSignIn = FacebookLogin();
  final TwitterLogin _twitterLogin = TwitterLogin(
    // このままではセキュリティ上大問題なのでcrypto使用版に書き換える
    consumerKey: "xxxxxxxxxx",
    consumerSecret: "xxxxxxxxxx",
  );

  bool loggedIn = false;
  EnumAuth enumAuth;
  FirebaseUser loggedInUser;

  void login() {
    setState(() {
      loggedIn = true;
    });
  }

  void logout() {
    setState(() {
      loggedIn = false;
    });
  }

  void setEnumAuth(EnumAuth sns) {
    setState(() {
      enumAuth = sns;
    });
  }

  Future signInWithGoogle() async {
    // Google認証の許可画面が表示される
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    //Firebaseのユーザー情報にアクセス
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    //userのid取得
    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;
    print("signed in " + user.displayName);
    print('user profile picture: ${user.photoUrl}');

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);
    login();
    setEnumAuth(EnumAuth.google);
    setState(() {
      loggedInUser = user;
    });
  }

  Future signInWithFacebook() async {
    final facebookLogin = FacebookLogin();
    // final facebookLoginResult =
    //     await facebookLogin.loginWithPublishPermissions((['email']));
    final facebookLoginResult = await facebookLogin.logIn((['email']));

    final AuthCredential credential = FacebookAuthProvider.getCredential(
      accessToken: facebookLoginResult.accessToken.token,
    );

    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    login();
    setEnumAuth(EnumAuth.facebook);
  }

  Future signInWithTwitter() async {
    final TwitterLoginResult result = await _twitterLogin.authorize();

    final AuthCredential credential = TwitterAuthProvider.getCredential(
      authToken: result.session.token,
      authTokenSecret: result.session.secret,
    );

    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    login();
    setEnumAuth(EnumAuth.twitter);
  }

  void signOutGoogle() async {
    await _googleSignIn.signOut();
    print("User Sign Out Google");
  }

  void signOutFacebook() async {
    await _facebookSignIn.logOut();
    print("User Sign Out Facebook");
  }

  void signOutTwitter() async {
    await _twitterLogin.logOut();
    print("User Sign Out Twittter");
  }

  void signOut(EnumAuth sns) async {
    switch (sns) {
      case EnumAuth.google:
        signOutGoogle();
        break;
      case EnumAuth.twitter:
        signOutTwitter();
        break;
      case EnumAuth.facebook:
        signOutFacebook();
        break;
    }
    logout();
  }

  @override
  Widget build(BuildContext context) {
    Widget logoutText = Text("Logging out");
    Widget loginText = Text("Logging in");

    Widget loginBtnGoogle = RaisedButton(
      child: Text("Sign in with Google"),
      color: Color(0xFFDD4B39),
      textColor: Colors.white,
      onPressed: signInWithGoogle,
    );

    Widget loginBtnFb = RaisedButton(
      child: Text("Sign in with Facebook"),
      color: Color(0xFF3B5998),
      textColor: Colors.white,
      onPressed: signInWithFacebook,
    );

    Widget loginBtnTwitter = RaisedButton(
      child: Text("Sign in with Twitter"),
      color: Color(0xFF1DA1F2),
      textColor: Colors.white,
      onPressed: signInWithTwitter,
    );

    Widget logoutBtn = RaisedButton(
      child: Text("Sign out"),
      color: Colors.black38,
      textColor: Colors.white,
      onPressed: () => signOut(enumAuth),
    );

    Widget loginBtns = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        loginBtnGoogle,
        loginBtnFb,
        loginBtnTwitter,
      ],
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            loggedIn ? loginText : logoutText,
            loggedIn ? logoutBtn : loginBtns,
            //loggedIn ? MainAppStartPage() : LoginPage(),
          ],
        ),
      ),
    );
  }
}
