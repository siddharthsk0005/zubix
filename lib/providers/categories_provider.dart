import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';

class CategoriesNotifier extends Notifier<List<CategoryModel>> {
  @override
  List<CategoryModel> build() {
    // Fetch live categories from backend asynchronously
    Future.microtask(() => fetchFromBackend());

    return [
      CategoryModel(
        id: 'cat_fashion',
        name: 'Fashion and Lifestyle',
        slug: 'fashion-lifestyle',
        iconName: 'checkroom',
        displayOrder: 1,
      ),
      CategoryModel(
        id: 'cat_beauty',
        name: 'Beauty and Body Care',
        slug: 'beauty-body-care',
        iconName: 'spa',
        displayOrder: 2,
      ),
      CategoryModel(
        id: 'cat_home',
        name: 'Home Essentials',
        slug: 'home-essentials',
        iconName: 'home',
        displayOrder: 3,
      ),
      CategoryModel(
        id: 'cat_cosmetics',
        name: 'Cosmetics',
        slug: 'cosmetics',
        iconName: 'brush',
        displayOrder: 4,
      ),
      CategoryModel(
        id: 'cat_electronics',
        name: 'Electronics and Devices',
        slug: 'electronics-devices',
        iconName: 'devices',
        displayOrder: 5,
      ),
    ];
  }

  Future<void> fetchFromBackend() async {
    try {
      final remote = await ApiService.getCategories();
      if (remote != null && remote.isNotEmpty) {
        state = remote;
      }
    } catch (_) {}
  }

  void addCategory(String name, {String iconName = 'category'}) {
    final newId = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    final slug = name.toLowerCase().replaceAll(' ', '-').replaceAll('&', 'and');
    state = [
      ...state,
      CategoryModel(
        id: newId,
        name: name,
        slug: slug,
        iconName: iconName,
        displayOrder: state.length + 1,
      ),
    ];
  }

  void updateCategory(String id, String newName, {bool? isActive}) {
    state = state.map((cat) {
      if (cat.id == id) {
        return cat.copyWith(
          name: newName,
          isActive: isActive ?? cat.isActive,
        );
      }
      return cat;
    }).toList();
  }

  void removeCategory(String id) {
    state = state.where((cat) => cat.id != id).toList();
  }
}

final categoriesProvider = NotifierProvider<CategoriesNotifier, List<CategoryModel>>(
  CategoriesNotifier.new,
);

final activeCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final all = ref.watch(categoriesProvider);
  return all.where((c) => c.isActive).toList();
});

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'cat_fashion';

  void select(String id) => state = id;
}

final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, String>(
  SelectedCategoryNotifier.new,
);
