import 'package:flutter/widgets.dart';

class RestartWidget extends StatefulWidget {
  RestartWidget({required this.child}) : super(key: _rootKey);

  final Widget child;

  static final GlobalKey<_RestartWidgetState> _rootKey =
      GlobalKey<_RestartWidgetState>();

  static void restart() => _rootKey.currentState?.restart();

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}
