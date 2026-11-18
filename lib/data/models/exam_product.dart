/// Model representing an examination e-pin product from Bigisub Education API
/// (`GET https://api.bigisub.ng/api/v2/bills/result-checker/prices/`).
class ExamProduct {
  final String id;
  final String examCode;
  final String provider;
  final String name;
  final String description;
  final String validity;
  final double price;
  final double? corporatePrice;
  final String category;
  final bool isAvailable;
  final int? maxQuantity;
  final List<int> allowedQuantities;

  const ExamProduct({
    required this.id,
    String? examCode,
    required this.provider,
    required this.name,
    required this.description,
    this.validity = 'Valid for current examination year',
    required this.price,
    this.corporatePrice,
    required this.category,
    this.isAvailable = true,
    this.maxQuantity = 5,
    this.allowedQuantities = const [1, 2, 5],
  }) : examCode = examCode ?? provider;

  factory ExamProduct.fromBigisubJson(Map<String, dynamic> json) {
    final examType =
        (json['exam_type'] ?? json['type'] ?? json['id'] ?? 'WAEC')
            .toString()
            .toUpperCase();
    final code = (json['code'] ?? examType.toLowerCase()).toString();
    final amount =
        (json['amount'] ?? json['regular_price'] ?? 0 as num).toDouble();
    final corpPrice = (json['corporate_price'] as num?)?.toDouble();
    final validity =
        (json['validity'] ?? 'Valid for current examination year').toString();
    final desc = (json['description'] ??
            'Check $examType examination results online. Official PIN delivered instantly.')
        .toString();

    return ExamProduct(
      id: code.toLowerCase(),
      examCode: examType,
      provider: examType,
      name: (json['name'] ?? '$examType Result Checker').toString(),
      description: desc,
      validity: validity,
      price: amount,
      corporatePrice: corpPrice,
      category: examType,
      isAvailable: true,
      maxQuantity: 5,
      allowedQuantities: const [1, 2, 5],
    );
  }
}
