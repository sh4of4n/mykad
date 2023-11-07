import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await setupSentry(
    () => runApp(
      SentryScreenshotWidget(
        child: SentryUserInteractionWidget(
          child: DefaultAssetBundle(
            bundle: SentryAssetBundle(),
            child: const MyApp(),
          ),
        ),
      ),
    ),
  );
}

Future<void> setupSentry(AppRunner appRunner,
    {bool isIntegrationTest = false,
    BeforeSendCallback? beforeSendCallback}) async {
  await SentryFlutter.init((options) {
    options.dsn =
        'https://1b41e5be9df3b6f6c968eb2d85e33bb0@o354605.ingest.sentry.io/4506148845780992';
    options.tracesSampleRate = 1.0;
    options.profilesSampleRate = 1.0;
    options.attachThreads = true;
    options.enableWindowMetricBreadcrumbs = true;
    options.sendDefaultPii = true;
    options.reportSilentFlutterErrors = true;
    options.attachScreenshot = true;
    options.screenshotQuality = SentryScreenshotQuality.low;
    options.attachViewHierarchy = true;
    // We can enable Sentry debug logging during development. This is likely
    // going to log too much for your app, but can be useful when figuring out
    // configuration issues, e.g. finding out why your events are not uploaded.

    options.maxRequestBodySize = MaxRequestBodySize.always;
    options.maxResponseBodySize = MaxResponseBodySize.always;
  },
      // Init your App.
      appRunner: appRunner);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

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
  String _batteryLevel = 'Unknown battery level.';
  static const platform = MethodChannel('samples.flutter.dev/battery');

  Future<void> _incrementCounter() async {
    String batteryLevel;
    try {
      final result = await platform.invokeMethod<int>('getBatteryLevel');
      batteryLevel = 'Battery level at $result % .';
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });
    setState(() {
      _counter++;
    });
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
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
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(_batteryLevel),
            ElevatedButton(
              onPressed: () async {
                final result = await platform.invokeMethod<String>('onCreate');
                setState(() {
                  _batteryLevel = result.toString();
                });
              },
              child: const Text('onCreate'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await platform.invokeMethod<String>('onReadMyKad');
                setState(() {
                  _batteryLevel = result.toString();
                });
              },
              child: const Text('onReadMyKad'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
