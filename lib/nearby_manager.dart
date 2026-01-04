import 'dart:async';
import 'dart:io';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

enum ConnectionStatus { idle, searching, connected }

class NearbyManager {
  late NearbyService nearbyService;
  List<Device> devices = [];
  List<Device> connectedDevices = [];
  
  StreamSubscription? subscription;
  StreamSubscription? receivedDataSubscription;

  Function(String)? onDataReceived;
  Function(ConnectionStatus)? onStatusChanged;
  Function? onDevicesUpdated;

  NearbyManager() {
    nearbyService = NearbyService();
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.nearbyWifiDevices,
      ].request();
      return statuses.values.every((status) => status.isGranted);
    } else {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
      ].request();
      return statuses.values.every((status) => status.isGranted);
    }
  }

  Future<void> init() async {
    await nearbyService.init(
      serviceType: 'xpong-p2p',
      deviceName: Platform.isAndroid ? 'Android-Pong' : 'iOS-Pong',
      strategy: Strategy.P2P_STAR,
      callback: (data) {
        // This callback is for receiving data
      },
    );

    subscription = nearbyService.stateChangedSubscription(callback: (devicesList) {
      devices = devicesList;
      connectedDevices = devicesList
          .where((d) => d.state == SessionState.connected)
          .toList();
      if (onDevicesUpdated != null) onDevicesUpdated!();
    });

    receivedDataSubscription = nearbyService.dataReceivedSubscription(callback: (data) {
      if (onDataReceived != null) {
        onDataReceived!(data['message']);
      }
    });
  }

  void startAdvertising() {
    nearbyService.startAdvertisingPeer();
  }

  void startBrowsing() {
    nearbyService.startBrowsingForPeers();
  }

  void stopAll() {
    nearbyService.stopAdvertisingPeer();
    nearbyService.stopBrowsingForPeers();
  }

  void connect(Device device) {
    nearbyService.invitePeer(deviceID: device.deviceId, deviceName: device.deviceName);
  }

  void sendData(String message) {
    for (var device in connectedDevices) {
      nearbyService.sendMessage(device.deviceId, message);
    }
  }

  void dispose() {
    subscription?.cancel();
    receivedDataSubscription?.cancel();
    stopAll();
  }
}
