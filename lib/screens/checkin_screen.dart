import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/maps_service.dart';
import '../services/restaurant_state.dart';
import 'bingo_card_screen.dart';
import 'camera_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final RestaurantState _state = RestaurantState();
  String? _lastPhotoPath;

  final List<String> restaurants = [
    "JOLA'S NIGERIAN KITCHEN (EDMOND)", 
    "CITY JERK GRILL (OKC)", 
    "BIG O'S PORK & DREAMS (EDMOND)", 
    "EASTSIDE PIZZA HOUSE (OKC)",
    "JUST PUT A EGG ON IT (OKC)",
    "TASTE OF AFRICA (OKC)", 
    "NOT CHO CHEESECAKE (BETHANY)", 
    "THE CRIMSON MELT (MOORE)",
    "SWEET SIPS & STICKS (NORMAN)",
    "HEAVENLEE BBQ (OKC)",
    "AUNTIES SOUL FOOD (MWC)", 
    "ANDEEZ DONUTS (EDMOND)",
    "FREE SPACE", 
    "THE HIVE EATERY (EDMOND)", 
    "PINKBERRY FROZEN YOGURT (NORMAN)",
    "BIG O'S PORK & DREAMS (MWC)"
  ];

  void _handleCheckIn(int restaurantIndex) {
    setState(() {
      _state.markRestaurant(restaurantIndex);
      
      if (_state.checkForBingo()) {
        _showBingoAnimation();
        _state.setBingoShown();
      }
    });
    
    // Handle photo if one was taken
    if (_lastPhotoPath != null) {
      // TODO: Handle the photo (e.g., upload to Firebase Storage)
      print('Check-in photo path: $_lastPhotoPath');
      _lastPhotoPath = null; // Reset after handling
    }
    
    _showSuccessMessage(context);
  }

  void _showBingoAnimation() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.star_fill,
                  color: Colors.amber,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'BINGO!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  child: const Text('Continue Playing'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRestaurantSelectionDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text('Select Restaurant'),
          message: const Text('Choose the restaurant you visited'),
          actions: List<CupertinoActionSheetAction>.generate(
            restaurants.length,
            (index) => CupertinoActionSheetAction(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      restaurants[index],
                      style: const TextStyle(color: CupertinoColors.activeBlue),
                    ),
                  ),
                  if (_state.isCheckedIn(index))
                    const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: CupertinoColors.activeGreen,
                      size: 20,
                    ),
                ],
              ),
              onPressed: () {
                Navigator.pop(context, index);
              },
            ),
          ),
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        );
      },
    ).then((selectedIndex) {
      if (selectedIndex != null) {
        _handleCheckIn(selectedIndex);
      }
    });
  }

  void _showSuccessMessage(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Success'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('Check-in recorded successfully!'),
              ),
              if (_lastPhotoPath != null)
                const Text('Photo saved with check-in'),
            ],
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
      appBar: const CupertinoNavigationBar(
        middle: Text('Check In'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _lastPhotoPath != null 
                      ? CupertinoIcons.camera_fill
                      : CupertinoIcons.building_2_fill,
                    size: 100,
                    color: _lastPhotoPath != null ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          fullscreenDialog: true,
                          builder: (context) => CameraScreen(
                            onPhotoTaken: (String photoPath) {
                              setState(() {
                                _lastPhotoPath = photoPath;
                              });
                              _showRestaurantSelectionDialog(context);
                            },
                          ),
                        ),
                      );
                    },
                    child: const Text('Take Photo'),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    onPressed: () => _showRestaurantSelectionDialog(context),
                    child: const Text('Check In Without Photo'),
                  ),
                  if (_lastPhotoPath != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Photo ready for check-in',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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
                          Text('Check In', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      onPressed: () => _showRestaurantSelectionDialog(context),
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
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => BingoCardScreen(
                              onRestaurantMarked: (index) {
                                setState(() {});
                              },
                            ),
                          ),
                        );
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
                          latitude: 37.7749,
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