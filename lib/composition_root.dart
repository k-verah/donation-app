import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/single_child_widget.dart';

//DATA
// Data sources
import 'data/datasources/auth/firebase_auth_datasource.dart';
import 'data/datasources/users/user_profile_datasource.dart';
import 'data/datasources/sensors/location_datasource.dart';
import 'data/datasources/sensors/camera_datasource.dart';
import 'data/datasources/donations/donations_datasource.dart';
import 'data/datasources/foundations/foundation_point_datasource.dart';

// Repositories
import 'data/repositories/auth/auth_repository_impl.dart';
import 'data/repositories/sensors/location_repository_impl.dart';
import 'data/repositories/sensors/camera_repository_impl.dart';
import 'package:donation_app/data/repositories/donations/donations_respository_impl.dart';
import 'data/repositories/foundations/foundation_point_repository_impl.dart';

// DOMAIN
// Repositories
import 'domain/repositories/auth/auth_repository.dart';
import 'domain/repositories/sensors/location_repository.dart';
import 'domain/repositories/sensors/camera_repository.dart';
import 'domain/repositories/donations/donations_repository.dart';
import 'domain/repositories/foundations/foundation_point_repository.dart';

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

// PRESENTATION
// Providers
import 'presentation/providers/auth/auth_provider.dart';
import 'presentation/providers/sensors/location_provider.dart';
import 'presentation/providers/donations/donation_provider.dart';
import 'presentation/providers/sensors/camera_provider.dart';

class CompositionRoot {
  static List<SingleChildWidget> providers() {
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
    final startCamera = StartCamera(camRepo); // sin pasar enums en domain
    final takePhoto = TakePhoto(camRepo);
    final stopCamera = StopCamera(camRepo);
    final pickFromGallery = PickFromGallery(camRepo);

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
    ];
  }
}
