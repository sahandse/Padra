import '../device/device_snapshot.dart';

class HealthScoreResult {
  const HealthScoreResult({
    required this.score,
    required this.maxScore,
    required this.items,
    required this.unknownCount,
    required this.recommendations,
  });

  final int score;
  final int maxScore;
  final List<HealthScoreItem> items;
  final int unknownCount;
  final List<String> recommendations;

  int get percent => maxScore == 0 ? 0 : ((score / maxScore) * 100).round();
}

class HealthScoreItem {
  const HealthScoreItem({
    required this.title,
    required this.score,
    required this.maxScore,
    required this.detail,
    required this.state,
  });

  final String title;
  final int score;
  final int maxScore;
  final String detail;
  final HealthScoreState state;
}

enum HealthScoreState { good, attention, unknown }

class HealthScoreService {
  const HealthScoreService();

  HealthScoreResult evaluate(DeviceSnapshot? snapshot) {
    if (snapshot == null) {
      return const HealthScoreResult(
        score: 0,
        maxScore: 0,
        unknownCount: 4,
        items: [
          HealthScoreItem(
            title: 'باتری',
            score: 0,
            maxScore: 20,
            detail: 'برای امتیازدهی ابتدا بررسی کامل دستگاه را اجرا کن.',
            state: HealthScoreState.unknown,
          ),
          HealthScoreItem(
            title: 'حافظه',
            score: 0,
            maxScore: 30,
            detail: 'داده فضای ذخیره‌سازی هنوز دریافت نشده است.',
            state: HealthScoreState.unknown,
          ),
          HealthScoreItem(
            title: 'امنیت اندروید',
            score: 0,
            maxScore: 30,
            detail: 'تاریخ وصله امنیتی هنوز بررسی نشده است.',
            state: HealthScoreState.unknown,
          ),
          HealthScoreItem(
            title: 'بررسی‌های تکمیلی',
            score: 0,
            maxScore: 20,
            detail: 'آنتی‌ویروس، Cleaner، Apps و Network را جداگانه بررسی کن.',
            state: HealthScoreState.unknown,
          ),
        ],
        recommendations: ['از صفحه اصلی «بررسی کامل» را اجرا کن.'],
      );
    }

    final items = <HealthScoreItem>[];
    final recommendations = <String>[];

    final batteryLow = snapshot.batteryLevel <= 20 &&
        snapshot.batteryState != 'در حال شارژ' &&
        snapshot.batteryState != 'شارژ کامل';
    items.add(
      HealthScoreItem(
        title: 'باتری',
        score: batteryLow ? 10 : 20,
        maxScore: 20,
        detail: batteryLow
            ? 'شارژ ${snapshot.batteryLevel}٪ است و دستگاه در حال شارژ نیست.'
            : 'شارژ ${snapshot.batteryLevel}٪ • ${snapshot.batteryState}',
        state: batteryLow ? HealthScoreState.attention : HealthScoreState.good,
      ),
    );
    if (batteryLow) {
      recommendations.add('Battery Saver را بررسی کن یا دستگاه را شارژ کن.');
    }

    final storage = snapshot.usedStoragePercent;
    if (storage == null) {
      items.add(const HealthScoreItem(
        title: 'حافظه',
        score: 0,
        maxScore: 30,
        detail: 'میزان فضای استفاده‌شده از اندروید دریافت نشد.',
        state: HealthScoreState.unknown,
      ));
    } else {
      final int storageScore;
      if (storage >= 95) {
        storageScore = 8;
      } else if (storage >= 90) {
        storageScore = 15;
      } else if (storage >= 80) {
        storageScore = 23;
      } else {
        storageScore = 30;
      }
      final attention = storage >= 90;
      items.add(
        HealthScoreItem(
          title: 'حافظه',
          score: storageScore,
          maxScore: 30,
          detail: '${storage.round()}٪ فضای ذخیره‌سازی استفاده شده است.',
          state: attention ? HealthScoreState.attention : HealthScoreState.good,
        ),
      );
      if (attention) {
        recommendations.add('Storage و Cleaner را باز کن و فایل‌های حجیم را بررسی کن.');
      }
    }

    final patchAge = _patchAgeInDays(snapshot.securityPatch);
    if (patchAge == null) {
      items.add(const HealthScoreItem(
        title: 'امنیت اندروید',
        score: 0,
        maxScore: 30,
        detail: 'تاریخ وصله امنیتی قابل تشخیص نبود.',
        state: HealthScoreState.unknown,
      ));
    } else {
      final int securityScore;
      if (patchAge > 365) {
        securityScore = 8;
      } else if (patchAge > 180) {
        securityScore = 18;
      } else if (patchAge > 90) {
        securityScore = 25;
      } else {
        securityScore = 30;
      }
      final attention = patchAge > 180;
      items.add(
        HealthScoreItem(
          title: 'امنیت اندروید',
          score: securityScore,
          maxScore: 30,
          detail: 'وصله امنیتی ${snapshot.securityPatch} • حدود $patchAge روز قبل',
          state: attention ? HealthScoreState.attention : HealthScoreState.good,
        ),
      );
      if (attention) {
        recommendations.add('بروزرسانی سیستم و وصله امنیتی Android را بررسی کن.');
      }
    }

    items.add(const HealthScoreItem(
      title: 'بررسی‌های تکمیلی',
      score: 0,
      maxScore: 20,
      detail: 'این ۲۰ امتیاز فقط بعد از اجرای Antivirus، Cleaner، Apps و Network قابل ارزیابی است.',
      state: HealthScoreState.unknown,
    ));
    recommendations.add('برای کامل‌شدن امتیاز، ابزارهای Antivirus، Cleaner، Apps و Network را هم اجرا کن.');

    final knownItems = items.where((item) => item.state != HealthScoreState.unknown);
    final score = knownItems.fold<int>(0, (sum, item) => sum + item.score);
    final maxScore = knownItems.fold<int>(0, (sum, item) => sum + item.maxScore);

    return HealthScoreResult(
      score: score,
      maxScore: maxScore,
      items: items,
      unknownCount: items.where((item) => item.state == HealthScoreState.unknown).length,
      recommendations: recommendations,
    );
  }

  int? _patchAgeInDays(String? patch) {
    if (patch == null || patch.isEmpty) return null;
    final date = DateTime.tryParse(patch);
    if (date == null) return null;
    return DateTime.now().difference(date).inDays;
  }
}
