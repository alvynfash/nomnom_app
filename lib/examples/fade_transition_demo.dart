import 'package:flutter/material.dart';
import '../utils/fade_page_route.dart';

/// Demo screen showing fade transition usage
class FadeTransitionDemo extends StatelessWidget {
  const FadeTransitionDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fade Transition Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Navigation Transitions Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Standard fade navigation
            ElevatedButton(
              onPressed: () {
                FadeNavigation.push(
                  context,
                  const _DemoScreen(title: 'Fade Push', color: Colors.blue),
                );
              },
              child: const Text('Fade Push'),
            ),

            const SizedBox(height: 16),

            // Fade replacement
            ElevatedButton(
              onPressed: () {
                FadeNavigation.pushReplacement(
                  context,
                  const _DemoScreen(title: 'Fade Replace', color: Colors.green),
                );
              },
              child: const Text('Fade Replace'),
            ),

            const SizedBox(height: 16),

            // Custom duration fade
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  FadePageRoute(
                    child: const _DemoScreen(
                      title: 'Custom Duration',
                      color: Colors.purple,
                    ),
                    duration: const Duration(milliseconds: 600),
                    reverseDuration: const Duration(milliseconds: 400),
                  ),
                );
              },
              child: const Text('Custom Duration Fade'),
            ),

            const SizedBox(height: 32),

            const Text(
              'Compare with standard MaterialPageRoute:',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 16),

            // Standard material route for comparison
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const _DemoScreen(
                      title: 'Standard Slide',
                      color: Colors.orange,
                    ),
                  ),
                );
              },
              child: const Text('Standard Slide Transition'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Demo screen to navigate to
class _DemoScreen extends StatelessWidget {
  final String title;
  final Color color;

  const _DemoScreen({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: color.withValues(alpha: 0.1),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Back'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  FadeNavigation.push(
                    context,
                    const _DemoScreen(title: 'Nested Fade', color: Colors.red),
                  );
                },
                child: const Text('Push Another (Fade)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
