import 'package:json_annotation/json_annotation.dart';

part 'story_state.g.dart';

@JsonSerializable(explicitToJson: true)
class StoryState {
  final String storyId;
  final Map<String, dynamic> statusUpdates;
  final List<Map<String, String>> nextActions;
  final DateTime updatedAt;

  StoryState({
    required this.storyId,
    required this.statusUpdates,
    required this.nextActions,
    required this.updatedAt,
  });

  factory StoryState.fromJson(Map<String, dynamic> json) =>
      _$StoryStateFromJson(json);
  Map<String, dynamic> toJson() => _$StoryStateToJson(this);
}
