enum FeedbackRating {
  excellent,
  good,
  average,
  poor;

  String get value => name;

  String get label => switch (this) {
    FeedbackRating.excellent => 'Excellent',
    FeedbackRating.good => 'Good',
    FeedbackRating.average => 'Average',
    FeedbackRating.poor => 'Poor',
  };
}

enum FeatureRequestCategory {
  uiUx,
  content,
  performance,
  accessibility,
  other;

  String get value => switch (this) {
    FeatureRequestCategory.uiUx => 'ui_ux',
    FeatureRequestCategory.content => 'content',
    FeatureRequestCategory.performance => 'performance',
    FeatureRequestCategory.accessibility => 'accessibility',
    FeatureRequestCategory.other => 'other',
  };

  String get label => switch (this) {
    FeatureRequestCategory.uiUx => 'UI/UX Improvement',
    FeatureRequestCategory.content => 'Content Feature',
    FeatureRequestCategory.performance => 'Performance or Speed',
    FeatureRequestCategory.accessibility => 'Accessibility',
    FeatureRequestCategory.other => 'Other',
  };
}

enum FeatureRequestTargetPlatform {
  website,
  mobile,
  both;

  String get value => name;

  String get label => switch (this) {
    FeatureRequestTargetPlatform.website => 'Website',
    FeatureRequestTargetPlatform.mobile => 'Mobile App',
    FeatureRequestTargetPlatform.both => 'Both',
  };
}

class FeedbackRequest {
  const FeedbackRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.rating,
    required this.message,
    required this.platform,
    required this.source,
    required this.appName,
  });

  final String name;
  final String email;
  final String phone;
  final FeedbackRating rating;
  final String message;
  final String platform;
  final String source;
  final String appName;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'rating': rating.value,
      'message': message,
      'platform': platform,
      'source': source,
      'appName': appName,
    };
  }
}

class FeatureRequestSubmission {
  const FeatureRequestSubmission({
    required this.name,
    required this.email,
    required this.phone,
    required this.title,
    required this.description,
    required this.category,
    required this.targetPlatform,
    required this.platform,
    required this.source,
    required this.appName,
  });

  final String name;
  final String email;
  final String phone;
  final String title;
  final String description;
  final FeatureRequestCategory category;
  final FeatureRequestTargetPlatform targetPlatform;
  final String platform;
  final String source;
  final String appName;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'featureTitle': title,
      'title': title,
      'featureDescription': description,
      'description': description,
      'category': category.value,
      'target_platform': targetPlatform.value,
      'platform': platform,
      'source': source,
      'appName': appName,
    };
  }
}

class CommonEmailApiException implements Exception {
  const CommonEmailApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
