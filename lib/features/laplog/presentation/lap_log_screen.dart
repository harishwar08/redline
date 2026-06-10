import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system.dart';
import '../../../core/format.dart';
import '../application/stats_providers.dart';
import '../data/stats.dart';

// Signature metallic bars — the one gradient the system keeps.
const _barTop = Color(0xFFFFFFFF);
const _barBottom = Color(0xFF3A3C3F);

/// Lap Log — the STATS screen: focus history as a metallic bar chart with a
/// Week/Month toggle, a hero car, and distance / avg / best summary cards.
class LapLogScreen extends ConsumerStatefulWidget {
  const LapLogScreen({super.key});

  @override
  ConsumerState<LapLogScreen> createState() => _LapLogScreenState();
}

class _LapLogScreenState extends ConsumerState<LapLogScreen> {
  LapRange _range = LapRange.week;

  @override
  Widget build(BuildContext context) {
    final chart = ref.watch(statsServiceProvider).chart(_range);
    final bars = chart.bars;
    final totalMin = chart.totalMinutes;
    final avg = chart.averageMinutes;
    final best = chart.bestMinutes;
    final hasData = chart.hasData;
    final peak = chart.peakIndex; // peak bar gets the accent-red label

    // Everything fits on one screen (no scroll): fixed compact elements with
    // the chart card in Expanded to absorb the remaining space.
    return DsBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(DS.s17, DS.s8, DS.s17, DS.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1 — Header: title + WEEK/MONTH segmented pill.
              Row(
                children: [
                  const Text('Stats', style: DSText.screenTitle),
                  const Spacer(),
                  _RangeToggle(range: _range, onChanged: (r) => setState(() => _range = r)),
                ],
              ),
              const SizedBox(height: DS.s24),

              // 2 — Hero car (full-bleed contain; the one permitted shadow).
              const _HeroCar(),
              const SizedBox(height: DS.s24),

              // 3 — Three metric cards (focus time for the selected period).
              Row(
                children: [
                  _StatCard(
                    icon: Icons.schedule,
                    label: 'Hours',
                    value: formatHoursMinutes(totalMin),
                  ),
                  const SizedBox(width: DS.s12),
                  _StatCard(
                    icon: Icons.speed_outlined,
                    label: 'Average',
                    value: formatHoursMinutes(avg),
                  ),
                  const SizedBox(width: DS.s12),
                  _StatCard(
                    icon: Icons.emoji_events_outlined,
                    label: 'Best',
                    value: formatHoursMinutes(best),
                    valueColor: DS.accent, // BEST — the allowed accent use here
                  ),
                ],
              ),
              const SizedBox(height: DS.s17),

              // 4 — Bar chart card, fills the remaining space. Nothing renders
              // beneath it.
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(DS.s17, DS.s17, DS.s17, DS.s8),
                  decoration: DS.cardDecoration(),
                  child: hasData ? _Chart(bars: bars, peak: peak) : const _EmptyChart(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.range, required this.onChanged});

  final LapRange range;
  final ValueChanged<LapRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: DS.cardRaised,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: DS.hairline),
      ),
      child: Row(
        children: [
          for (final r in LapRange.values)
            GestureDetector(
              onTap: () => onChanged(r),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: r == range ? DS.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  r == LapRange.week ? 'WEEK' : 'MONTH',
                  style: TextStyle(
                    fontFamily: DS.fontFamily,
                    color: r == range ? Colors.white : DS.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroCar extends StatelessWidget {
  const _HeroCar();

  // Source image is 977×303 (transparent PNG). AspectRatio takes the full
  // available width and BoxFit.contain shows the whole car with no cropping.
  static const double _aspect = 977 / 303;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // The one shadow permitted in the whole app — lets the car rest on black.
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Color(0x73000000), blurRadius: 30, offset: Offset(0, 12))],
      ),
      child: AspectRatio(
        aspectRatio: _aspect,
        child: Image.asset(
          'assets/images/new_car.png',
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.bars, required this.peak});

  final List<LapBar> bars;
  final int peak;

  @override
  Widget build(BuildContext context) {
    final maxY = bars.fold<double>(0, (a, b) => b.minutes > a ? b.minutes : a);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxY * 1.25).clamp(10, double.infinity),
        // Press-and-hold a bar to reveal its focus time as a DS tooltip. The
        // large top + side touch threshold makes every column (even empty
        // 0-height bars) hold-able across its full height.
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchExtraThreshold: const EdgeInsets.only(top: 1000, left: 14, right: 14),
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => DS.cardRaised,
            tooltipBorderRadius: BorderRadius.circular(DS.rTile),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${formatHoursMinutes(rod.toY)} hr',
              const TextStyle(
                  fontFamily: DS.fontFamily, color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= bars.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    bars[i].label,
                    style: TextStyle(
                      fontFamily: DS.fontFamily,
                      color: i == peak ? DS.accent : DS.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < bars.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: bars[i].minutes,
                  width: 14,
                  borderRadius: BorderRadius.zero, // flat tops
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_barTop, _barBottom],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = DS.textPrimary,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: DS.s12, vertical: DS.s12),
        decoration: DS.cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: DS.textSecondary, size: 18),
            const SizedBox(height: 6),
            Text(label.toUpperCase(), style: DSText.metricLabel, textAlign: TextAlign.center),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: RichText(
                text: TextSpan(
                  text: value,
                  style: DSText.statValue.copyWith(color: valueColor, fontSize: 22),
                  children: const [
                    TextSpan(
                      text: ' hr',
                      style: TextStyle(
                          fontFamily: DS.fontFamily,
                          color: DS.textTertiary, fontSize: 13, fontWeight: FontWeight.w400, fontStyle: FontStyle.normal),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('NO LAPS LOGGED YET', style: DSText.metricLabel),
    );
  }
}
