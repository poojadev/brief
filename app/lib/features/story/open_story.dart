import 'package:material_ui/material_ui.dart';

import '../../app/di.dart';
import '../../app/lab.dart';
import '../../data/models/story.dart';
import 'view/story_live_bug.dart';
import 'view/story_live_fix.dart';

/// The story page, in the Lab's Episode 5 mode.
Widget storyPageFor(Story story) => getIt<LabSettings>().liveMode == LabMode.bug
    ? StoryLiveBug(story: story)
    : StoryLiveFix(story: story);
