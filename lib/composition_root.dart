import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

//DATA
// Data sources
import 'data/datasources/auth/firebase_auth_datasource.dart';
import 'data/datasources/users/user_profile_datasource.dart';
import 'data/datasources/sensors/location_datasource.dart';
import 'data/datasources/sensors/camera_datasource.dart';
import 'data/datasources/donations/donations_datasource.dart';
import 'data/datasources/foundations/foundation_point_datasource.dart';
import 'data/datasources/analytics/analytics_datasource.dart';
import 'data/datasources/local/local_storage_datasource.dart';

// Repositories
import 'data/repositories/auth/auth_repository_impl.dart';
import 'data/repositories/sensors/location_repository_impl.dart';
import 'data/repositories/sensors/camera_repository_impl.dart';
import 'package:donation_app/data/repositories/donations/donations_respository_impl.dart';
import 'data/repositories/foundations/foundation_point_repository_impl.dart';
import 'data/repositories/analytics/analytics_repository_impl.dart';
import 'data/repositories/local/local_storage_repository_impl.dart';

// DOMAIN
// Repositories
import 'domain/repositories/auth/auth_repository.dart';
import 'domain/repositories/sensors/location_repository.dart';
import 'domain/repositories/sensors/camera_repository.dart';
import 'domain/repositories/donations/donations_repository.dart';
import 'domain/repositories/foundations/foundation_point_repository.dart';
import 'domain/repositories/analytics/analytics_repository.dart';
import 'domain/repositories/local/local_storage_repository.dart';

// Use Cases
import 'domain/use_cases/get_auth_state.dart';
import 'domain/use_cases/sign_in.dart';
import 'domain/use_cases/sign_out.dart';
import 'domain/use_cases/sign_up.dart';
import 'domain/use_cases/get_current_location.dart';
import 'domain/use_cases/get_foundations_points.dart';
import 'domain/use_cases/sort_points.dart';
import 'domain/use_cases/recommend_foundation.dart';
import 'domain/use_cases/create_donation.dart';
import 'domain/use_cases/stream_user_donations.dart';
import 'domain/use_cases/start_camera.dart';
import 'domain/use_cases/take_photo.dart';
import 'domain/use_cases/stop_camera.dart';
import 'domain/use_cases/pick_from_gallery.dart';
import 'domain/use_cases/track_filter_usage.dart';
import 'domain/use_cases/track_point_usage.dart';
import 'domain/use_cases/get_filter_combination_stats.dart';
import 'domain/use_cases/get_point_usage_stats.dart';
import 'domain/use_cases/save_filter_preferences.dart';
import 'domain/use_cases/load_filter_preferences.dart';
import 'domain/use_cases/save_last_location.dart';
import 'domain/use_cases/load_last_location.dart';
import 'domain/use_cases/cache_donation_points.dart';
import 'domain/use_cases/load_cached_points.dart';

// PRESENTATION
// Providers
import 'presentation/providers/auth/auth_provider.dart';
import 'presentation/providers/sensors/location_provider.dart';
import 'presentation/providers/donations/donation_provider.dart';
import 'presentation/providers/sensors/camera_provider.dart';
import 'presentation/providers/analytics/analytics_provider.dart';

class CompositionRoot {
  static Future<List<SingleChildWidget>> providers() async {
    final authDS = FirebaseAuthDatasource(fb.FirebaseAuth.instance);
    final profileDS = UserProfileDataSource(FirebaseFirestore.instance);
    final AuthRepository authRepo = AuthRepositoryImpl(authDS, profileDS);

    final signIn = SignIn(authRepo);
    final signUp = SignUp(authRepo);
    final signOut = SignOut(authRepo);
    final getAuthState = GetAuthState(authRepo);

    final locDS = LocationDataSource();
    final LocationRepository locRepo = LocationRepositoryImpl(locDS);
    final getCurrentLoc = GetCurrentLocation(locRepo);

    final foundationPointsDS = FoundationPointDatasource();
    final FoundationPointRepository foundationsRepo =
        FoundationPointRepositoryImpl(foundationPointsDS);
    final getFoundationPoints = GetFoundationsPoints(foundationsRepo);

    final sortPoints = SortPoints();
    final recommendUC = RecommendFoundation(sortPoints);

    final donationsDS = DonationsDataSource(FirebaseFirestore.instance);
    final DonationsRepository donationsRepo = DonationsRepositoryImpl(
      donationsDS,
    );
    final createDonation = CreateDonation(donationsRepo);
    final streamUserDonations = StreamUserDonations(donationsRepo);

    final camDS = CameraDatasource();
    final CameraRepository camRepo = CameraRepositoryImpl(camDS);
    final startCamera = StartCamera(camRepo);
    final takePhoto = TakePhoto(camRepo);
    final stopCamera = StopCamera(camRepo);
    final pickFromGallery = PickFromGallery(camRepo);

    // Analytics
    final analyticsDS = AnalyticsDataSource(FirebaseFirestore.instance);
    final AnalyticsRepository analyticsRepo = AnalyticsRepositoryImpl(analyticsDS);
    final trackFilterUsage = TrackFilterUsage(analyticsRepo);
    final trackPointUsage = TrackPointUsage(analyticsRepo);
    final getFilterCombinationStats = GetFilterCombinationStats(analyticsRepo);
    final getPointUsageStats = GetPointUsageStats(analyticsRepo);

    // ✅ Local Storage
    final prefs = await SharedPreferences.getInstance();
    final localStorageDS = LocalStorageDataSource(prefs);
    final LocalStorageRepository localStorageRepo = LocalStorageRepositoryImpl(localStorageDS);
    final saveFilterPreferences = SaveFilterPreferences(localStorageRepo);
    final loadFilterPreferences = LoadFilterPreferences(localStorageRepo);
    final saveLastLocation = SaveLastLocation(localStorageRepo);
    final loadLastLocation = LoadLastLocation(localStorageRepo);
    final cacheDonationPoints = CacheDonationPoints(localStorageRepo);
    final loadCachedPoints = LoadCachedPoints(localStorageRepo);

    return [
      ChangeNotifierProvider(
        create: (_) => AuthProvider(
          signIn,
          signUp,
          signOut,
          getAuthState,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => LocationProvider(
          getCurrentLocation: getCurrentLoc,
          getFoundationsPoints: getFoundationPoints,
          sortPoints: sortPoints,
          recommendUC: recommendUC,
          saveFilterPreferences: saveFilterPreferences,
          loadFilterPreferences: loadFilterPreferences,
          saveLastLocation: saveLastLocation,
          loadLastLocation: loadLastLocation,
          cacheDonationPoints: cacheDonationPoints,
          loadCachedPoints: loadCachedPoints,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => DonationProvider(
          createDonation: createDonation,
          streamUserDonations: streamUserDonations,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => CameraProvider(
          repo: camRepo,
          startCamera: startCamera,
          takePhoto: takePhoto,
          stopCamera: stopCamera,
          pickFromGallery: pickFromGallery,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => AnalyticsProvider(
          trackFilterUsage: trackFilterUsage,
          trackPointUsage: trackPointUsage,
          getFilterCombinationStats: getFilterCombinationStats,
          getPointUsageStats: getPointUsageStats,
        ),
      ),
    ];
  }
}
