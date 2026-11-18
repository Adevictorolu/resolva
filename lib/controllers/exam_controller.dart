import 'package:get/get.dart';
import '../data/models/exam_product.dart';
import '../data/mock/mock_data.dart';
import '../services/bigisub_service.dart';
import '../services/pricing_service.dart';

/// Controller for Other Services — Examination E-Pins (Bigisub Education API).
class ExamController extends GetxController {
  final List<ExamProduct> _baseProducts = <ExamProduct>[];
  final products = <ExamProduct>[].obs;
  final filteredProducts = <ExamProduct>[].obs;
  final selectedCategory = 'All Products'.obs;
  final searchQuery = ''.obs;
  final selectedProduct = Rxn<ExamProduct>();
  final quantity = 1.obs;
  final isSubmittingOrder = false.obs;

  final categories = const ['All Products', 'WAEC', 'NECO', 'NABTEB'];

  List<ExamProduct> get baseProducts => List.unmodifiable(_baseProducts);

  @override
  void onInit() {
    super.onInit();
    _baseProducts.assignAll(mockExamProducts);
    PricingService.addListener((_) => applyPricingRules());
    applyPricingRules();
    _hydrateEducationCatalog();
  }

  /// Applies the latest admin pricing rules to all Examination E-Pin products.
  void applyPricingRules() {
    final priced = _baseProducts
        .map((p) => PricingService.applyToExamProduct(p, p.price))
        .toList();
    products.assignAll(priced);
    if (selectedProduct.value != null) {
      final currentId = selectedProduct.value!.id;
      final updatedSelected =
          priced.firstWhereOrNull((p) => p.id == currentId);
      if (updatedSelected != null) {
        selectedProduct.value = updatedSelected;
      }
    }
    _applyFilters();
  }

  Future<void> _hydrateEducationCatalog() async {
    final catalog = await BigisubService.loadCatalog();
    if (catalog.educationProducts.isNotEmpty) {
      _baseProducts.assignAll(catalog.educationProducts);
      applyPricingRules();
    }
    final live = await BigisubService.fetchLiveEducationPrices();
    if (live != null && live.isNotEmpty) {
      _baseProducts.assignAll(live);
      applyPricingRules();
    }
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
    var result = products.toList();

    if (selectedCategory.value != 'All Products') {
      result = result
          .where(
            (p) =>
                p.category.toUpperCase() ==
                selectedCategory.value.toUpperCase(),
          )
          .toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.provider.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q),
          )
          .toList();
    }

    filteredProducts.assignAll(result);
  }

  void selectProduct(ExamProduct product) {
    selectedProduct.value = product;
    quantity.value = 1;
  }

  void clearSelection() {
    selectedProduct.value = null;
    quantity.value = 1;
  }

  /// Bigisub Education API allows quantities 1, 2, or 5.
  void incrementQuantity() {
    final allowed =
        selectedProduct.value?.allowedQuantities ?? const [1, 2, 5];
    final idx = allowed.indexOf(quantity.value);
    if (idx >= 0 && idx < allowed.length - 1) {
      quantity.value = allowed[idx + 1];
    } else if (idx == -1) {
      quantity.value = allowed.first;
    }
  }

  void decrementQuantity() {
    final allowed =
        selectedProduct.value?.allowedQuantities ?? const [1, 2, 5];
    final idx = allowed.indexOf(quantity.value);
    if (idx > 0) {
      quantity.value = allowed[idx - 1];
    } else if (idx == -1) {
      quantity.value = allowed.first;
    }
  }

  void setQuantity(int qty) {
    final allowed =
        selectedProduct.value?.allowedQuantities ?? const [1, 2, 5];
    if (allowed.contains(qty)) {
      quantity.value = qty;
    } else if (qty <= 1) {
      quantity.value = 1;
    } else if (qty <= 3) {
      quantity.value = 2;
    } else {
      quantity.value = 5;
    }
  }

  double get totalPrice =>
      (selectedProduct.value?.price ?? 0) * quantity.value;
}
