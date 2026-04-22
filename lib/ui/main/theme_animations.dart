import 'package:flutter/material.dart';
import 'package:polaris/models/models.dart';

/// Maps theme animation config to Flutter transition widgets.
class ThemeTransition {
  ThemeTransition._();

  static Duration resolveDuration(ThemeAnimationConfig anim) =>
      Duration(milliseconds: anim.duration ?? _presetDuration(anim.preset));

  static Curve resolveCurve(ThemeAnimationConfig anim) =>
      _namedCurve(anim.curve) ?? _presetCurve(anim.preset);

  /// Wraps [child] in an [AnimatedSwitcher] using the theme's animation config.
  static AnimatedSwitcher switcher({
    required Widget child,
    required ThemeAnimationConfig anim,
  }) {
    return AnimatedSwitcher(
      duration: resolveDuration(anim),
      switchInCurve: resolveCurve(anim),
      switchOutCurve: resolveCurve(anim),
      transitionBuilder: _transitionBuilderFor(anim.preset),
      child: child,
    );
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static AnimatedSwitcherTransitionBuilder _transitionBuilderFor(
      String preset) {
    switch (preset) {
      case 'slide_fade':
        return (child, animation) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.12, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(opacity: animation, child: child),
            );
      case 'slide_up':
        return (child, animation) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(opacity: animation, child: child),
            );
      case 'zoom':
        return (child, animation) => ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
      case 'none':
        return AnimatedSwitcher.defaultTransitionBuilder;
      case 'fade_scale':
      default:
        return (child, animation) => ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
    }
  }

  static int _presetDuration(String preset) {
    switch (preset) {
      case 'none':
        return 0;
      case 'zoom':
        return 350;
      default:
        return 250;
    }
  }

  static Curve _presetCurve(String preset) {
    switch (preset) {
      case 'slide_fade':
      case 'slide_up':
        return Curves.easeOutCubic;
      case 'zoom':
        return Curves.easeInOutCubic;
      default:
        return Curves.easeOut;
    }
  }

  static Curve? _namedCurve(String? name) {
    if (name == null) return null;
    const map = <String, Curve>{
      'linear': Curves.linear,
      'ease': Curves.ease,
      'easeIn': Curves.easeIn,
      'easeOut': Curves.easeOut,
      'easeInOut': Curves.easeInOut,
      'easeOutCubic': Curves.easeOutCubic,
      'easeInCubic': Curves.easeInCubic,
      'easeInOutCubic': Curves.easeInOutCubic,
      'easeOutQuart': Curves.easeOutQuart,
      'easeInOutQuart': Curves.easeInOutQuart,
      'bounceOut': Curves.bounceOut,
      'elasticOut': Curves.elasticOut,
      'decelerate': Curves.decelerate,
      'fastOutSlowIn': Curves.fastOutSlowIn,
    };
    return map[name];
  }
}
