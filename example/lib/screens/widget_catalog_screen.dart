import 'package:material_ui/material_ui.dart';
import 'package:trainvent_general/trainvent_general.dart';

import 'triangle_loading_indicator_screen.dart';

class WidgetCatalogScreen extends StatelessWidget {
  const WidgetCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widget Library')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: const TriangleLoadingIndicator(
                size: 40,
                background: Colors.black54,
              ),
              title: const Text('TriangleLoadingIndicator'),
              subtitle: const Text('Preview and test the loading animation'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TriangleLoadingIndicatorScreen(),
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
