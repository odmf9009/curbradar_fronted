import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/home/main_navigation_screen.dart';
import '../../presentation/screens/home/splash_screen.dart';
import '../../presentation/screens/home/object_detail_screen.dart';
import '../../presentation/screens/publish/publish_object_screen.dart';
import '../../presentation/screens/premium/premium_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/profile/my_posts_screen.dart';
import '../../presentation/screens/profile/admin_panel_screen.dart';
import '../../presentation/screens/home/filters_screen.dart';
import '../../presentation/screens/home/all_nearby_objects_screen.dart';
import '../../presentation/screens/ranking/ranking_screen.dart';
import '../../presentation/screens/saved/saved_objects_screen.dart';
import '../../presentation/screens/home/chat_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/profile/public_profile_screen.dart';
import '../../presentation/screens/settings/notification_settings_screen.dart';
import '../../presentation/screens/settings/search_radius_screen.dart';
import '../../presentation/screens/settings/privacy_settings_screen.dart';
import '../../presentation/screens/settings/language_settings_screen.dart';
import '../../presentation/screens/settings/about_screen.dart';
import '../../presentation/screens/settings/help_support_screen.dart';
import '../../presentation/screens/settings/privacy_policy_screen.dart';
import '../../presentation/screens/settings/terms_screen.dart';
import '../../presentation/screens/settings/third_party_licenses_screen.dart';
import '../../presentation/screens/profile/achievements_screen.dart';
import '../../presentation/screens/profile/activity_history_screen.dart';
import '../../presentation/screens/profile/referral_screen.dart';
import '../../presentation/screens/profile/rewards_screen.dart';
import '../../presentation/screens/stats/community_stats_screen.dart';
import '../models/filter_model.dart';
import '../models/curb_object.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String publish = '/publish';
  static const String premium = '/premium';
  static const String settings = '/settings';
  static const String achievements   = '/achievements';
  static const String activityHistory= '/activity-history';
  static const String referral       = '/referral';
  static const String rewards        = '/rewards';
  static const String communityStats = '/community-stats';
  static const String objectDetail = '/object-detail';
  static const String myPosts = '/my-posts';
  static const String adminPanel = '/admin-panel';
  static const String filters = '/filters';
  static const String ranking = '/ranking';
  static const String saved = '/saved';
  static const String allNearby = '/all-nearby';
  static const String chat = '/chat';
  static const String notificationSettings = '/notification-settings';
  static const String searchRadiusSettings = '/search-radius-settings';
  static const String privacySettings = '/privacy-settings';
  static const String languageSettings = '/language-settings';
  static const String publicProfile = '/public_profile';
  static const String about = '/about';
  static const String helpSupport = '/help-support';
  static const String privacyPolicy = '/privacy-policy';
  static const String terms = '/terms';
  static const String licenses = '/licenses';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    home: (context) => const MainNavigationScreen(),
    publish: (context) => const PublishObjectScreen(),
    premium: (context) => const PremiumScreen(),
    settings: (context) => const SettingsScreen(),
    notificationSettings: (context) => const NotificationSettingsScreen(),
    searchRadiusSettings: (context) => const SearchRadiusScreen(),
    privacySettings: (context) => const PrivacySettingsScreen(),
    languageSettings: (context) => const LanguageSettingsScreen(),
    objectDetail: (context) => const ObjectDetailScreen(),
    myPosts: (context) => const MyPostsScreen(),
    adminPanel: (context) => const AdminPanelScreen(),
    filters: (context) => FiltersScreen(initialFilters: FilterModel()),
    ranking: (context) => const RankingScreen(),
    saved: (context) => const SavedObjectsScreen(),
    allNearby: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return AllNearbyObjectsScreen(
        objects: args['objects'] as List<CurbObject>,
        currentPosition: args['position'] as Position?,
      );
    },
    chat: (context) => const ChatScreen(),
    publicProfile: (context) => const PublicProfileScreen(),
    about: (context) => const AboutScreen(),
    helpSupport: (context) => const HelpSupportScreen(),
    privacyPolicy: (context) => const PrivacyPolicyScreen(),
    terms: (context) => const TermsScreen(),
    licenses: (context) => const ThirdPartyLicensesScreen(),
    achievements:    (context) => const AchievementsScreen(),
    activityHistory: (context) => const ActivityHistoryScreen(),
    referral:        (context) => const ReferralScreen(),
    rewards:         (context) => const RewardsScreen(),
    communityStats:  (context) => const CommunityStatsScreen(),
  };
}
