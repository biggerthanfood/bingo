import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class BingoCardScreen extends StatelessWidget {
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
    "FREE SPACE",
    "AUNTIES SOUL FOOD (MWC)", 
    "ANDEEZ DONUTS (EDMOND)",
    "HEAVENLEE BBQ (OKC)", 
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

  BingoCardScreen({super.key});

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
            'BLACK RESTAURANT BINGO',
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 25,
                itemBuilder: (context, index) {
                  Color borderColor;
                  if (index < 5) borderColor = Colors.black;
                  else if (index < 10) borderColor = Colors.red;
                  else if (index < 15) borderColor = Colors.green;
                  else if (index < 20) borderColor = Colors.blue;
                  else borderColor = Colors.purple;

                  return Container(
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