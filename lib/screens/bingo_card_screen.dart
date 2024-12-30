import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/restaurant_state.dart';

class BingoCardScreen extends StatefulWidget {
  final Function(int)? onRestaurantMarked;
  
  const BingoCardScreen({
    super.key,
    this.onRestaurantMarked,
  });

  @override
  State<BingoCardScreen> createState() => _BingoCardScreenState();
}

class _BingoCardScreenState extends State<BingoCardScreen> {
  final RestaurantState _state = RestaurantState();
  final GlobalKey _gridKey = GlobalKey();

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
    "BIG O'S PORK & DREAMS (MWC)",
    "Restaurant 17",
    "Restaurant 18",
    "Restaurant 19",
    "Restaurant 20",
    "Restaurant 21",
    "Restaurant 22",
    "Restaurant 23",
    "Restaurant 24",
    "Restaurant 25"
  ];

  @override
  void initState() {
    super.initState();
    _state.permanentlyMarkRestaurant(12); // Mark FREE SPACE
  }

  void markRestaurant(int index) {
    if (index == 12) {
      return;
    }
    if (index >= 0 && index < restaurants.length) {
      setState(() {
        _state.markRestaurant(index);
        
        // Check for blackout (all spaces marked)
        bool isBlackout = _state.checkedRestaurants.length == 25;
        
        if (isBlackout) {
          _showBingoAnimation(isBlackout: true);
        } else if (_state.checkForBingo()) {
          _showBingoAnimation();
          _state.setBingoShown();
        }
      });
      
      widget.onRestaurantMarked?.call(index);
    }
  }

  void _showBingoAnimation({bool isBlackout = false}) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isBlackout ? Colors.black : Colors.white,
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
                Icon(
                  isBlackout ? CupertinoIcons.star_circle_fill : CupertinoIcons.star_fill,
                  color: Colors.amber,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  isBlackout ? 'Congratulations!\nYou\'re A Bingo Champ!' : 'BINGO!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isBlackout ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      color: isBlackout ? Colors.white : CupertinoColors.activeBlue,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBingoMarker(int index) {
    bool isPartOfBingo = _state.getWinningLines().any((line) => line.contains(index));
    bool isBlackout = _state.checkedRestaurants.length == 25;
    Color bingoColor = isBlackout ? Colors.black : (isPartOfBingo ? Colors.green : Colors.red);
    String restaurantName = restaurants[index];

    return Stack(
      children: [
        // Background chip
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: bingoColor.withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: bingoColor == Colors.red 
                  ? Colors.red.shade900 
                  : (bingoColor == Colors.black ? Colors.white : Colors.green.shade900),
              width: 2
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            gradient: RadialGradient(
              colors: bingoColor == Colors.red
                  ? [Colors.red.shade400, Colors.red.shade700]
                  : (bingoColor == Colors.black 
                      ? [Colors.black87, Colors.black]
                      : [Colors.green.shade400, Colors.green.shade700]),
              center: Alignment.topLeft,
              radius: 1.5,
            ),
          ),
        ),
        // Restaurant name text in front of circle
        Center(
          child: Text(
            restaurantName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
        // Bingo indicator
        if (isPartOfBingo && !isBlackout)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green.shade900,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.check,
                color: Colors.green.shade900,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CupertinoNavigationBar(
        middle: Text('Restaurant Bingo'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'RESTAURANT BINGO',
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'COMMUNITY | CULTURE | ADVENTURE',
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                key: _gridKey,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 25,
                itemBuilder: (context, index) {
                  Color borderColor;
                  if (index < 5) {
                    borderColor = Colors.black;
                  } else if (index < 10) {
                    borderColor = Colors.red;
                  } else if (index < 15) {
                    borderColor = Colors.green;
                  } else if (index < 20) {
                    borderColor = Colors.blue;
                  } else {
                    borderColor = Colors.purple;
                  }

                  return GestureDetector(
                    onTap: () => markRestaurant(index),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor, width: 2),
                        color: index == 12 ? const Color(0xFFF5F5F5) : Colors.white,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                restaurants[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: index == 12 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          if (_state.isCheckedIn(index))
                            Positioned.fill(
                              child: _buildBingoMarker(index),
                            ),
                          if (index != 12 && (index == 1 || index == 5 || index == 11)) 
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Icon(
                                Icons.eco,
                                size: 12,
                                color: Colors.green[700],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}