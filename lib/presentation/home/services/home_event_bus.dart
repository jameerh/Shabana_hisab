import 'dart:async';

abstract class HomeEvent {}

class HomeRefreshRequestedEvent extends HomeEvent {}
class DashboardDataChangedEvent extends HomeEvent {}
class RecurringTransactionGeneratedEvent extends HomeEvent {}
class BudgetWarningEvent extends HomeEvent {}

class HomeEventBus {
  static final HomeEventBus _instance = HomeEventBus._internal();
  factory HomeEventBus() => _instance;
  HomeEventBus._internal();

  final _controller = StreamController<HomeEvent>.broadcast();

  Stream<HomeEvent> get stream => _controller.stream;

  void publish(HomeEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
