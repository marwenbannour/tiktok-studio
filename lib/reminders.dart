import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

/// تذكير بالـnotification وقت النشر متاع فيديو مبرمج
class Reminders {
  static final plugin = FlutterLocalNotificationsPlugin();
  static Future<void>? _init;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'plans',
      'البرنامج',
      channelDescription: 'تذكير وقت نشر الفيديوهات',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static Future<void> _ensureInit() => _init ??= () async {
        tzdata.initializeTimeZones();
        try {
          final info = await FlutterTimezone.getLocalTimezone();
          tz.setLocalLocation(tz.getLocation(info.identifier));
        } catch (e) {
          debugPrint('Reminders: timezone fallback UTC ($e)');
        }
        await plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          ),
        );
      }();

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// يبرمج (ولا يفسخ) التذكير حسب الـplan. يرجّع true كان تبرمج.
  static Future<bool> sync(PlannedVideo p, {bool askPermission = true}) async {
    await _ensureInit();
    await plugin.cancel(id: p.notificationId);
    if (!p.reminder || p.status == PlanStatus.posted || !p.date.isAfter(DateTime.now())) {
      return false;
    }
    if (askPermission && await _android?.areNotificationsEnabled() == false) {
      await _android?.requestNotificationsPermission();
    }
    await plugin.zonedSchedule(
      id: p.notificationId,
      scheduledDate: tz.TZDateTime.from(p.date, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: '🎬 وقت النشر!',
      body: p.title,
    );
    return true;
  }

  static Future<void> cancel(PlannedVideo p) async {
    await _ensureInit();
    await plugin.cancel(id: p.notificationId);
  }

  static Future<List<int>> pendingIds() async {
    await _ensureInit();
    return (await plugin.pendingNotificationRequests()).map((r) => r.id).toList();
  }
}
