abstract class FeatureModule {
  String get id;
  String get name;
  bool get isEnabled;
  void initialize();
}

class FeatureRegistry {
  static final FeatureRegistry _instance = FeatureRegistry._internal();
  factory FeatureRegistry() => _instance;
  FeatureRegistry._internal();

  final Map<String, FeatureModule> _modules = {};

  void registerModule(FeatureModule module) {
    _modules[module.id] = module;
    module.initialize();
  }

  bool isFeatureEnabled(String id) {
    return _modules[id]?.isEnabled ?? false;
  }
}
