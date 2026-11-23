import 'package:material_ui/material_ui.dart';
import 'package:waste_lens/waste_lens.dart';

import 'app/di.dart';
import 'app/theme.dart';
import 'features/feed/view/today_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(
    // Whole app instrumented. In release builds WasteLens returns its child
    // untouched: zero overhead.
    const WasteLens(config: WasteLensConfig(overlay: true), child: BriefApp()),
  );
}

class BriefApp extends StatelessWidget {
  const BriefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brief',
      debugShowCheckedModeBanner: false,
      theme: BriefTheme.light(),
      darkTheme: BriefTheme.dark(),
      themeMode: ThemeMode.system,
      home: const TodayPage(),
    );
  }
}
