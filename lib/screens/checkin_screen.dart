import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/maps_service.dart';

class CheckInScreen extends StatelessWidget {
  const CheckInScreen({super.key});

  void _showManualCheckInDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Manual Check-in'),
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text('Confirm that you visited this restaurant?'),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.pop(context);
                _showSuccessMessage(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showSuccessMessage(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Success'),
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text('Check-in recorded successfully!'),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('Check In'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.camera),
          onPressed: () {
            // TODO: Implement photo upload
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.building_2_fill,
                    size: 100,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    onPressed: () => _showManualCheckInDialog(context),
                    child: const Text('Manual Check-in'),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: CupertinoButton(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(CupertinoIcons.square_list),
                          Text('Manual', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      onPressed: () => _showManualCheckInDialog(context),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
                  Expanded(
                    child: CupertinoButton(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(CupertinoIcons.grid),
                          Text('Bingo', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      onPressed: () {
                        // TODO: Navigate to bingo card view
                      },
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
                  Expanded(
                    child: CupertinoButton(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(CupertinoIcons.map),
                          Text('Map', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      onPressed: () {
                        MapsService.openAppleMaps(
                          latitude: 37.7749, // Example coordinates
                          longitude: -122.4194,
                          name: "Restaurant Name"
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}