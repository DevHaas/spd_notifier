// ignore_for_file: unused_field

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spd_notifier/loading_mixin.dart';
import 'package:spd_notifier/spd_notifier.dart';

import 'package:webview_flutter/webview_flutter.dart';

class SPDListener extends StatefulWidget {
  final Color backgroundColor;
  final Widget responseWidget;
  final PreferredSizeWidget? appBar;
  final Widget? offerWidget;
  final Widget offlineWidget;
  final Function(bool)? onLimitedLayoutChanged;

  final bool isRedirect;

  const SPDListener({
    required this.responseWidget,
    required this.backgroundColor,
    this.appBar,
    this.offerWidget,
    this.isRedirect = false,
    super.key,
    required this.offlineWidget,
    this.onLimitedLayoutChanged,
  });

  @override
  State<SPDListener> createState() => _SPDListenerState();
}

class _SPDListenerState extends State<SPDListener>
    with LoadingMixin<SPDListener> {
  WebViewController? webViewController;
  late final StreamSubscription _onSubscription;
  bool isLimitedLayout = false;
  bool onStart = false;

  bool isOffline = false;
  String? fetchData;

  Future<void> _loadConnectionChecker() async {
    _onSubscription =
        Connectivity().onConnectivityChanged.listen((connectivityResult) async {
      if (connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet)) {
        setState(() {
          reload();

          isOffline = false;
        });
      }

      if (connectivityResult.contains(ConnectivityResult.none)) {
        setState(() {
          reload();

          isOffline = true;
        });
      }
    });

    final result = await Connectivity().checkConnectivity();
    if (result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet)) {
      setState(() {
        isOffline = false;
      });
    }

    if (result.contains(ConnectivityResult.none)) {
      setState(() {
        isOffline = true;
      });
    }
  }

  @override
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    fetchData = prefs.getString(SpdNotifier.integrationKey);

    if (fetchData == null) {
      if (widget.onLimitedLayoutChanged != null) {
        widget.onLimitedLayoutChanged!.call(false);
      }

      setState(() {
        isLimitedLayout = true;
        onStart = false;
      });

      return;
    }

    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.backgroundColor)
      ..loadRequest(Uri.parse(fetchData!))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) async {
            setState(() {
              onStart = true;
            });
          },
          onPageFinished: (String url) async {
            final limit = prefs.getString(SpdNotifier.limitedKey);

            if (limit == null) {
              if (widget.onLimitedLayoutChanged != null) {
                widget.onLimitedLayoutChanged!.call(false);
              }

              setState(() {
                isLimitedLayout = true;
                onStart = false;
              });

              return;
            }

            final status = url.contains(limit);

            if (!status) {
              if (widget.onLimitedLayoutChanged != null) {
                widget.onLimitedLayoutChanged!.call(status);
              }

              await SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeRight,
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
              ]);
            }

            setState(() {
              isLimitedLayout = status;
              onStart = false;
            });
          },
        ),
      );

    if (widget.onLimitedLayoutChanged != null) {
      widget.onLimitedLayoutChanged!.call(true);
    }

    await _loadConnectionChecker();

    return;
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isOffline
        ? widget.offlineWidget
        : SafeArea(
            child: Scaffold(
              backgroundColor: widget.backgroundColor,
              appBar: widget.appBar,
              body: LayoutBuilder(
                builder: (context, snapshot) {
                  if (loading) {
                    return SizedBox.expand(
                      child: ColoredBox(
                        color: widget.backgroundColor,
                        child: const Center(
                          child: SizedBox(
                            height: 40,
                            width: 40,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    );
                  }

                  if (webViewController == null) {
                    return widget.responseWidget;
                  }

                  if (isOffline) {
                    return widget.offlineWidget;
                  }

                  if (onStart) {
                    return widget.isRedirect
                        ? widget.offerWidget ??
                            SizedBox.expand(
                              child: ColoredBox(
                                color: widget.backgroundColor,
                                child: const Center(
                                  child: SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                            )
                        : SizedBox.expand(
                            child: ColoredBox(
                              color: widget.backgroundColor,
                              child: const Center(
                                child: SizedBox(
                                  height: 40,
                                  width: 40,
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          );
                  }

                  if (isLimitedLayout) {
                    return widget.responseWidget;
                  } else {
                    return widget.isRedirect
                        ? widget.offerWidget ??
                            WebViewWidget(controller: webViewController!)
                        : WebViewWidget(controller: webViewController!);
                  }
                },
              ),
            ),
          );
  }
}
