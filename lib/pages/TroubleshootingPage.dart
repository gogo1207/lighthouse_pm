import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lighthouse_pm/dialogs/EnableBluetoothDialogFlow.dart';
import 'package:lighthouse_pm/dialogs/LocationPermissonDialogFlow.dart';
import 'package:lighthouse_pm/permissionsHelper/BLEPermissionsHelper.dart';
import 'package:permission_handler/permission_handler.dart';

const double _TROUBLESHOOTING_SCROLL_PADDING = 20;

///
/// A widget showing the a material scaffold with the troubleshooting widget.
///
class TroubleshootingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Troubleshooting')),
        body: TroubleshootingContentWidget());
  }
}

///
/// A widget with a list of some troubleshooting steps the user might take.
/// It also has a few platform specific troubleshooting steps like location
/// permissions for Android.
///
class TroubleshootingContentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      ListTile(
        title: Text('Make sure the lighthouse is plugged in'),
        leading: Icon(Icons.power, color: Colors.blue),
      ),
      Divider(),
      ListTile(
          title: Text(
              'Make sure that your lighthouses are V2 lighthouses and not V1/Vive'),
          subtitle: Text('This app does not support V1 base stations yet™.'),
          leading: SvgPicture.asset("assets/images/app-icon.svg")),
      Divider(),
      ListTile(
          title: Text('You might be out of range'),
          subtitle: Text('Try moving closer to the lighthouses.'),
          leading: Icon(Icons.signal_cellular_null, color: Colors.orange)),
      Divider(),
    ];

    if (Platform.isAndroid) {
      children.insert(
          0,
          // FlutterBlue doesn't like it when you have two of the same streams
          // open at once, so for now convert it into a future.
          //StreamBuilder<BluetoothState>(
          //  stream: FlutterBlue.instance.state,
          FutureBuilder<BluetoothState>(
            future: FlutterBlue.instance.state.first,
            initialData: BluetoothState.unknown,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              final data = snapshot.data;
              switch (data) {
                case BluetoothState.on:
                case BluetoothState.turningOn:
                case BluetoothState.unknown:
                  return Container();
                default:
                  return Column(
                    children: [
                      _TroubleshootingItemWithAction(
                          leadingIcon: Icons.bluetooth_disabled,
                          leadingColor: Colors.blue,
                          title: Text('Enable Bluetooth'),
                          subtitle: Text(
                              'Bluetooth needs to be enabled to scan for devices'),
                          actionIcon: Icons.settings_bluetooth,
                          onTap: () async {
                            await EnableBluetoothDialogFlow
                                .showEnableBluetoothDialogFlow(context);
                          }),
                      Divider(),
                    ],
                  );
              }
            },
          ));
      children.insert(
          0,
          FutureBuilder<PermissionStatus>(
            future: BLEPermissionsHelper.hasBLEPermissions(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data.isGranted) {
                return Container();
              }
              return Column(
                children: [
                  _TroubleshootingItemWithAction(
                    leadingIcon: Icons.lock,
                    leadingColor: Colors.red,
                    title: Text('Allow Location permissions'),
                    subtitle: Text(
                        'On Android you need to allow location permissions to scan for devices'),
                    actionIcon: Icons.location_on,
                    onTap: () async {
                      await LocationPermissionDialogFlow
                          .showLocationPermissionDialogFlow(context);
                    },
                  ),
                  Divider(),
                ],
              );
            },
          ));
      children.insert(0, Divider());
      children.insert(
          0,
          _TroubleshootingItemWithAction(
            leadingIcon: Icons.location_off,
            leadingColor: Colors.green,
            title: Text('Enable location services'),
            subtitle: Text(
                'On Android 6.0 or higher it is required to enable location services. Or no devices will show up.'),
            actionIcon: Icons.settings,
            onTap: () async {
              await BLEPermissionsHelper.openLocationSettings();
            },
          ));
    }
    // Add a container at the bottom and at the top to add a bit of padding to
    // make it all look a bit nicer.
    children.insert(
        0,
        Container(
          height: _TROUBLESHOOTING_SCROLL_PADDING,
        ));
    children.add(Container(
      height: _TROUBLESHOOTING_SCROLL_PADDING,
    ));

    return ListView(children: children);
  }
}

///
/// A simple widget to show a troubleshooting item with an action next to it.
/// For example 'location service should be enabled' with the action go to settings.
///
class _TroubleshootingItemWithAction extends StatelessWidget {
  _TroubleshootingItemWithAction(
      {Key key,
      @required this.leadingIcon,
      @required this.leadingColor,
      @required this.actionIcon,
      @required this.onTap,
      @required this.title,
      this.subtitle})
      : super(key: key);

  final IconData leadingIcon;
  final Color leadingColor;
  final IconData actionIcon;
  final VoidCallback onTap;
  final Widget title;
  final Widget subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            leading: Icon(leadingIcon, color: leadingColor),
            title: title,
            subtitle: subtitle,
          ),
        ),
        RawMaterialButton(
            onPressed: onTap,
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(8.0),
            shape: CircleBorder(),
            child: Icon(
              actionIcon,
              color: Colors.black,
              size: 24.0,
            )),
      ],
    );
  }
}