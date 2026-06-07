import 'package:flutter/material.dart';

import '../../../core/tokens.dart';
import '../../../core/typography.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/controls.dart';
import '../../../shared/widgets/indicators.dart';
import '../../../shared/widgets/panels.dart';
import '../../../shared/widgets/screen_fx.dart';

/// Dev-only style gallery — renders every component in the vintage palette so
/// the design system can be eyeballed. Reachable at `/gallery`.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _sound = true;
  bool _auto = false;
  int _minutes = 25;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('STYLE GALLERY')),
      body: ScreenFx(
        child: ListView(
          padding: const EdgeInsets.all(RSpace.l),
          children: [
            _section('Typography'),
            Text('Draft the Q3 narrative', style: RText.h2()),
            const SizedBox(height: 4),
            Text('18:24 · 03/05 · 9:41', style: RText.readout()),
            const SizedBox(height: 4),
            Text('NOW DRIVING', style: RText.label()),
            _section('Panels & plates'),
            BakelitePanel(
              rim: PanelRim.brass,
              child: Row(
                children: [
                  const DomeScrew(),
                  const SizedBox(width: RSpace.m),
                  Expanded(child: Text('Bakelite panel · brass rim', style: RText.body())),
                  const DomeScrew(),
                ],
              ),
            ),
            const SizedBox(height: RSpace.m),
            const OdometerReadout(text: '18:24', size: 36),
            _section('Hardware'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChromeButton(icon: Icons.refresh, onPressed: () {}, semanticLabel: 'Reset'),
                EngineButton(label: 'Start\nLap', onPressed: () {}, active: true),
                ChromeButton(icon: Icons.skip_next, onPressed: () {}, semanticLabel: 'Next'),
              ],
            ),
            _section('Plate buttons'),
            PlateButton(label: 'Enter the Garage', onPressed: () {}),
            const SizedBox(height: RSpace.s),
            PlateButton(label: 'Park for Now', filled: false, onPressed: () {}),
            const SizedBox(height: RSpace.s),
            PlateButton(label: 'Abort the Lap', filled: false, danger: true, onPressed: () {}),
            _section('Switches & steppers'),
            Row(
              children: [
                Text('SOUND', style: RText.label()),
                const Spacer(),
                FlipSwitch(value: _sound, onChanged: (v) => setState(() => _sound = v)),
              ],
            ),
            const SizedBox(height: RSpace.s),
            Row(
              children: [
                Text('AUTO-START', style: RText.label()),
                const Spacer(),
                FlipSwitch(value: _auto, onChanged: (v) => setState(() => _auto = v)),
              ],
            ),
            const SizedBox(height: RSpace.m),
            Center(
              child: KnurledStepper(
                value: _minutes,
                suffix: 'min',
                onChanged: (v) => setState(() => _minutes = v),
              ),
            ),
            _section('Indicators'),
            Row(
              children: [
                const TellTaleLamp(color: RColors.oxbloodBright, lit: true),
                const SizedBox(width: 6),
                const TellTaleLamp(color: RColors.amber, lit: true),
                const SizedBox(width: 6),
                const TellTaleLamp(color: RColors.brassHi),
                const SizedBox(width: 6),
                const TellTaleLamp(color: RColors.chrome),
              ],
            ),
            const SizedBox(height: RSpace.m),
            const FuelGaugeProgress(value: 0.62),
            _section('Ledger'),
            BakelitePanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  LedgerRow(
                    title: 'Draft Q3 narrative',
                    leading: const TellTaleLamp(color: RColors.oxbloodBright, lit: true, size: 12),
                    trailing: Text('03/05', style: RText.readout(size: 15)),
                  ),
                  LedgerRow(
                    title: 'Inbox to zero',
                    leading: const TellTaleLamp(color: RColors.brassHi, size: 12),
                    trailing: Text('00/02', style: RText.readout(size: 15)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RSpace.huge),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: RSpace.xl, bottom: RSpace.s),
        child: Text(title.toUpperCase(), style: RText.label(color: RColors.brassHi)),
      );
}
