import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'nearby_manager.dart';
import 'pong_game.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XPong',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: const LobbyScreen(),
    );
  }
}

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final NearbyManager _nearbyManager = NearbyManager();
  bool _isInitialized = false;
  bool _isAdvertising = false;
  bool _isBrowsing = false;
  bool _isGameStarted = false;

  @override
  void initState() {
    super.initState();
    _initNearby();
  }

  Future<void> _initNearby() async {
    bool granted = await _nearbyManager.requestPermissions();
    if (granted) {
      await _nearbyManager.init();
      setState(() {
        _isInitialized = true;
      });
      _nearbyManager.onDevicesUpdated = () {
        if (mounted) setState(() {});
        _checkConnections();
      };
    }
  }

  void _checkConnections() {
    if (_nearbyManager.connectedDevices.isNotEmpty && !_isGameStarted) {
      _isGameStarted = true;
      // If we are connected, start the game
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PongGame(
            nearbyManager: _nearbyManager,
            isHost: _isAdvertising, // Advertising device acts as host
          ),
        ),
      ).then((_) {
        _isGameStarted = false;
        setState(() {
          _isAdvertising = false;
          _isBrowsing = false;
        });
      });
      _nearbyManager.stopAll();
    }
  }

  @override
  void dispose() {
    _nearbyManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("XPong Lobby")),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isAdvertising ? null : () {
                        setState(() => _isAdvertising = true);
                        _nearbyManager.startAdvertising();
                      },
                      child: const Text("Host Game"),
                    ),
                    ElevatedButton(
                      onPressed: _isBrowsing ? null : () {
                        setState(() => _isBrowsing = true);
                        _nearbyManager.startBrowsing();
                      },
                      child: const Text("Join Game"),
                    ),
                  ],
                ),
                const Divider(height: 40),
                const Text("Nearby Players:", style: TextStyle(fontSize: 18)),
                Expanded(
                  child: ListView.builder(
                    itemCount: _nearbyManager.devices.length,
                    itemBuilder: (context, index) {
                      final device = _nearbyManager.devices[index];
                      return ListTile(
                        title: Text(device.deviceName),
                        subtitle: Text(device.state.name),
                        trailing: device.state == SessionState.notConnected
                            ? ElevatedButton(
                                onPressed: () => _nearbyManager.connect(device),
                                child: const Text("Connect"),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}