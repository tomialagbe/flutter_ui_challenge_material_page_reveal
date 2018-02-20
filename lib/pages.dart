import 'dart:ui';

final pages = [
  new PageViewModel(
    const Color(0xFF678FB4),
    'assets/hotels.png',
    'Hotels',
    'All hotels and hostels are sorted by hospitality rating',
    'assets/key.png'
  ),
  new PageViewModel(
    const Color(0xFF65B0B4),
    'assets/banks.png',
    'Banks',
    'We carefully verify all banks before adding them into the app',
    'assets/wallet.png'
  ),
  new PageViewModel(
    const Color(0xFF9B90BC),
    'assets/stores.png',
    'Store',
    'All local stores are categorized for your convenience',
    'assets/shopping_cart.png',
  ),
];

class PageViewModel {
  final Color color;
  final String heroAssetPath;
  final String title;
  final String body;
  final String iconAssetPath;

  PageViewModel(
    this.color,
    this.heroAssetPath,
    this.title,
    this.body,
    this.iconAssetPath,
  );
}

class PagerIndicatorViewModel {
  final List<PageViewModel> pages;
  final int activeIndex;
  final double transitionAmount; // [-1.0, 1.0] where negative means moving to previous and positive means moving to next.

  PagerIndicatorViewModel(
    this.pages,
    this.activeIndex,
    this.transitionAmount,
  );
}

class PagerBubbleViewModel {
  final String iconAssetPath;
  final Color color;
  final bool isHollow;
  final bool isActive;
  final double transitionAmount;

  PagerBubbleViewModel(
    this.iconAssetPath,
    this.color,
    this.isHollow,
    this.isActive,
    this.transitionAmount,
  );
}