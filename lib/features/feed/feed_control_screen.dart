import 'package:flutter/material.dart';

class FeedControlScreen extends StatefulWidget {
  const FeedControlScreen({super.key});

  @override
  State<FeedControlScreen> createState() => _FeedControlScreenState();
}

class _FeedControlScreenState extends State<FeedControlScreen> {
  // Feed Algorithm Parameters
  double _trendingWeight = 0.4;
  double _personalizedWeight = 0.4;
  double _friendWeight = 0.2;
  double _adFrequency = 0.1;
  bool _enableAIGeneration = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Controls
          Expanded(
            flex: 2,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Feed Algorithm Tuning', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    _SliderControl(
                      label: 'Trending Content Weight',
                      value: _trendingWeight,
                      onChanged: (v) => setState(() => _trendingWeight = v),
                    ),
                    _SliderControl(
                      label: 'Personalized (ML) Weight',
                      value: _personalizedWeight,
                      onChanged: (v) => setState(() => _personalizedWeight = v),
                    ),
                    _SliderControl(
                      label: 'Friends Activity Weight',
                      value: _friendWeight,
                      onChanged: (v) => setState(() => _friendWeight = v),
                    ),
                    const Divider(),
                    _SliderControl(
                      label: 'Ad/Promo Frequency',
                      value: _adFrequency,
                      onChanged: (v) => setState(() => _adFrequency = v),
                      activeColor: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Enable AI Recommendations'),
                      subtitle: const Text('Use vector embeddings for similarity matching'),
                      value: _enableAIGeneration,
                      onChanged: (v) => setState(() => _enableAIGeneration = v),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Algorithm parameters updated')));
                      },
                      child: const Text('Deploy Changes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Simulation Preview
          Expanded(
            flex: 1,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Simulation', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Container(
                      height: 500,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black,
                      ),
                      child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          // Mock feed item
                          return Container(
                            height: 100,
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.movie, color: Colors.grey),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Movie Title $index', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                      Text(
                                        index % 3 == 0 ? 'Trending' : (index % 2 == 0 ? 'For You' : 'Friend Liked'),
                                        style: TextStyle(
                                          color: index % 3 == 0 ? Colors.blue : (index % 2 == 0 ? Colors.green : Colors.purple),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderControl extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final Color? activeColor;

  const _SliderControl({required this.label, required this.value, required this.onChanged, this.activeColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${(value * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
