import 'dart:ui';

import 'package:flutter/material.dart';

@immutable
class AccentPalette extends ThemeExtension<AccentPalette> {
  const AccentPalette({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.quaternary,
    required this.highlight,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color quaternary;
  final Color highlight;

  @override
  AccentPalette copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? quaternary,
    Color? highlight,
  }) {
    return AccentPalette(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      quaternary: quaternary ?? this.quaternary,
      highlight: highlight ?? this.highlight,
    );
  }

  @override
  AccentPalette lerp(ThemeExtension<AccentPalette>? other, double t) {
    if (other is! AccentPalette) {
      return this;
    }

    return AccentPalette(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      tertiary: Color.lerp(tertiary, other.tertiary, t) ?? tertiary,
      quaternary: Color.lerp(quaternary, other.quaternary, t) ?? quaternary,
      highlight: Color.lerp(highlight, other.highlight, t) ?? highlight,
    );
  }
}

@immutable
class GlassmorphismSurfaces extends ThemeExtension<GlassmorphismSurfaces> {
  const GlassmorphismSurfaces({
    required this.low,
    required this.medium,
    required this.high,
    required this.luminous,
    required this.border,
    this.blurSigma = 24,
  });

  final Color low;
  final Color medium;
  final Color high;
  final Color luminous;
  final Color border;
  final double blurSigma;

  @override
  GlassmorphismSurfaces copyWith({
    Color? low,
    Color? medium,
    Color? high,
    Color? luminous,
    Color? border,
    double? blurSigma,
  }) {
    return GlassmorphismSurfaces(
      low: low ?? this.low,
      medium: medium ?? this.medium,
      high: high ?? this.high,
      luminous: luminous ?? this.luminous,
      border: border ?? this.border,
      blurSigma: blurSigma ?? this.blurSigma,
    );
  }

  @override
  GlassmorphismSurfaces lerp(
      ThemeExtension<GlassmorphismSurfaces>? other,
      double t,
      ) {
    if (other is! GlassmorphismSurfaces) {
      return this;
    }

    return GlassmorphismSurfaces(
      low: Color.lerp(low, other.low, t) ?? low,
      medium: Color.lerp(medium, other.medium, t) ?? medium,
      high: Color.lerp(high, other.high, t) ?? high,
      luminous: Color.lerp(luminous, other.luminous, t) ?? luminous,
      border: Color.lerp(border, other.border, t) ?? border,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t) ?? blurSigma,
    );
  }
}

@immutable
class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({
    required this.short,
    required this.medium,
    required this.long,
    required this.delay,
    required this.standard,
    required this.emphasized,
    required this.pulsed,
  });

  final Duration short;
  final Duration medium;
  final Duration long;
  final Duration delay;
  final Curve standard;
  final Curve emphasized;
  final Curve pulsed;

  @override
  AppMotion copyWith({
    Duration? short,
    Duration? medium,
    Duration? long,
    Duration? delay,
    Curve? standard,
    Curve? emphasized,
    Curve? pulsed,
  }) {
    return AppMotion(
      short: short ?? this.short,
      medium: medium ?? this.medium,
      long: long ?? this.long,
      delay: delay ?? this.delay,
      standard: standard ?? this.standard,
      emphasized: emphasized ?? this.emphasized,
      pulsed: pulsed ?? this.pulsed,
    );
  }

  @override
  AppMotion lerp(ThemeExtension<AppMotion>? other, double t) {
    if (other is! AppMotion) {
      return this;
    }

    Duration _lerpDuration(Duration a, Duration b) {
      final double result = a.inMilliseconds + (b.inMilliseconds - a.inMilliseconds) * t;
      return Duration(milliseconds: result.round());
    }

    return AppMotion(
      short: _lerpDuration(short, other.short),
      medium: _lerpDuration(medium, other.medium),
      long: _lerpDuration(long, other.long),
      delay: _lerpDuration(delay, other.delay),
      standard: t < 0.5 ? standard : other.standard,
      emphasized: t < 0.5 ? emphasized : other.emphasized,
      pulsed: t < 0.5 ? pulsed : other.pulsed,
    );
  }
}