import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 1. Variable para controlar el tema
  ThemeMode _themeMode = ThemeMode.light;

  // 2. Función para cambiar el tema
  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.blue),
      themeMode: _themeMode, 
      home: MyHomePage(
        title: 'Flutter Demo Home Page', 
        // 3. Pasamos la función al Home
        onThemeChanged: _toggleTheme, 
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  // 4. AGREGAMOS onThemeChanged al constructor
  final String title;
  final VoidCallback onThemeChanged; 

  const MyHomePage({
    super.key, 
    required this.title, 
    required this.onThemeChanged,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        // 5. AGREGAMOS EL BOTÓN EN EL APPBAR
        actions: [
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.light 
                ? Icons.dark_mode 
                : Icons.light_mode),
            onPressed: widget.onThemeChanged, // Usamos la función que viene del padre
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Corregido el punto por MainAxisAlignment
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}