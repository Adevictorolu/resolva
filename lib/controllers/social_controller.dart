import 'package:get/get.dart';
import '../data/models/social_service.dart';
import '../data/mock/mock_data.dart';
import '../services/bigisub_service.dart';
import '../services/pricing_service.dart';

/// Controller for the Social Media Boosting (Bigisub Marketing Hub) marketplace.
class SocialController extends GetxController {
  final platforms = mockPlatforms;
  final List<SocialService> _baseServices = <SocialService>[];
  final services = <SocialService>[].obs;
  final filteredServices = <SocialService>[].obs;

  final selectedPlatformId = ''.obs;
  final selectedCountry = 'all'.obs; // 'all', 'nigeria', 'global', 'ghana'
  final selectedCategory = 'All'.obs;
  final searchQuery = ''.obs;

  final selectedService = Rxn<SocialService>();
  final quantity = 0.obs;
  final profileUrl = ''.obs;
  final customText = ''.obs;
  final pollAnswerNumber = 1.obs;
  final hashtag = ''.obs;
  final oldPosts = 0.obs;
  final futurePosts = 0.obs;
  final delayMinutes = 0.obs;

  final isLoadingCatalog = false.obs;
  final isSubmittingOrder = false.obs;

  final categories = const [
    'All',
    'Followers & Subscribers',
    'Likes & Reactions',
    'Views & Streams',
    'Comments & Replies',
    'Shares, Saves & Votes',
  ];

  final countries = const [
    ('all', 'All Regions'),
    ('nigeria', 'Nigeria 🇳🇬'),
    ('global', 'Global 🌍'),
    ('ghana', 'Ghana 🇬🇭'),
  ];

  List<SocialService> get baseServices => List.unmodifiable(_baseServices);

  @override
  void onInit() {
    super.onInit();
    _baseServices.assignAll(mockSocialServices);
    PricingService.addListener((_) => applyPricingRules());
    PricingService.initialize();
    applyPricingRules();
    _hydrateBigisubCatalog();
  }

  /// Applies the latest admin pricing rules to all Social Media Boosting services.
  void applyPricingRules() {
    final priced = _baseServices
        .map((s) => PricingService.applyToSocialService(s, s.displayAmount))
        .toList();
    services.assignAll(priced);
    if (selectedService.value != null) {
      final currentId = selectedService.value!.id;
      final updatedSelected =
          priced.firstWhereOrNull((s) => s.id == currentId);
      if (updatedSelected != null) {
        selectedService.value = updatedSelected;
      }
    }
    _applyFilters();
  }

  Future<void> _hydrateBigisubCatalog() async {
    isLoadingCatalog.value = true;
    try {
      final catalog = await BigisubService.loadCatalog();
      if (catalog.marketingServices.isNotEmpty) {
        final sorted = catalog.marketingServices.toList()
          ..sort((a, b) {
            final ca =
                a.country == 'nigeria' ? 0 : (a.country == 'global' ? 1 : 2);
            final cb =
                b.country == 'nigeria' ? 0 : (b.country == 'global' ? 1 : 2);
            if (ca != cb) return ca.compareTo(cb);
            return a.startingPrice.compareTo(b.startingPrice);
          });
        _baseServices.assignAll(sorted);
        applyPricingRules();
      }
    } finally {
      isLoadingCatalog.value = false;
    }
  }

  void selectPlatform(String platformId) {
    if (selectedPlatformId.value == platformId) {
      selectedPlatformId.value = '';
    } else {
      selectedPlatformId.value = platformId;
    }
    _applyFilters();
  }

  void selectCountry(String countryCode) {
    selectedCountry.value = countryCode;
    _applyFilters();
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
    _applyFilters();
  }

  void search(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void _applyFilters() {
    var result = services.toList();

    if (selectedPlatformId.value.isNotEmpty) {
      final pid = selectedPlatformId.value.toLowerCase();
      result = result.where((s) {
        final sp = s.platformId.toLowerCase();
        if (pid == 'twitter' || pid == 'x') {
          return sp == 'twitter' || sp == 'x';
        }
        return sp == pid;
      }).toList();
    }

    if (selectedCountry.value != 'all') {
      result = result
          .where((s) => s.country.toLowerCase() == selectedCountry.value)
          .toList();
    }

    if (selectedCategory.value != 'All') {
      result = result
          .where((s) => s.normalizedCategory == selectedCategory.value)
          .toList();
    }

    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.trim().toLowerCase();
      result = result.where((s) {
        return s.name.toLowerCase().contains(q) ||
            s.category.toLowerCase().contains(q) ||
            s.platformId.toLowerCase().contains(q) ||
            '${s.bigisubServiceId}'.contains(q);
      }).toList();
    }

    filteredServices.assignAll(result);
  }

  void selectService(SocialService service) {
    selectedService.value = service;
    quantity.value = service.minQuantity;
    profileUrl.value = '';
    customText.value = '';
    pollAnswerNumber.value = 1;
    hashtag.value = '';
    oldPosts.value = 0;
    futurePosts.value = 0;
    delayMinutes.value = 0;
  }

  void clearSelection() {
    selectedService.value = null;
    quantity.value = 0;
    profileUrl.value = '';
    customText.value = '';
  }

  void setQuantity(int qty) {
    final service = selectedService.value;
    if (service == null) return;
    if (qty >= service.minQuantity && qty <= service.maxQuantity) {
      quantity.value = qty;
    }
  }

  void incrementQuantity([int? step]) {
    final service = selectedService.value;
    if (service == null) return;
    final defaultStep = service.pricingModel == 'per_unit' ? 10 : 100;
    final newQty = quantity.value + (step ?? defaultStep);
    if (newQty <= service.maxQuantity) {
      quantity.value = newQty;
    } else {
      quantity.value = service.maxQuantity;
    }
  }

  void decrementQuantity([int? step]) {
    final service = selectedService.value;
    if (service == null) return;
    final defaultStep = service.pricingModel == 'per_unit' ? 10 : 100;
    final newQty = quantity.value - (step ?? defaultStep);
    if (newQty >= service.minQuantity) {
      quantity.value = newQty;
    } else {
      quantity.value = service.minQuantity;
    }
  }

  void setProfileUrl(String url) {
    profileUrl.value = url;
  }

  void setCustomText(String text) {
    customText.value = text;
  }

  double get totalPrice {
    final service = selectedService.value;
    if (service == null) return 0;
    return service.calculatePrice(quantity.value);
  }

  SocialPlatform? get selectedPlatform {
    final service = selectedService.value;
    final targetId = service != null ? service.platformId : selectedPlatformId.value;
    if (targetId.isEmpty) return null;
    try {
      return platforms.firstWhere((p) => p.id == targetId);
    } catch (_) {
      return platforms.last;
    }
  }

  SocialPlatform platformFor(String platformId) {
    final pid = platformId.toLowerCase() == 'x' ? 'twitter' : platformId.toLowerCase();
    try {
      return platforms.firstWhere((p) => p.id == pid);
    } catch (_) {
      return platforms.last;
    }
  }
}
