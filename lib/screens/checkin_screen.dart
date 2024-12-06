import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/maps_service.dart';
import '../services/restaurant_state.dart';
import 'bingo_card_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final RestaurantState _state = RestaurantState();

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
              child: Text(restaurants[index]),
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
                  CupertinoButton.filled(
                    onPressed: () => _showRestaurantSelectionDialog(context),
                    child: const Text('Check In to Restaurant'),
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