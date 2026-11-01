import '../models/dashboard_card.dart';

abstract class DashboardCardProvider {
  /// Returns a list of available cards from this provider based on current context.
  Future<List<DashboardCard>> getAvailableCards();
}

class DashboardRegistry {
  static final DashboardRegistry _instance = DashboardRegistry._internal();
  factory DashboardRegistry() => _instance;
  DashboardRegistry._internal();

  final List<DashboardCardProvider> _providers = [];

  void registerProvider(DashboardCardProvider provider) {
    if (!_providers.contains(provider)) {
      _providers.add(provider);
    }
  }

  void unregisterProvider(DashboardCardProvider provider) {
    _providers.remove(provider);
  }

  /// Fetches all cards from all registered providers, sorts by score (descending).
  Future<List<DashboardCard>> getScoredCards() async {
    List<DashboardCard> allCards = [];
    
    for (var provider in _providers) {
      final cards = await provider.getAvailableCards();
      allCards.addAll(cards);
    }

    // Sort descending by score
    allCards.sort((a, b) => b.score.compareTo(a.score));
    return allCards;
  }
}
