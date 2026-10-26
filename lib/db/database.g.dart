// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ScriptsTable extends Scripts with TableInfo<$ScriptsTable, Script> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScriptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
      'style', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _publishedAtMeta =
      const VerificationMeta('publishedAt');
  @override
  late final GeneratedColumn<int> publishedAt = GeneratedColumn<int>(
      'published_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _viewsMeta = const VerificationMeta('views');
  @override
  late final GeneratedColumn<int> views = GeneratedColumn<int>(
      'views', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _likesMeta = const VerificationMeta('likes');
  @override
  late final GeneratedColumn<int> likes = GeneratedColumn<int>(
      'likes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _commentsMeta =
      const VerificationMeta('comments');
  @override
  late final GeneratedColumn<int> comments = GeneratedColumn<int>(
      'comments', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _seriesTitleMeta =
      const VerificationMeta('seriesTitle');
  @override
  late final GeneratedColumn<String> seriesTitle = GeneratedColumn<String>(
      'series_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _episodeMeta =
      const VerificationMeta('episode');
  @override
  late final GeneratedColumn<int> episode = GeneratedColumn<int>(
      'episode', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        category,
        style,
        duration,
        content,
        model,
        isFavorite,
        publishedAt,
        createdAt,
        views,
        likes,
        comments,
        seriesTitle,
        episode
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scripts';
  @override
  VerificationContext validateIntegrity(Insertable<Script> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('style')) {
      context.handle(
          _styleMeta, style.isAcceptableOrUnknown(data['style']!, _styleMeta));
    } else if (isInserting) {
      context.missing(_styleMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('published_at')) {
      context.handle(
          _publishedAtMeta,
          publishedAt.isAcceptableOrUnknown(
              data['published_at']!, _publishedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('views')) {
      context.handle(
          _viewsMeta, views.isAcceptableOrUnknown(data['views']!, _viewsMeta));
    }
    if (data.containsKey('likes')) {
      context.handle(
          _likesMeta, likes.isAcceptableOrUnknown(data['likes']!, _likesMeta));
    }
    if (data.containsKey('comments')) {
      context.handle(_commentsMeta,
          comments.isAcceptableOrUnknown(data['comments']!, _commentsMeta));
    }
    if (data.containsKey('series_title')) {
      context.handle(
          _seriesTitleMeta,
          seriesTitle.isAcceptableOrUnknown(
              data['series_title']!, _seriesTitleMeta));
    }
    if (data.containsKey('episode')) {
      context.handle(_episodeMeta,
          episode.isAcceptableOrUnknown(data['episode']!, _episodeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Script map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Script(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      style: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}style'])!,
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      publishedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}published_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      views: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}views']),
      likes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}likes']),
      comments: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}comments']),
      seriesTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}series_title']),
      episode: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}episode']),
    );
  }

  @override
  $ScriptsTable createAlias(String alias) {
    return $ScriptsTable(attachedDatabase, alias);
  }
}

class Script extends DataClass implements Insertable<Script> {
  final int id;
  final String title;
  final String category;
  final String style;
  final int duration;

  /// JSON الكامل متاع VideoScript (segments, code, steps, caption, hashtags, tips)
  final String content;
  final String model;
  final bool isFavorite;

  /// وقت النشر على TikTok (null = ما تنشرش)
  final int? publishedAt;
  final int createdAt;
  final int? views;
  final int? likes;
  final int? comments;
  final String? seriesTitle;
  final int? episode;
  const Script(
      {required this.id,
      required this.title,
      required this.category,
      required this.style,
      required this.duration,
      required this.content,
      required this.model,
      required this.isFavorite,
      this.publishedAt,
      required this.createdAt,
      this.views,
      this.likes,
      this.comments,
      this.seriesTitle,
      this.episode});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['style'] = Variable<String>(style);
    map['duration'] = Variable<int>(duration);
    map['content'] = Variable<String>(content);
    map['model'] = Variable<String>(model);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || publishedAt != null) {
      map['published_at'] = Variable<int>(publishedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || views != null) {
      map['views'] = Variable<int>(views);
    }
    if (!nullToAbsent || likes != null) {
      map['likes'] = Variable<int>(likes);
    }
    if (!nullToAbsent || comments != null) {
      map['comments'] = Variable<int>(comments);
    }
    if (!nullToAbsent || seriesTitle != null) {
      map['series_title'] = Variable<String>(seriesTitle);
    }
    if (!nullToAbsent || episode != null) {
      map['episode'] = Variable<int>(episode);
    }
    return map;
  }

  ScriptsCompanion toCompanion(bool nullToAbsent) {
    return ScriptsCompanion(
      id: Value(id),
      title: Value(title),
      category: Value(category),
      style: Value(style),
      duration: Value(duration),
      content: Value(content),
      model: Value(model),
      isFavorite: Value(isFavorite),
      publishedAt: publishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedAt),
      createdAt: Value(createdAt),
      views:
          views == null && nullToAbsent ? const Value.absent() : Value(views),
      likes:
          likes == null && nullToAbsent ? const Value.absent() : Value(likes),
      comments: comments == null && nullToAbsent
          ? const Value.absent()
          : Value(comments),
      seriesTitle: seriesTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesTitle),
      episode: episode == null && nullToAbsent
          ? const Value.absent()
          : Value(episode),
    );
  }

  factory Script.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Script(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      style: serializer.fromJson<String>(json['style']),
      duration: serializer.fromJson<int>(json['duration']),
      content: serializer.fromJson<String>(json['content']),
      model: serializer.fromJson<String>(json['model']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      publishedAt: serializer.fromJson<int?>(json['publishedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      views: serializer.fromJson<int?>(json['views']),
      likes: serializer.fromJson<int?>(json['likes']),
      comments: serializer.fromJson<int?>(json['comments']),
      seriesTitle: serializer.fromJson<String?>(json['seriesTitle']),
      episode: serializer.fromJson<int?>(json['episode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'style': serializer.toJson<String>(style),
      'duration': serializer.toJson<int>(duration),
      'content': serializer.toJson<String>(content),
      'model': serializer.toJson<String>(model),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'publishedAt': serializer.toJson<int?>(publishedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'views': serializer.toJson<int?>(views),
      'likes': serializer.toJson<int?>(likes),
      'comments': serializer.toJson<int?>(comments),
      'seriesTitle': serializer.toJson<String?>(seriesTitle),
      'episode': serializer.toJson<int?>(episode),
    };
  }

  Script copyWith(
          {int? id,
          String? title,
          String? category,
          String? style,
          int? duration,
          String? content,
          String? model,
          bool? isFavorite,
          Value<int?> publishedAt = const Value.absent(),
          int? createdAt,
          Value<int?> views = const Value.absent(),
          Value<int?> likes = const Value.absent(),
          Value<int?> comments = const Value.absent(),
          Value<String?> seriesTitle = const Value.absent(),
          Value<int?> episode = const Value.absent()}) =>
      Script(
        id: id ?? this.id,
        title: title ?? this.title,
        category: category ?? this.category,
        style: style ?? this.style,
        duration: duration ?? this.duration,
        content: content ?? this.content,
        model: model ?? this.model,
        isFavorite: isFavorite ?? this.isFavorite,
        publishedAt: publishedAt.present ? publishedAt.value : this.publishedAt,
        createdAt: createdAt ?? this.createdAt,
        views: views.present ? views.value : this.views,
        likes: likes.present ? likes.value : this.likes,
        comments: comments.present ? comments.value : this.comments,
        seriesTitle: seriesTitle.present ? seriesTitle.value : this.seriesTitle,
        episode: episode.present ? episode.value : this.episode,
      );
  Script copyWithCompanion(ScriptsCompanion data) {
    return Script(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      style: data.style.present ? data.style.value : this.style,
      duration: data.duration.present ? data.duration.value : this.duration,
      content: data.content.present ? data.content.value : this.content,
      model: data.model.present ? data.model.value : this.model,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      publishedAt:
          data.publishedAt.present ? data.publishedAt.value : this.publishedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      views: data.views.present ? data.views.value : this.views,
      likes: data.likes.present ? data.likes.value : this.likes,
      comments: data.comments.present ? data.comments.value : this.comments,
      seriesTitle:
          data.seriesTitle.present ? data.seriesTitle.value : this.seriesTitle,
      episode: data.episode.present ? data.episode.value : this.episode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Script(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('style: $style, ')
          ..write('duration: $duration, ')
          ..write('content: $content, ')
          ..write('model: $model, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('views: $views, ')
          ..write('likes: $likes, ')
          ..write('comments: $comments, ')
          ..write('seriesTitle: $seriesTitle, ')
          ..write('episode: $episode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      category,
      style,
      duration,
      content,
      model,
      isFavorite,
      publishedAt,
      createdAt,
      views,
      likes,
      comments,
      seriesTitle,
      episode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Script &&
          other.id == this.id &&
          other.title == this.title &&
          other.category == this.category &&
          other.style == this.style &&
          other.duration == this.duration &&
          other.content == this.content &&
          other.model == this.model &&
          other.isFavorite == this.isFavorite &&
          other.publishedAt == this.publishedAt &&
          other.createdAt == this.createdAt &&
          other.views == this.views &&
          other.likes == this.likes &&
          other.comments == this.comments &&
          other.seriesTitle == this.seriesTitle &&
          other.episode == this.episode);
}

class ScriptsCompanion extends UpdateCompanion<Script> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> category;
  final Value<String> style;
  final Value<int> duration;
  final Value<String> content;
  final Value<String> model;
  final Value<bool> isFavorite;
  final Value<int?> publishedAt;
  final Value<int> createdAt;
  final Value<int?> views;
  final Value<int?> likes;
  final Value<int?> comments;
  final Value<String?> seriesTitle;
  final Value<int?> episode;
  const ScriptsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.style = const Value.absent(),
    this.duration = const Value.absent(),
    this.content = const Value.absent(),
    this.model = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.views = const Value.absent(),
    this.likes = const Value.absent(),
    this.comments = const Value.absent(),
    this.seriesTitle = const Value.absent(),
    this.episode = const Value.absent(),
  });
  ScriptsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String category,
    required String style,
    required int duration,
    required String content,
    this.model = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.publishedAt = const Value.absent(),
    required int createdAt,
    this.views = const Value.absent(),
    this.likes = const Value.absent(),
    this.comments = const Value.absent(),
    this.seriesTitle = const Value.absent(),
    this.episode = const Value.absent(),
  })  : title = Value(title),
        category = Value(category),
        style = Value(style),
        duration = Value(duration),
        content = Value(content),
        createdAt = Value(createdAt);
  static Insertable<Script> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? style,
    Expression<int>? duration,
    Expression<String>? content,
    Expression<String>? model,
    Expression<bool>? isFavorite,
    Expression<int>? publishedAt,
    Expression<int>? createdAt,
    Expression<int>? views,
    Expression<int>? likes,
    Expression<int>? comments,
    Expression<String>? seriesTitle,
    Expression<int>? episode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (style != null) 'style': style,
      if (duration != null) 'duration': duration,
      if (content != null) 'content': content,
      if (model != null) 'model': model,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (publishedAt != null) 'published_at': publishedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (views != null) 'views': views,
      if (likes != null) 'likes': likes,
      if (comments != null) 'comments': comments,
      if (seriesTitle != null) 'series_title': seriesTitle,
      if (episode != null) 'episode': episode,
    });
  }

  ScriptsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? category,
      Value<String>? style,
      Value<int>? duration,
      Value<String>? content,
      Value<String>? model,
      Value<bool>? isFavorite,
      Value<int?>? publishedAt,
      Value<int>? createdAt,
      Value<int?>? views,
      Value<int?>? likes,
      Value<int?>? comments,
      Value<String?>? seriesTitle,
      Value<int?>? episode}) {
    return ScriptsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      style: style ?? this.style,
      duration: duration ?? this.duration,
      content: content ?? this.content,
      model: model ?? this.model,
      isFavorite: isFavorite ?? this.isFavorite,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      episode: episode ?? this.episode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<int>(publishedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (views.present) {
      map['views'] = Variable<int>(views.value);
    }
    if (likes.present) {
      map['likes'] = Variable<int>(likes.value);
    }
    if (comments.present) {
      map['comments'] = Variable<int>(comments.value);
    }
    if (seriesTitle.present) {
      map['series_title'] = Variable<String>(seriesTitle.value);
    }
    if (episode.present) {
      map['episode'] = Variable<int>(episode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScriptsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('style: $style, ')
          ..write('duration: $duration, ')
          ..write('content: $content, ')
          ..write('model: $model, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('views: $views, ')
          ..write('likes: $likes, ')
          ..write('comments: $comments, ')
          ..write('seriesTitle: $seriesTitle, ')
          ..write('episode: $episode')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _scriptIdMeta =
      const VerificationMeta('scriptId');
  @override
  late final GeneratedColumn<int> scriptId = GeneratedColumn<int>(
      'script_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1080));
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1920));
  static const VerificationMeta _fpsMeta = const VerificationMeta('fps');
  @override
  late final GeneratedColumn<int> fps = GeneratedColumn<int>(
      'fps', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(30));
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _exportedPathMeta =
      const VerificationMeta('exportedPath');
  @override
  late final GeneratedColumn<String> exportedPath = GeneratedColumn<String>(
      'exported_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        scriptId,
        title,
        width,
        height,
        fps,
        durationMs,
        exportedPath,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(Insertable<Project> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('script_id')) {
      context.handle(_scriptIdMeta,
          scriptId.isAcceptableOrUnknown(data['script_id']!, _scriptIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('fps')) {
      context.handle(
          _fpsMeta, fps.isAcceptableOrUnknown(data['fps']!, _fpsMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('exported_path')) {
      context.handle(
          _exportedPathMeta,
          exportedPath.isAcceptableOrUnknown(
              data['exported_path']!, _exportedPathMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      scriptId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}script_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width'])!,
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height'])!,
      fps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fps'])!,
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      exportedPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exported_path']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final int id;
  final int? scriptId;
  final String title;
  final int width;
  final int height;
  final int fps;
  final int durationMs;
  final String? exportedPath;
  final int updatedAt;
  const Project(
      {required this.id,
      this.scriptId,
      required this.title,
      required this.width,
      required this.height,
      required this.fps,
      required this.durationMs,
      this.exportedPath,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || scriptId != null) {
      map['script_id'] = Variable<int>(scriptId);
    }
    map['title'] = Variable<String>(title);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['fps'] = Variable<int>(fps);
    map['duration_ms'] = Variable<int>(durationMs);
    if (!nullToAbsent || exportedPath != null) {
      map['exported_path'] = Variable<String>(exportedPath);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      scriptId: scriptId == null && nullToAbsent
          ? const Value.absent()
          : Value(scriptId),
      title: Value(title),
      width: Value(width),
      height: Value(height),
      fps: Value(fps),
      durationMs: Value(durationMs),
      exportedPath: exportedPath == null && nullToAbsent
          ? const Value.absent()
          : Value(exportedPath),
      updatedAt: Value(updatedAt),
    );
  }

  factory Project.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<int>(json['id']),
      scriptId: serializer.fromJson<int?>(json['scriptId']),
      title: serializer.fromJson<String>(json['title']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      fps: serializer.fromJson<int>(json['fps']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      exportedPath: serializer.fromJson<String?>(json['exportedPath']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scriptId': serializer.toJson<int?>(scriptId),
      'title': serializer.toJson<String>(title),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'fps': serializer.toJson<int>(fps),
      'durationMs': serializer.toJson<int>(durationMs),
      'exportedPath': serializer.toJson<String?>(exportedPath),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Project copyWith(
          {int? id,
          Value<int?> scriptId = const Value.absent(),
          String? title,
          int? width,
          int? height,
          int? fps,
          int? durationMs,
          Value<String?> exportedPath = const Value.absent(),
          int? updatedAt}) =>
      Project(
        id: id ?? this.id,
        scriptId: scriptId.present ? scriptId.value : this.scriptId,
        title: title ?? this.title,
        width: width ?? this.width,
        height: height ?? this.height,
        fps: fps ?? this.fps,
        durationMs: durationMs ?? this.durationMs,
        exportedPath:
            exportedPath.present ? exportedPath.value : this.exportedPath,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      scriptId: data.scriptId.present ? data.scriptId.value : this.scriptId,
      title: data.title.present ? data.title.value : this.title,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      fps: data.fps.present ? data.fps.value : this.fps,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      exportedPath: data.exportedPath.present
          ? data.exportedPath.value
          : this.exportedPath,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('scriptId: $scriptId, ')
          ..write('title: $title, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('fps: $fps, ')
          ..write('durationMs: $durationMs, ')
          ..write('exportedPath: $exportedPath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, scriptId, title, width, height, fps,
      durationMs, exportedPath, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.scriptId == this.scriptId &&
          other.title == this.title &&
          other.width == this.width &&
          other.height == this.height &&
          other.fps == this.fps &&
          other.durationMs == this.durationMs &&
          other.exportedPath == this.exportedPath &&
          other.updatedAt == this.updatedAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<int> id;
  final Value<int?> scriptId;
  final Value<String> title;
  final Value<int> width;
  final Value<int> height;
  final Value<int> fps;
  final Value<int> durationMs;
  final Value<String?> exportedPath;
  final Value<int> updatedAt;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.scriptId = const Value.absent(),
    this.title = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.fps = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.exportedPath = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    this.scriptId = const Value.absent(),
    required String title,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.fps = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.exportedPath = const Value.absent(),
    required int updatedAt,
  })  : title = Value(title),
        updatedAt = Value(updatedAt);
  static Insertable<Project> custom({
    Expression<int>? id,
    Expression<int>? scriptId,
    Expression<String>? title,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? fps,
    Expression<int>? durationMs,
    Expression<String>? exportedPath,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scriptId != null) 'script_id': scriptId,
      if (title != null) 'title': title,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (fps != null) 'fps': fps,
      if (durationMs != null) 'duration_ms': durationMs,
      if (exportedPath != null) 'exported_path': exportedPath,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProjectsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? scriptId,
      Value<String>? title,
      Value<int>? width,
      Value<int>? height,
      Value<int>? fps,
      Value<int>? durationMs,
      Value<String?>? exportedPath,
      Value<int>? updatedAt}) {
    return ProjectsCompanion(
      id: id ?? this.id,
      scriptId: scriptId ?? this.scriptId,
      title: title ?? this.title,
      width: width ?? this.width,
      height: height ?? this.height,
      fps: fps ?? this.fps,
      durationMs: durationMs ?? this.durationMs,
      exportedPath: exportedPath ?? this.exportedPath,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scriptId.present) {
      map['script_id'] = Variable<int>(scriptId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (fps.present) {
      map['fps'] = Variable<int>(fps.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (exportedPath.present) {
      map['exported_path'] = Variable<String>(exportedPath.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('scriptId: $scriptId, ')
          ..write('title: $title, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('fps: $fps, ')
          ..write('durationMs: $durationMs, ')
          ..write('exportedPath: $exportedPath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ClipsTable extends Clips with TableInfo<$ClipsTable, Clip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES projects (id) ON DELETE CASCADE'));
  static const VerificationMeta _trackMeta = const VerificationMeta('track');
  @override
  late final GeneratedColumn<String> track = GeneratedColumn<String>(
      'track', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourcePathMeta =
      const VerificationMeta('sourcePath');
  @override
  late final GeneratedColumn<String> sourcePath = GeneratedColumn<String>(
      'source_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startMsMeta =
      const VerificationMeta('startMs');
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
      'start_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _inMsMeta = const VerificationMeta('inMs');
  @override
  late final GeneratedColumn<int> inMs = GeneratedColumn<int>(
      'in_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _outMsMeta = const VerificationMeta('outMs');
  @override
  late final GeneratedColumn<int> outMs = GeneratedColumn<int>(
      'out_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
      'speed', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _zOrderMeta = const VerificationMeta('zOrder');
  @override
  late final GeneratedColumn<int> zOrder = GeneratedColumn<int>(
      'z_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _propsMeta = const VerificationMeta('props');
  @override
  late final GeneratedColumn<String> props = GeneratedColumn<String>(
      'props', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        track,
        sourcePath,
        startMs,
        inMs,
        outMs,
        speed,
        zOrder,
        props
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clips';
  @override
  VerificationContext validateIntegrity(Insertable<Clip> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('track')) {
      context.handle(
          _trackMeta, track.isAcceptableOrUnknown(data['track']!, _trackMeta));
    } else if (isInserting) {
      context.missing(_trackMeta);
    }
    if (data.containsKey('source_path')) {
      context.handle(
          _sourcePathMeta,
          sourcePath.isAcceptableOrUnknown(
              data['source_path']!, _sourcePathMeta));
    }
    if (data.containsKey('start_ms')) {
      context.handle(_startMsMeta,
          startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta));
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('in_ms')) {
      context.handle(
          _inMsMeta, inMs.isAcceptableOrUnknown(data['in_ms']!, _inMsMeta));
    }
    if (data.containsKey('out_ms')) {
      context.handle(
          _outMsMeta, outMs.isAcceptableOrUnknown(data['out_ms']!, _outMsMeta));
    }
    if (data.containsKey('speed')) {
      context.handle(
          _speedMeta, speed.isAcceptableOrUnknown(data['speed']!, _speedMeta));
    }
    if (data.containsKey('z_order')) {
      context.handle(_zOrderMeta,
          zOrder.isAcceptableOrUnknown(data['z_order']!, _zOrderMeta));
    }
    if (data.containsKey('props')) {
      context.handle(
          _propsMeta, props.isAcceptableOrUnknown(data['props']!, _propsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Clip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Clip(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      track: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}track'])!,
      sourcePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_path']),
      startMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_ms'])!,
      inMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}in_ms'])!,
      outMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}out_ms'])!,
      speed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}speed'])!,
      zOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}z_order'])!,
      props: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}props'])!,
    );
  }

  @override
  $ClipsTable createAlias(String alias) {
    return $ClipsTable(attachedDatabase, alias);
  }
}

class Clip extends DataClass implements Insertable<Clip> {
  final int id;
  final int projectId;
  final String track;
  final String? sourcePath;
  final int startMs;
  final int inMs;
  final int outMs;
  final double speed;
  final int zOrder;
  final String props;
  const Clip(
      {required this.id,
      required this.projectId,
      required this.track,
      this.sourcePath,
      required this.startMs,
      required this.inMs,
      required this.outMs,
      required this.speed,
      required this.zOrder,
      required this.props});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['track'] = Variable<String>(track);
    if (!nullToAbsent || sourcePath != null) {
      map['source_path'] = Variable<String>(sourcePath);
    }
    map['start_ms'] = Variable<int>(startMs);
    map['in_ms'] = Variable<int>(inMs);
    map['out_ms'] = Variable<int>(outMs);
    map['speed'] = Variable<double>(speed);
    map['z_order'] = Variable<int>(zOrder);
    map['props'] = Variable<String>(props);
    return map;
  }

  ClipsCompanion toCompanion(bool nullToAbsent) {
    return ClipsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      track: Value(track),
      sourcePath: sourcePath == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePath),
      startMs: Value(startMs),
      inMs: Value(inMs),
      outMs: Value(outMs),
      speed: Value(speed),
      zOrder: Value(zOrder),
      props: Value(props),
    );
  }

  factory Clip.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Clip(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      track: serializer.fromJson<String>(json['track']),
      sourcePath: serializer.fromJson<String?>(json['sourcePath']),
      startMs: serializer.fromJson<int>(json['startMs']),
      inMs: serializer.fromJson<int>(json['inMs']),
      outMs: serializer.fromJson<int>(json['outMs']),
      speed: serializer.fromJson<double>(json['speed']),
      zOrder: serializer.fromJson<int>(json['zOrder']),
      props: serializer.fromJson<String>(json['props']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'track': serializer.toJson<String>(track),
      'sourcePath': serializer.toJson<String?>(sourcePath),
      'startMs': serializer.toJson<int>(startMs),
      'inMs': serializer.toJson<int>(inMs),
      'outMs': serializer.toJson<int>(outMs),
      'speed': serializer.toJson<double>(speed),
      'zOrder': serializer.toJson<int>(zOrder),
      'props': serializer.toJson<String>(props),
    };
  }

  Clip copyWith(
          {int? id,
          int? projectId,
          String? track,
          Value<String?> sourcePath = const Value.absent(),
          int? startMs,
          int? inMs,
          int? outMs,
          double? speed,
          int? zOrder,
          String? props}) =>
      Clip(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        track: track ?? this.track,
        sourcePath: sourcePath.present ? sourcePath.value : this.sourcePath,
        startMs: startMs ?? this.startMs,
        inMs: inMs ?? this.inMs,
        outMs: outMs ?? this.outMs,
        speed: speed ?? this.speed,
        zOrder: zOrder ?? this.zOrder,
        props: props ?? this.props,
      );
  Clip copyWithCompanion(ClipsCompanion data) {
    return Clip(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      track: data.track.present ? data.track.value : this.track,
      sourcePath:
          data.sourcePath.present ? data.sourcePath.value : this.sourcePath,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      inMs: data.inMs.present ? data.inMs.value : this.inMs,
      outMs: data.outMs.present ? data.outMs.value : this.outMs,
      speed: data.speed.present ? data.speed.value : this.speed,
      zOrder: data.zOrder.present ? data.zOrder.value : this.zOrder,
      props: data.props.present ? data.props.value : this.props,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Clip(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('track: $track, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('startMs: $startMs, ')
          ..write('inMs: $inMs, ')
          ..write('outMs: $outMs, ')
          ..write('speed: $speed, ')
          ..write('zOrder: $zOrder, ')
          ..write('props: $props')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, track, sourcePath, startMs,
      inMs, outMs, speed, zOrder, props);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Clip &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.track == this.track &&
          other.sourcePath == this.sourcePath &&
          other.startMs == this.startMs &&
          other.inMs == this.inMs &&
          other.outMs == this.outMs &&
          other.speed == this.speed &&
          other.zOrder == this.zOrder &&
          other.props == this.props);
}

class ClipsCompanion extends UpdateCompanion<Clip> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<String> track;
  final Value<String?> sourcePath;
  final Value<int> startMs;
  final Value<int> inMs;
  final Value<int> outMs;
  final Value<double> speed;
  final Value<int> zOrder;
  final Value<String> props;
  const ClipsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.track = const Value.absent(),
    this.sourcePath = const Value.absent(),
    this.startMs = const Value.absent(),
    this.inMs = const Value.absent(),
    this.outMs = const Value.absent(),
    this.speed = const Value.absent(),
    this.zOrder = const Value.absent(),
    this.props = const Value.absent(),
  });
  ClipsCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required String track,
    this.sourcePath = const Value.absent(),
    required int startMs,
    this.inMs = const Value.absent(),
    this.outMs = const Value.absent(),
    this.speed = const Value.absent(),
    this.zOrder = const Value.absent(),
    this.props = const Value.absent(),
  })  : projectId = Value(projectId),
        track = Value(track),
        startMs = Value(startMs);
  static Insertable<Clip> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? track,
    Expression<String>? sourcePath,
    Expression<int>? startMs,
    Expression<int>? inMs,
    Expression<int>? outMs,
    Expression<double>? speed,
    Expression<int>? zOrder,
    Expression<String>? props,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (track != null) 'track': track,
      if (sourcePath != null) 'source_path': sourcePath,
      if (startMs != null) 'start_ms': startMs,
      if (inMs != null) 'in_ms': inMs,
      if (outMs != null) 'out_ms': outMs,
      if (speed != null) 'speed': speed,
      if (zOrder != null) 'z_order': zOrder,
      if (props != null) 'props': props,
    });
  }

  ClipsCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<String>? track,
      Value<String?>? sourcePath,
      Value<int>? startMs,
      Value<int>? inMs,
      Value<int>? outMs,
      Value<double>? speed,
      Value<int>? zOrder,
      Value<String>? props}) {
    return ClipsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      track: track ?? this.track,
      sourcePath: sourcePath ?? this.sourcePath,
      startMs: startMs ?? this.startMs,
      inMs: inMs ?? this.inMs,
      outMs: outMs ?? this.outMs,
      speed: speed ?? this.speed,
      zOrder: zOrder ?? this.zOrder,
      props: props ?? this.props,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (track.present) {
      map['track'] = Variable<String>(track.value);
    }
    if (sourcePath.present) {
      map['source_path'] = Variable<String>(sourcePath.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (inMs.present) {
      map['in_ms'] = Variable<int>(inMs.value);
    }
    if (outMs.present) {
      map['out_ms'] = Variable<int>(outMs.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (zOrder.present) {
      map['z_order'] = Variable<int>(zOrder.value);
    }
    if (props.present) {
      map['props'] = Variable<String>(props.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClipsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('track: $track, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('startMs: $startMs, ')
          ..write('inMs: $inMs, ')
          ..write('outMs: $outMs, ')
          ..write('speed: $speed, ')
          ..write('zOrder: $zOrder, ')
          ..write('props: $props')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScriptsTable scripts = $ScriptsTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $ClipsTable clips = $ClipsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [scripts, projects, clips];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('projects',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('clips', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$ScriptsTableCreateCompanionBuilder = ScriptsCompanion Function({
  Value<int> id,
  required String title,
  required String category,
  required String style,
  required int duration,
  required String content,
  Value<String> model,
  Value<bool> isFavorite,
  Value<int?> publishedAt,
  required int createdAt,
  Value<int?> views,
  Value<int?> likes,
  Value<int?> comments,
  Value<String?> seriesTitle,
  Value<int?> episode,
});
typedef $$ScriptsTableUpdateCompanionBuilder = ScriptsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> category,
  Value<String> style,
  Value<int> duration,
  Value<String> content,
  Value<String> model,
  Value<bool> isFavorite,
  Value<int?> publishedAt,
  Value<int> createdAt,
  Value<int?> views,
  Value<int?> likes,
  Value<int?> comments,
  Value<String?> seriesTitle,
  Value<int?> episode,
});

class $$ScriptsTableFilterComposer
    extends Composer<_$AppDatabase, $ScriptsTable> {
  $$ScriptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get style => $composableBuilder(
      column: $table.style, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get publishedAt => $composableBuilder(
      column: $table.publishedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get views => $composableBuilder(
      column: $table.views, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get likes => $composableBuilder(
      column: $table.likes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get comments => $composableBuilder(
      column: $table.comments, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seriesTitle => $composableBuilder(
      column: $table.seriesTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get episode => $composableBuilder(
      column: $table.episode, builder: (column) => ColumnFilters(column));
}

class $$ScriptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScriptsTable> {
  $$ScriptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get style => $composableBuilder(
      column: $table.style, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get publishedAt => $composableBuilder(
      column: $table.publishedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get views => $composableBuilder(
      column: $table.views, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get likes => $composableBuilder(
      column: $table.likes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get comments => $composableBuilder(
      column: $table.comments, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seriesTitle => $composableBuilder(
      column: $table.seriesTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get episode => $composableBuilder(
      column: $table.episode, builder: (column) => ColumnOrderings(column));
}

class $$ScriptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScriptsTable> {
  $$ScriptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<int> get publishedAt => $composableBuilder(
      column: $table.publishedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get views =>
      $composableBuilder(column: $table.views, builder: (column) => column);

  GeneratedColumn<int> get likes =>
      $composableBuilder(column: $table.likes, builder: (column) => column);

  GeneratedColumn<int> get comments =>
      $composableBuilder(column: $table.comments, builder: (column) => column);

  GeneratedColumn<String> get seriesTitle => $composableBuilder(
      column: $table.seriesTitle, builder: (column) => column);

  GeneratedColumn<int> get episode =>
      $composableBuilder(column: $table.episode, builder: (column) => column);
}

class $$ScriptsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ScriptsTable,
    Script,
    $$ScriptsTableFilterComposer,
    $$ScriptsTableOrderingComposer,
    $$ScriptsTableAnnotationComposer,
    $$ScriptsTableCreateCompanionBuilder,
    $$ScriptsTableUpdateCompanionBuilder,
    (Script, BaseReferences<_$AppDatabase, $ScriptsTable, Script>),
    Script,
    PrefetchHooks Function()> {
  $$ScriptsTableTableManager(_$AppDatabase db, $ScriptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScriptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScriptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScriptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> style = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> model = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int?> publishedAt = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> views = const Value.absent(),
            Value<int?> likes = const Value.absent(),
            Value<int?> comments = const Value.absent(),
            Value<String?> seriesTitle = const Value.absent(),
            Value<int?> episode = const Value.absent(),
          }) =>
              ScriptsCompanion(
            id: id,
            title: title,
            category: category,
            style: style,
            duration: duration,
            content: content,
            model: model,
            isFavorite: isFavorite,
            publishedAt: publishedAt,
            createdAt: createdAt,
            views: views,
            likes: likes,
            comments: comments,
            seriesTitle: seriesTitle,
            episode: episode,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            required String category,
            required String style,
            required int duration,
            required String content,
            Value<String> model = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int?> publishedAt = const Value.absent(),
            required int createdAt,
            Value<int?> views = const Value.absent(),
            Value<int?> likes = const Value.absent(),
            Value<int?> comments = const Value.absent(),
            Value<String?> seriesTitle = const Value.absent(),
            Value<int?> episode = const Value.absent(),
          }) =>
              ScriptsCompanion.insert(
            id: id,
            title: title,
            category: category,
            style: style,
            duration: duration,
            content: content,
            model: model,
            isFavorite: isFavorite,
            publishedAt: publishedAt,
            createdAt: createdAt,
            views: views,
            likes: likes,
            comments: comments,
            seriesTitle: seriesTitle,
            episode: episode,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ScriptsTable, Script>(table),
                    BaseReferences<_$AppDatabase, $ScriptsTable, Script>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ScriptsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ScriptsTable,
    Script,
    $$ScriptsTableFilterComposer,
    $$ScriptsTableOrderingComposer,
    $$ScriptsTableAnnotationComposer,
    $$ScriptsTableCreateCompanionBuilder,
    $$ScriptsTableUpdateCompanionBuilder,
    (Script, BaseReferences<_$AppDatabase, $ScriptsTable, Script>),
    Script,
    PrefetchHooks Function()>;
typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  Value<int?> scriptId,
  required String title,
  Value<int> width,
  Value<int> height,
  Value<int> fps,
  Value<int> durationMs,
  Value<String?> exportedPath,
  required int updatedAt,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  Value<int?> scriptId,
  Value<String> title,
  Value<int> width,
  Value<int> height,
  Value<int> fps,
  Value<int> durationMs,
  Value<String?> exportedPath,
  Value<int> updatedAt,
});

final class $$ProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ClipsTable, List<Clip>> _clipsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.clips,
          aliasName: 'projects__id__clips__project_id');

  $$ClipsTableProcessedTableManager get clipsRefs {
    final manager = $$ClipsTableTableManager($_db, $_db.clips)
        .filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_clipsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scriptId => $composableBuilder(
      column: $table.scriptId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fps => $composableBuilder(
      column: $table.fps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exportedPath => $composableBuilder(
      column: $table.exportedPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> clipsRefs(
      Expression<bool> Function($$ClipsTableFilterComposer f) f) {
    final $$ClipsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.clips,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClipsTableFilterComposer(
              $db: $db,
              $table: $db.clips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scriptId => $composableBuilder(
      column: $table.scriptId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fps => $composableBuilder(
      column: $table.fps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exportedPath => $composableBuilder(
      column: $table.exportedPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get scriptId =>
      $composableBuilder(column: $table.scriptId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get fps =>
      $composableBuilder(column: $table.fps, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<String> get exportedPath => $composableBuilder(
      column: $table.exportedPath, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> clipsRefs<T extends Object>(
      Expression<T> Function($$ClipsTableAnnotationComposer a) f) {
    final $$ClipsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.clips,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClipsTableAnnotationComposer(
              $db: $db,
              $table: $db.clips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, $$ProjectsTableReferences),
    Project,
    PrefetchHooks Function({bool clipsRefs})> {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> scriptId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> width = const Value.absent(),
            Value<int> height = const Value.absent(),
            Value<int> fps = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<String?> exportedPath = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              ProjectsCompanion(
            id: id,
            scriptId: scriptId,
            title: title,
            width: width,
            height: height,
            fps: fps,
            durationMs: durationMs,
            exportedPath: exportedPath,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> scriptId = const Value.absent(),
            required String title,
            Value<int> width = const Value.absent(),
            Value<int> height = const Value.absent(),
            Value<int> fps = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<String?> exportedPath = const Value.absent(),
            required int updatedAt,
          }) =>
              ProjectsCompanion.insert(
            id: id,
            scriptId: scriptId,
            title: title,
            width: width,
            height: height,
            fps: fps,
            durationMs: durationMs,
            exportedPath: exportedPath,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ProjectsTable, Project>(table),
                    $$ProjectsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({clipsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (clipsRefs) db.clips],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (clipsRefs)
                    await $_getPrefetchedData<Project, $ProjectsTable, Clip>(
                        currentTable: table,
                        referencedTable:
                            $$ProjectsTableReferences._clipsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableReferences(db, table, p0).clipsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, $$ProjectsTableReferences),
    Project,
    PrefetchHooks Function({bool clipsRefs})>;
typedef $$ClipsTableCreateCompanionBuilder = ClipsCompanion Function({
  Value<int> id,
  required int projectId,
  required String track,
  Value<String?> sourcePath,
  required int startMs,
  Value<int> inMs,
  Value<int> outMs,
  Value<double> speed,
  Value<int> zOrder,
  Value<String> props,
});
typedef $$ClipsTableUpdateCompanionBuilder = ClipsCompanion Function({
  Value<int> id,
  Value<int> projectId,
  Value<String> track,
  Value<String?> sourcePath,
  Value<int> startMs,
  Value<int> inMs,
  Value<int> outMs,
  Value<double> speed,
  Value<int> zOrder,
  Value<String> props,
});

final class $$ClipsTableReferences
    extends BaseReferences<_$AppDatabase, $ClipsTable, Clip> {
  $$ClipsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('clips__project_id__projects__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<int>('project_id')!;

    final manager = $$ProjectsTableTableManager($_db, $_db.projects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ClipsTableFilterComposer extends Composer<_$AppDatabase, $ClipsTable> {
  $$ClipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get track => $composableBuilder(
      column: $table.track, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourcePath => $composableBuilder(
      column: $table.sourcePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startMs => $composableBuilder(
      column: $table.startMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get inMs => $composableBuilder(
      column: $table.inMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get outMs => $composableBuilder(
      column: $table.outMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get speed => $composableBuilder(
      column: $table.speed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get zOrder => $composableBuilder(
      column: $table.zOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get props => $composableBuilder(
      column: $table.props, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableFilterComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ClipsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClipsTable> {
  $$ClipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get track => $composableBuilder(
      column: $table.track, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourcePath => $composableBuilder(
      column: $table.sourcePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startMs => $composableBuilder(
      column: $table.startMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get inMs => $composableBuilder(
      column: $table.inMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get outMs => $composableBuilder(
      column: $table.outMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get speed => $composableBuilder(
      column: $table.speed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get zOrder => $composableBuilder(
      column: $table.zOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get props => $composableBuilder(
      column: $table.props, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ClipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClipsTable> {
  $$ClipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get track =>
      $composableBuilder(column: $table.track, builder: (column) => column);

  GeneratedColumn<String> get sourcePath => $composableBuilder(
      column: $table.sourcePath, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get inMs =>
      $composableBuilder(column: $table.inMs, builder: (column) => column);

  GeneratedColumn<int> get outMs =>
      $composableBuilder(column: $table.outMs, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<int> get zOrder =>
      $composableBuilder(column: $table.zOrder, builder: (column) => column);

  GeneratedColumn<String> get props =>
      $composableBuilder(column: $table.props, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ClipsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ClipsTable,
    Clip,
    $$ClipsTableFilterComposer,
    $$ClipsTableOrderingComposer,
    $$ClipsTableAnnotationComposer,
    $$ClipsTableCreateCompanionBuilder,
    $$ClipsTableUpdateCompanionBuilder,
    (Clip, $$ClipsTableReferences),
    Clip,
    PrefetchHooks Function({bool projectId})> {
  $$ClipsTableTableManager(_$AppDatabase db, $ClipsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<String> track = const Value.absent(),
            Value<String?> sourcePath = const Value.absent(),
            Value<int> startMs = const Value.absent(),
            Value<int> inMs = const Value.absent(),
            Value<int> outMs = const Value.absent(),
            Value<double> speed = const Value.absent(),
            Value<int> zOrder = const Value.absent(),
            Value<String> props = const Value.absent(),
          }) =>
              ClipsCompanion(
            id: id,
            projectId: projectId,
            track: track,
            sourcePath: sourcePath,
            startMs: startMs,
            inMs: inMs,
            outMs: outMs,
            speed: speed,
            zOrder: zOrder,
            props: props,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            required String track,
            Value<String?> sourcePath = const Value.absent(),
            required int startMs,
            Value<int> inMs = const Value.absent(),
            Value<int> outMs = const Value.absent(),
            Value<double> speed = const Value.absent(),
            Value<int> zOrder = const Value.absent(),
            Value<String> props = const Value.absent(),
          }) =>
              ClipsCompanion.insert(
            id: id,
            projectId: projectId,
            track: track,
            sourcePath: sourcePath,
            startMs: startMs,
            inMs: inMs,
            outMs: outMs,
            speed: speed,
            zOrder: zOrder,
            props: props,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ClipsTable, Clip>(table),
                    $$ClipsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable: $$ClipsTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$ClipsTableReferences._projectIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ClipsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ClipsTable,
    Clip,
    $$ClipsTableFilterComposer,
    $$ClipsTableOrderingComposer,
    $$ClipsTableAnnotationComposer,
    $$ClipsTableCreateCompanionBuilder,
    $$ClipsTableUpdateCompanionBuilder,
    (Clip, $$ClipsTableReferences),
    Clip,
    PrefetchHooks Function({bool projectId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ScriptsTableTableManager get scripts =>
      $$ScriptsTableTableManager(_db, _db.scripts);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$ClipsTableTableManager get clips =>
      $$ClipsTableTableManager(_db, _db.clips);
}
