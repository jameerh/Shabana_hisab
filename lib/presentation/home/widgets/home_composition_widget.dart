import 'package:flutter/material.dart';

class HomeCompositionWidget extends StatelessWidget {
  final Widget greetingSection;
  final Widget intelligenceSection;
  final Widget universalCommandCenter;
  final Widget transactionSliver;
  final Future<void> Function()? onRefresh;

  const HomeCompositionWidget({
    Key? key,
    required this.greetingSection,
    required this.intelligenceSection,
    required this.universalCommandCenter,
    required this.transactionSliver,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(bottom: false, child: greetingSection),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: intelligenceSection,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyCommandCenterDelegate(universalCommandCenter),
          ),
          transactionSliver,
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class _StickyCommandCenterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyCommandCenterDelegate(this.child);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  double get maxExtent => 64.0;

  @override
  double get minExtent => 64.0;

  @override
  bool shouldRebuild(covariant _StickyCommandCenterDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
