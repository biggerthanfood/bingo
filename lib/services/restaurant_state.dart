class RestaurantState {
  static final RestaurantState _instance = RestaurantState._internal();
  
  factory RestaurantState() {
    return _instance;
  }
  
  RestaurantState._internal();

  final Set<int> _checkedInRestaurants = {};
  final Set<int> _permanentMarks = {};
  bool hasShownBingo = false;
  List<List<int>> winningLines = [];

  void markRestaurant(int index) {
    if (_permanentMarks.contains(index)) return;
    
    if (_checkedInRestaurants.contains(index)) {
      _checkedInRestaurants.remove(index);
    } else {
      _checkedInRestaurants.add(index);
    }
  }

  void permanentlyMarkRestaurant(int index) {
    _checkedInRestaurants.add(index);
    _permanentMarks.add(index);
  }

  bool isCheckedIn(int index) {
    return _checkedInRestaurants.contains(index);
  }

  Set<int> get checkedRestaurants => Set.from(_checkedInRestaurants);

  bool checkForBingo() {
    List<List<int>> newWinningLines = [];
    
    for (int i = 0; i < 5; i++) {
      List<int> row = List.generate(5, (j) => i * 5 + j);
      if (row.every((index) => _checkedInRestaurants.contains(index))) {
        newWinningLines.add(row);
      }
    }

    for (int i = 0; i < 5; i++) {
      List<int> column = List.generate(5, (j) => i + j * 5);
      if (column.every((index) => _checkedInRestaurants.contains(index))) {
        newWinningLines.add(column);
      }
    }

    List<int> diagonal1 = List.generate(5, (i) => i * 6);
    List<int> diagonal2 = List.generate(5, (i) => (i + 1) * 4).take(5).toList();
    
    if (diagonal1.every((index) => _checkedInRestaurants.contains(index))) {
      newWinningLines.add(diagonal1);
    }
    if (diagonal2.every((index) => _checkedInRestaurants.contains(index))) {
      newWinningLines.add(diagonal2);
    }

    winningLines = newWinningLines;
    return winningLines.isNotEmpty && !hasShownBingo;
  }

  List<List<int>> getWinningLines() => winningLines;

  void setBingoShown() {
    hasShownBingo = true;
  }
}