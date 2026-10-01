import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandedShell extends StatelessWidget {
  const BrandedShell({
    super.key,
    required this.child,
    this.showProductBowls = true,
    this.trailingHeader,
  });

  final Widget child;
  final bool showProductBowls;
  final Widget? trailingHeader;

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final horizontal = size.width >= 600 ? 32.0 : 20.0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.forestDeep,
            AppColors.forestMid,
            AppColors.forestDeep,
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          const _AmbientGlow(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    12,
                    horizontal,
                    16 + viewPadding.bottom.clamp(0, 8),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            _BrandHeader(trailing: trailingHeader),
                            if (showProductBowls) ...[
                              const SizedBox(height: 16),
                              const _ProductBowls(),
                            ],
                            const SizedBox(height: 18),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: child,
                            ),
                            const SizedBox(height: 20),
                            const _BrandHighlights(),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: _BrandFooter(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _GlowCircle(size: 220, opacity: 0.14),
          ),
          Positioned(
            bottom: 80,
            left: -70,
            child: _GlowCircle(size: 180, opacity: 0.10),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.lime.withValues(alpha: opacity),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Column(
          children: [
            _LogoMark(),
            SizedBox(height: 10),
            Text(
              'MAST QALANDER',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onForest,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 1.6,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'MQT',
              style: TextStyle(
                color: AppColors.lime,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 12),
            _ProductNames(),
          ],
        ),
        if (trailing != null) Positioned(top: 0, right: 0, child: trailing!),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.onForest.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.lime.withValues(alpha: 0.7)),
      ),
      child: const Icon(Icons.eco_rounded, color: AppColors.lime, size: 34),
    );
  }
}

class _ProductNames extends StatelessWidget {
  const _ProductNames();

  static const _items = [
    'Grains',
    'Oilseeds',
    'Pulses',
    'Spices',
    'Chickpeas',
    'Feed',
    'Dryfruits',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final name in _items)
          Text(
            name,
            style: TextStyle(
              color: name == 'Pulses' ? AppColors.lime : AppColors.onForest,
              fontWeight: name == 'Pulses' ? FontWeight.w800 : FontWeight.w500,
              fontSize: name == 'Pulses' ? 18 : 12,
              height: 1,
            ),
          ),
      ],
    );
  }
}

class _ProductBowls extends StatelessWidget {
  const _ProductBowls();

  static const _bowls = <(Color, IconData)>[
    (Color(0xFFC45C26), Icons.grain),
    (Color(0xFFF4F0E4), Icons.rice_bowl_outlined),
    (Color(0xFFE8B923), Icons.eco_outlined),
    (Color(0xFFE8E8E8), Icons.circle_outlined),
    (Color(0xFFB84A3A), Icons.spa_outlined),
    (Color(0xFF3A2A24), Icons.blur_on),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final bowl in _bowls)
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bowl.$1,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.onForest.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              bowl.$2,
              size: 20,
              color: bowl.$1.computeLuminance() > 0.55
                  ? AppColors.forestDeep
                  : AppColors.onForest,
            ),
          ),
      ],
    );
  }
}

class _BrandHighlights extends StatelessWidget {
  const _BrandHighlights();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Row(
        children: [
          Expanded(
            child: _HighlightCard(
              child: Column(
                children: [
                  Text(
                    'Established Since',
                    style: TextStyle(
                      color: AppColors.onForest,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '1975',
                    style: TextStyle(
                      color: AppColors.onForest,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
          _YearsBadge(),
          SizedBox(width: 12),
          Expanded(
            child: _HighlightCard(
              child: Text(
                'Origination, Processing, Branding & Distribution',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.onForest,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.onForest.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.onForest.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

class _YearsBadge extends StatelessWidget {
  const _YearsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.lime, width: 2),
        color: AppColors.forestDeep.withValues(alpha: 0.35),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '50',
            style: TextStyle(
              color: AppColors.lime,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            'YEARS',
            style: TextStyle(
              color: AppColors.onForest,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandFooter extends StatelessWidget {
  const _BrandFooter();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: AppColors.onForest, fontSize: 11, height: 1.4);
    return const Column(
      children: [
        Text(
          'Head Office  ·  Suite # 1602, 16th Floor,',
          textAlign: TextAlign.center,
          style: style,
        ),
        Text(
          'Muhammadi Trade Tower, New Chali, Karachi, Pakistan.',
          textAlign: TextAlign.center,
          style: style,
        ),
        SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            _FooterItem(Icons.language, 'www.mastqalandergroup.com'),
            _FooterItem(Icons.alternate_email, 'mastqalander.pk'),
            _FooterItem(Icons.phone_outlined, '+92 33 3305034'),
          ],
        ),
      ],
    );
  }
}

class _FooterItem extends StatelessWidget {
  const _FooterItem(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.limeSoft),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.onForest, fontSize: 11),
        ),
      ],
    );
  }
}

class WhitePanel extends StatelessWidget {
  const WhitePanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: child,
      ),
    );
  }
}

class MqtBanner extends StatelessWidget {
  const MqtBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mqtBar,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'MQT',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class PanelLogo extends StatelessWidget {
  const PanelLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.forest.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.eco_rounded,
            color: AppColors.forest,
            size: 30,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'MAST QALANDER',
          style: TextStyle(
            color: AppColors.forest,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class RequiredLabel extends StatelessWidget {
  const RequiredLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFD32F2F)),
            ),
          ],
        ),
      ),
    );
  }
}
