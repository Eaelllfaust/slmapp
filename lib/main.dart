import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebView App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  bool isLoading = true;
  late final WebViewController _controller;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _checkConnectivity();
    _initializeWebView();
  }

  void _initializeWebView() {
    final NavigationDelegate navigationDelegate = NavigationDelegate(
      onPageStarted: (String url) {
        if (mounted) {
          setState(() => isLoading = true);
        }
      },
      onProgress: (int progress) {
        if (progress == 100) {
          if (mounted) {
            setState(() => isLoading = false);
          }
        }
      },
      onPageFinished: (String url) async {
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() => isLoading = false);
        }
      },
      onWebResourceError: (WebResourceError error) {
        debugPrint('WebView Error: ${error.description}');
        if (mounted) {
          setState(() => isLoading = false);
        }
      },
      onNavigationRequest: (NavigationRequest request) {
        return NavigationDecision.navigate;
      },
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..addJavaScriptChannel(
        'FlutterTTS',
        onMessageReceived: (message) {
          _speak(message.message);
        },
      )
      ..setNavigationDelegate(navigationDelegate);

    // Platform-specific configurations
    if (Platform.isAndroid) {
      _controller
        ..setBackgroundColor(Colors.transparent)
        ..loadRequest(
          Uri.parse('https://elderlms-tr8q.vercel.app/auth'),
          headers: {
            'Accept': '*/*',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
          },
        );
    } else if (Platform.isIOS) {
      _controller.loadRequest(
        Uri.parse('https://elderlms-tr8q.vercel.app/auth'),
        headers: {
          'Accept': '*/*',
        },
      );
    }
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showNoInternetDialog();
    }
  }

  void _showNoInternetDialog() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('No Internet'),
          content: const Text('Please check your internet connection and try again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _checkConnectivity();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}