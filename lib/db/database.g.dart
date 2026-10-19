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
        comments
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
      this.comments});
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
          Value<int?> comments = const Value.absent()}) =>
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
          ..write('comments: $comments')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, category, style, duration, content,
      model, isFavorite, publishedAt, createdAt, views, likes, comments);
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
          other.comments == this.comments);
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
      Value<int?>? comments}) {
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
          ..write('comments: $comments')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScriptsTable scripts = $ScriptsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [scripts];
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ScriptsTableTableManager get scripts =>
      $$ScriptsTableTableManager(_db, _db.scripts);
}
