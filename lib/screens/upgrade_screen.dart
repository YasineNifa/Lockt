import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/revenue_provider.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Icon(Icons.verified_user_outlined, size: 80, color: Colors.amber),
                  const SizedBox(height: 24),
                  Text(
                    'Unlock Peace of Mind',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Get the "Pack Sérénité" for a lifetime of tranquility.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  const _FeatureRow(icon: Icons.photo_camera, title: 'Photo Proof', subtitle: 'See it to believe it.'),
                  const _FeatureRow(icon: Icons.mic, title: 'Voice Memos', subtitle: 'Record your reassurance.'),
                  const _FeatureRow(icon: Icons.list_alt, title: 'Unlimited Routines', subtitle: 'For every part of your life.'),
                  const _FeatureRow(icon: Icons.timer, title: 'Smart Reset', subtitle: 'Custom schedules.'),
                  const _FeatureRow(icon: Icons.widgets, title: 'Home Widget', subtitle: 'Check status at a glance.'),
                  const SizedBox(height: 40),
                  FilledButton(
                    onPressed: () {
                      context.read<RevenueProvider>().purchaseLifetime();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      'Get Lifetime Access',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                       context.read<RevenueProvider>().restorePurchases();
                       Navigator.pop(context);
                    },
                    child: const Text('Restore Purchase'),
                  ),
                ],
              ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
