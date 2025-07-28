import 'dart:math' show max;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'loading.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  final remoteConfig = FirebaseRemoteConfig.instance;

  bool _showBanner = false;
  String _bannerText = '';

  Future<void> initRemoteConfig() async {
    print('Remote config init');
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await remoteConfig.setDefaults(const {
      'show_banner': false,
      'banner_text': '',
    });
    await remoteConfig.fetchAndActivate();
    setState(() {
      _showBanner = remoteConfig.getBool('show_banner');
      _bannerText = remoteConfig.getString('banner_text');
    });
    print('Remote config listener');
    if (!kIsWeb) {
      // not supported on web
      remoteConfig.onConfigUpdated.listen((event) async {
        print('Remote config updated');
        await remoteConfig.activate();
        setState(() {
          _showBanner = remoteConfig.getBool('show_banner');
          _bannerText = remoteConfig.getString('banner_text');
        });
      }, onError: (error) => print('Remote config error: ${error.toString()}'));
    }
  }

  @override
  void initState() {
    super.initState();
    initRemoteConfig();
  }

  void _incrementCounter(context) {
    FirebaseAnalytics.instance
        .logEvent(name: 'counter_incremented', parameters: null);
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
          content: Text(AppLocalizations.of(context)!.nItems(_counter)),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.ok),
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            ),
          ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.primary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          actions: [
            MenuAnchor(
              builder: (context, controller, child) {
                return IconButton(
                  icon: const Icon(Icons.more_vert),
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.all<Color>(
                        Theme.of(context).colorScheme.onPrimary),
                  ),
                  tooltip: 'Show menu',
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                );
              },
              menuChildren: [
                MenuItemButton(
                  onPressed: () => _incrementCounter(context),
                  child: Text(AppLocalizations.of(context)!.increment),
                ),
                MenuItemButton(
                  onPressed: () => throw Exception('Test Exception!'),
                  child: const Text('Throw Test Exception'),
                ),
              ],
            ),
          ]),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_showBanner)
              Container(
                color: Theme.of(context).colorScheme.secondary,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _bannerText,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(
                              color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ),
                ),
              ),
            const Expanded(child: StoriesList()),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class StoriesList extends StatelessWidget {
  const StoriesList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('snaps')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          return Column(
            children: [
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 0,
                      crossAxisCount: max(constraints.maxWidth ~/ 340, 2),
                    ),
                    itemCount:
                        snapshot.data == null ? 0 : snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final items =
                          snapshot.data == null ? [] : snapshot.data!.docs;
                      final item = items[index];
                      if (item.get('processed')) {
                        return GestureDetector(
                            onTap: () {
                              if (kIsWeb) {
                                context.go('/snap/${item.id}', extra: item);
                              } else {
                                context.push('/snap/${item.id}', extra: item);
                              }
                            },
                            child: Hero(
                              tag: item.id,
                              child: Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: NetworkImage(
                                      item.get('url'),
                                    ),
                                  ),
                                ),
                              ),
                            ));
                      } else {
                        return const LoadingAnimation();
                      }
                    },
                  );
                }),
              ),
            ],
          );
        });
  }
}
