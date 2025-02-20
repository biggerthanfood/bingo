// File: lib/screens/checkin_screen.dart

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
  final TextEditingController _receiptAmountController = TextEditingController();

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

  @override
  void dispose() {
    _receiptAmountController.dispose();
    super.dispose();
  }

  void _showReceiptInputDialog(int selectedRestaurantIndex) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Enter Receipt Amount'),
          content: Column(
            children: [
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _receiptAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                placeholder: 'Enter amount (e.g., 15.99)',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('\$'),
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                _receiptAmountController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                if (_isValidAmount(_receiptAmountController.text)) {
                  Navigator.pop(context);
                  _handleCheckIn(selectedRestaurantIndex);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  bool _isValidAmount(String value) {
    if (value.isEmpty) return false;
    try {
      final amount = double.parse(value);
      return amount > 0;
    } catch (e) {
      return false;
    }
  }

  void _handleCheckIn(int restaurantIndex) {
    if (_lastPhotoPath == null) {
      _showErrorMessage('Please take a photo before checking in.');
      return;
    }

    // Capture the amount before any state changes
    final receiptAmount = double.parse(_receiptAmountController.text);

    setState(() {
      _state.checkInRestaurant(restaurantIndex);
      
      if (_state.checkForBingo()) {
        _showBingoAnimation();
        _state.setBingoShown();
      }
    });
    
    // Handle photo and receipt amount
    print('Check-in photo path: $_lastPhotoPath');
    print('Receipt amount: \$${receiptAmount.toStringAsFixed(2)}');
    
    // Show success message before clearing state
    _showSuccessMessage(context, receiptAmount);
    
    // Reset state
    _lastPhotoPath = null;
    _receiptAmountController.clear();
  }

  void _showSuccessMessage(BuildContext context, double amount) {
    final amountText = '\$${amount.toStringAsFixed(2)}';
    
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
              Text('Receipt amount: $amountText'),
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
    if (_lastPhotoPath == null) {
      _showErrorMessage('Please take a photo first.');
      return;
    }

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
        _showReceiptInputDialog(selectedIndex);
      }
    });
  }

  void _showErrorMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
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
                  const Text(
                    'Photo required for check-in',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 14,
                    ),
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
                      onPressed: () {
                        if (_lastPhotoPath == null) {
                          _showErrorMessage('Please take a photo first.');
                        } else {
                          _showRestaurantSelectionDialog(context);
                        }
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