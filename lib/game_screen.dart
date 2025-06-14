import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  final bool isSinglePlayer;

  const GameScreen({super.key, required this.isSinglePlayer});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late List<List<String>> board;
  late bool xTurn;
  late bool gameOver;
  late String winner;
  bool isComputerThinking = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    initializeGame();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void initializeGame() {
    board = List.generate(3, (_) => List.filled(3, ''));
    xTurn = true;
    gameOver = false;
    winner = '';
    isComputerThinking = false;
  }

  void showGameOverDialog() {
    _animationController.forward(from: 0.0);

    showDialog(
      context: context,
      builder: (context) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        winner == 'Draw'
                            ? Colors.orange.withOpacity(0.2)
                            : (winner == 'X'
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.pink.withOpacity(0.2)),
                  ),
                  child: Icon(
                    winner == 'Draw'
                        ? Icons.balance
                        : (winner == 'X' ? Icons.close : Icons.circle_outlined),
                    size: 50,
                    color:
                        winner == 'Draw'
                            ? Colors.orange
                            : (winner == 'X' ? Colors.blue : Colors.pink),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  winner == 'Draw'
                      ? 'Game Draw!'
                      : (winner == 'X'
                          ? (widget.isSinglePlayer
                              ? 'You won!'
                              : 'Player X wins!')
                          : (widget.isSinglePlayer
                              ? 'Computer wins!'
                              : 'Player 0 wins!')),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        winner == 'Draw'
                            ? Colors.orange
                            : winner == 'X'
                            ? Colors.blue
                            : Colors.pink,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      initializeGame();
                    });
                  },
                  child: const Text(
                    'Play again!',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Main menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void makeMove(int row, int col) {
    if (board[row][col] != '' || gameOver || isComputerThinking) return;

    setState(() {
      board[row][col] = xTurn ? 'X' : '0';
      checkWinner();
      xTurn = !xTurn;

      if (!gameOver && widget.isSinglePlayer && !xTurn) {
        isComputerThinking = true;
        Timer(const Duration(seconds: 1), () {
          if (!mounted) return;
          computerMove();
        });
      }
    });
  }

  void computerMove() {
    List<List<int>> emptyCells = [];
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        if (board[i][j] == '') {
          emptyCells.add([i, j]);
        }
      }
    }

    if (emptyCells.isEmpty) return;

    for (var move in emptyCells) {
      board[move[0]][move[1]] = '0';
      if (checkWinningMove('0')) {
        setState(() {
          checkWinner();
          xTurn = !xTurn;
          isComputerThinking = false;
        });
        return;
      }
      board[move[0]][move[1]] = '';
    }

    for (var move in emptyCells) {
      board[move[0]][move[1]] = 'X';
      if (checkWinningMove('X')) {
        board[move[0]][move[1]] = '0';
        setState(() {
          checkWinner();
          xTurn = !xTurn;
          isComputerThinking = false;
        });
        return;
      }
      board[move[0]][move[1]] = '';
    }

    if (board[1][1] == '') {
      board[1][1] = '0';
      setState(() {
        checkWinner();
        xTurn = !xTurn;
        isComputerThinking = false;
      });
      return;
    }

    // Choose the corners
    List<List<int>> corners = [
      [0, 0],
      [0, 2],
      [2, 0],
      [2, 2],
    ];
    List<List<int>> availableCorners =
        corners.where((corner) => board[corner[0]][corner[1]] == '').toList();
    if (availableCorners.isNotEmpty) {
      final move = availableCorners[Random().nextInt(availableCorners.length)];
      board[move[0]][move[1]] = '0';
      setState(() {
        checkWinner();
        xTurn = !xTurn;
        isComputerThinking = false;
      });
      return;
    }

    final move = emptyCells[Random().nextInt(emptyCells.length)];
    board[move[0]][move[1]] = '0';
    setState(() {
      checkWinner();
      xTurn = !xTurn;
      isComputerThinking = false;
    });
  }

  bool checkWinningMove(String player) {
    for (int i = 0; i < 3; i++) {
      if (board[i][0] == player &&
          board[i][1] == player &&
          board[i][2] == player)
        return true;
      if (board[0][i] == player &&
          board[1][i] == player &&
          board[2][i] == player)
        return true;
    }

    if (board[0][0] == player &&
        board[1][1] == player &&
        board[2][2] == player) {
      return true;
    }
    if (board[0][2] == player &&
        board[1][1] == player &&
        board[2][0] == player) {
      return true;
    }

    return false;
  }

  void checkWinner() {
    if (checkWinningMove('X')) {
      setState(() {
        gameOver = true;
        winner = 'X';
        showGameOverDialog();
      });
      return;
    }

    if (checkWinningMove('0')) {
      setState(() {
        gameOver = true;
        winner = '0';
        showGameOverDialog();
      });
      return;
    }

    if (board.every((row) => row.every((cell) => cell != ''))) {
      setState(() {
        gameOver = true;
        winner = 'Draw';
        showGameOverDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.purple.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                gameOver
                    ? winner == 'Draw'
                        ? 'Game Over'
                        : 'Player $winner wins'
                    : isComputerThinking
                    ? 'Computer is think...'
                    : 'Player ${xTurn ? 'X' : '0'}`s Turn',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final row = index ~/ 3;
                  final col = index % 3;
                  return GestureDetector(
                    onTap: () => makeMove(row, col),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          board[row][col],
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color:
                                board[row][col] == 'X'
                                    ? Colors.blue
                                    : Colors.pink,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        initializeGame();
                      });
                    },
                    child: const Text(
                      'Restart Game',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        Navigator.pop(context);
                      });
                    },
                    child: const Text(
                      'Main menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
