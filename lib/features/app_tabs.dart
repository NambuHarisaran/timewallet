/// Home-shell tab indexes in one place. The dashboard GROW chips and header
/// jump between tabs by index; centralizing the numbers means a nav reshuffle
/// is a single-file edit. (Wealth + Tools merged into Plan; Review added.)
class AppTabs {
  AppTabs._();
  static const int home = 0;
  static const int goals = 1;
  static const int plan = 2;
  static const int review = 3;
  static const int profile = 4;
}
