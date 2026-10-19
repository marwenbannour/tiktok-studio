int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
String _str(dynamic v) => v == null ? '' : '$v';
List<Map<String, dynamic>> _maps(dynamic v) => v is List
    ? v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
    : <Map<String, dynamic>>[];
List<String> _strs(dynamic v) => v is List ? v.map((e) => '$e').toList() : <String>[];

String two(int n) => n.toString().padLeft(2, '0');

class Segment {
  final int from;
  final int to;
  final String screen;
  final String text;
  final String voice;

  const Segment({
    required this.from,
    required this.to,
    required this.screen,
    required this.text,
    required this.voice,
  });

  String get range => '${two(from)}–${two(to)}s';

  factory Segment.fromJson(Map<String, dynamic> j) => Segment(
        from: _int(j['from']),
        to: _int(j['to']),
        screen: _str(j['screen']),
        text: _str(j['text']),
        voice: _str(j['voice']),
      );

  Map<String, dynamic> toJson() =>
      {'from': from, 'to': to, 'screen': screen, 'text': text, 'voice': voice};

  Segment copyWith({String? screen, String? text, String? voice}) => Segment(
        from: from,
        to: to,
        screen: screen ?? this.screen,
        text: text ?? this.text,
        voice: voice ?? this.voice,
      );
}

class StepItem {
  final String title;
  final String detail;
  const StepItem(this.title, this.detail);

  factory StepItem.fromJson(Map<String, dynamic> j) =>
      StepItem(_str(j['title']), _str(j['detail']));

  Map<String, dynamic> toJson() => {'title': title, 'detail': detail};
}

class VideoScript {
  final String title;
  final String hookIdea;
  final List<Segment> segments;
  final String code;
  final String codeNote;
  final List<StepItem> steps;
  final String caption;
  final List<String> hashtags;
  final List<String> tips;
  final String category;
  final String style;
  final int duration;
  final int createdAt;

  // ---- حقول من قاعدة البيانات (موش من الـAPI) ----
  final int? dbId;
  final bool isFavorite;
  final int? publishedAt;
  final int? views;
  final int? likes;
  final int? comments;

  bool get hasStats => views != null || likes != null || comments != null;

  const VideoScript({
    required this.title,
    required this.hookIdea,
    required this.segments,
    required this.code,
    required this.codeNote,
    required this.steps,
    required this.caption,
    required this.hashtags,
    required this.tips,
    required this.category,
    required this.style,
    required this.duration,
    required this.createdAt,
    this.dbId,
    this.isFavorite = false,
    this.publishedAt,
    this.views,
    this.likes,
    this.comments,
  });

  factory VideoScript.fromJson(Map<String, dynamic> j) => VideoScript(
        title: _str(j['title']).isEmpty ? 'الفيديو متاعك' : _str(j['title']),
        hookIdea: _str(j['hook_idea']),
        segments: _maps(j['segments']).map(Segment.fromJson).toList(),
        code: _str(j['code']),
        codeNote: _str(j['code_note']),
        steps: _maps(j['steps']).map(StepItem.fromJson).toList(),
        caption: _str(j['caption']),
        hashtags: _strs(j['hashtags']),
        tips: _strs(j['tips']),
        category: _str(j['category']),
        style: _str(j['style']),
        duration: _int(j['duration']),
        createdAt: _int(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'hook_idea': hookIdea,
        'segments': segments.map((s) => s.toJson()).toList(),
        'code': code,
        'code_note': codeNote,
        'steps': steps.map((s) => s.toJson()).toList(),
        'caption': caption,
        'hashtags': hashtags,
        'tips': tips,
        'category': category,
        'style': style,
        'duration': duration,
        'createdAt': createdAt,
      };

  VideoScript copyWith({
    List<Segment>? segments,
    int? dbId,
    bool? isFavorite,
    int? publishedAt,
    bool clearPublished = false,
    int? views,
    int? likes,
    int? comments,
    bool setStats = false,
  }) =>
      VideoScript(
        title: title,
        hookIdea: hookIdea,
        segments: segments ?? this.segments,
        code: code,
        codeNote: codeNote,
        steps: steps,
        caption: caption,
        hashtags: hashtags,
        tips: tips,
        category: category,
        style: style,
        duration: duration,
        createdAt: createdAt,
        dbId: dbId ?? this.dbId,
        isFavorite: isFavorite ?? this.isFavorite,
        publishedAt: clearPublished ? null : (publishedAt ?? this.publishedAt),
        views: setStats ? views : (views ?? this.views),
        likes: setStats ? likes : (likes ?? this.likes),
        comments: setStats ? comments : (comments ?? this.comments),
      );

  VideoScript withSegment(int index, Segment s) =>
      copyWith(segments: [...segments]..[index] = s);

  String voiceText() => segments.map((s) => s.voice).join('\n');

  String captionText() => '$caption\n\n${hashtags.join(' ')}';

  String fullText() {
    final b = StringBuffer()..writeln(title)..writeln();
    for (final s in segments) {
      b
        ..writeln('[${s.range}]')
        ..writeln('الشاشة: ${s.screen}')
        ..writeln('النص: ${s.text}')
        ..writeln('الصوت: ${s.voice}')
        ..writeln();
    }
    if (code.trim().isNotEmpty) {
      b..writeln('الكود:')..writeln(code)..writeln();
    }
    b.writeln(captionText());
    return b.toString();
  }
}

enum PlanStatus {
  idea('💡 فكرة'),
  filmed('🎬 تصوّر'),
  posted('✅ تنشر');

  final String label;
  const PlanStatus(this.label);

  PlanStatus get next => PlanStatus.values[(index + 1) % PlanStatus.values.length];
}

/// فيديو مبرمج في «البرنامج»
class PlannedVideo {
  final int id;
  final String title;
  final DateTime date;
  final PlanStatus status;
  final bool reminder;

  /// createdAt متاع السكريبت المربوط (إذا فما)
  final int? scriptId;

  const PlannedVideo({
    required this.id,
    required this.title,
    required this.date,
    this.status = PlanStatus.idea,
    this.reminder = true,
    this.scriptId,
  });

  /// id صالح للـnotification (int 32 bits)
  int get notificationId => id % 0x7fffffff;

  PlannedVideo copyWith({String? title, DateTime? date, PlanStatus? status, bool? reminder}) =>
      PlannedVideo(
        id: id,
        title: title ?? this.title,
        date: date ?? this.date,
        status: status ?? this.status,
        reminder: reminder ?? this.reminder,
        scriptId: scriptId,
      );

  factory PlannedVideo.fromJson(Map<String, dynamic> j) => PlannedVideo(
        id: _int(j['id']),
        title: _str(j['title']),
        date: DateTime.fromMillisecondsSinceEpoch(_int(j['date'])),
        status: PlanStatus.values.firstWhere((s) => s.name == j['status'],
            orElse: () => PlanStatus.idea),
        reminder: j['reminder'] != false,
        scriptId: j['scriptId'] == null ? null : _int(j['scriptId']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.millisecondsSinceEpoch,
        'status': status.name,
        'reminder': reminder,
        'scriptId': scriptId,
      };
}
