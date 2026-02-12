import 'package:flutter/material.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<TutorialPage> _pages = [
    TutorialPage(
      title: 'Welcome to Minesweeper!',
      description: 'The goal is to reveal all cells that do NOT contain mines without hitting a mine.',
      icon: Icons.grid_view_rounded,
      color: Colors.blue,
    ),
    TutorialPage(
      title: 'Tap to Reveal',
      description: 'Tap on a cell to reveal what\'s underneath. If it\'s a number, it shows how many mines are adjacent to that cell.',
      icon: Icons.touch_app,
      color: Colors.green,
    ),
    TutorialPage(
      title: 'Numbers are Clues',
      description: '1 = 1 mine nearby\n2 = 2 mines nearby\n...and so on!\n\nUse these clues to figure out where the mines are.',
      icon: Icons.looks_one,
      color: Colors.orange,
    ),
    TutorialPage(
      title: 'Flag the Mines',
      description: 'Long press (or enable Flag Mode) to place a flag on cells you think contain mines. This helps you keep track!',
      icon: Icons.flag,
      color: Colors.red,
    ),
    TutorialPage(
      title: 'Win the Game',
      description: 'Reveal all safe cells to win! Be careful - one wrong tap on a mine and it\'s game over!',
      icon: Icons.emoji_events,
      color: Colors.amber,
    ),
    TutorialPage(
      title: 'Battle Mode',
      description: 'Challenge other players in real-time! Race to clear your board first while watching your opponent\'s progress.',
      icon: Icons.flash_on,
      color: Colors.purple,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Play'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: page.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          page.icon,
                          size: 64,
                          color: page.color,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        page.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        page.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Page indicators
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? _pages[index].color
                        : Colors.grey.shade300,
                  ),
                );
              }),
            ),
          ),
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentPage > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  child: const Text('Previous'),
                ),
                if (_currentPage < _pages.length - 1)
                  ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Next'),
                  )
                else
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Start Playing!'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TutorialPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  TutorialPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
