import 'package:flutter/material.dart';

class ScrollHideFab extends StatefulWidget {
  final Widget child; // O FAB ou qualquer widget que você quiser esconder
  final ScrollController scrollController;

  ScrollHideFab({
    required this.child,
    required this.scrollController,
  });

  @override
  _ScrollHideFabState createState() => _ScrollHideFabState();
}

class _ScrollHideFabState extends State<ScrollHideFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    widget.scrollController.addListener(_onScroll);
    _animationController.forward();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController.position.atEdge) {
      if (widget.scrollController.position.pixels == 0) {
        // Está no topo
        _showFab();
      } else {
        // Está no fim
        _hideFab();
      }
    } else {
      _showFab();
    }
  }

  void _showFab() {
    if (!_isFabVisible) {
      setState(() {
        _isFabVisible = true;
      });
      _animationController.forward();
    }
  }

  void _hideFab() {
    if (_isFabVisible) {
      setState(() {
        _isFabVisible = false;
      });
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: _isFabVisible ? widget.child : Container(),
    );
  }
}
