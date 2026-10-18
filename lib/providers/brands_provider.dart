import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brand_model.dart';
import '../services/api_service.dart';
import 'categories_provider.dart';

class BrandsNotifier extends Notifier<List<BrandModel>> {
  @override
  List<BrandModel> build() {
    Future.microtask(() => fetchFromBackend());

    return [
      BrandModel(
        id: 'brand_aurora',
        name: 'AURORA Minimal',
        tagline: 'Timeless Monochromatic Streetwear & Silhouettes',
        bio: 'Aurora blends high-density Japanese cotton with architectural silhouettes. Designed for effortless modern wardrobes.',
        logoUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=200&auto=format&fit=crop&q=80',
        showcaseImages: [
          'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=900&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1445205170230-053b83016050?w=900&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=900&auto=format&fit=crop&q=80',
        ],
        websiteUrl: 'https://auroraminimal.example.com',
        socialLinks: {
          'Instagram': 'https://instagram.com/aurora.minimal',
          'X': 'https://x.com/auroraminimal',
          'LinkedIn': 'https://linkedin.com/company/aurora-apparel',
        },
        contactEmail: 'partner@auroraminimal.com',
        contactPhone: '+1 (555) 392-8810',
        categoryId: 'cat_fashion',
        sessionCreatedBy: 'Aman Verma (Lead Curator)',
        isApproved: true,
      ),
      BrandModel(
        id: 'brand_botanica',
        name: 'Botanica Botanics',
        tagline: 'Cold-Pressed Botanical Body & Skin Elixirs',
        bio: 'Zero-chemical, wild-harvested botanicals crafted for skin barrier restoration and natural glow.',
        logoUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=200&auto=format&fit=crop&q=80',
        showcaseImages: [
          'https://images.unsplash.com/photo-1608248597359-566085a85590?w=900&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=900&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=900&auto=format&fit=crop&q=80',
        ],
        websiteUrl: 'https://botanicabotanics.example.com',
        socialLinks: {
          'Instagram': 'https://instagram.com/botanica.official',
          'LinkedIn': 'https://linkedin.com/company/botanica-skincare',
        },
        contactEmail: 'press@botanica.com',
        contactPhone: '+1 (555) 782-9901',
        categoryId: 'cat_beauty',
        sessionCreatedBy: 'Siddharth Kumawat (Admin)',
        isApproved: true,
      ),
      BrandModel(
        id: 'brand_nordic',
        name: 'Nordic Space',
        tagline: 'Artisanal Ceramic & Wood Home Accents',
        bio: 'Functional interior objects celebrating raw organic textures and Scandinavian minimalism.',
        logoUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=200&auto=format&fit=crop&q=80',
        showcaseImages: [
          'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=900&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?w=900&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=900&auto=format&fit=crop&q=80',
        ],
        websiteUrl: 'https://nordicspace.example.com',
        socialLinks: {
          'Instagram': 'https://instagram.com/nordicspace',
          'X': 'https://x.com/nordic_space',
        },
        contactEmail: 'concierge@nordicspace.com',
        contactPhone: '+1 (555) 234-7712',
        categoryId: 'cat_home',
        sessionCreatedBy: 'Zubix Partner Guild',
        isApproved: true,
      ),
      BrandModel(
        id: 'brand_lumiere',
        name: 'LUMIÈRE Atelier',
        tagline: 'High-Pigment Vegan Mineral Cosmetics',
        bio: 'Clean performance makeup engineered for ultra-fine blendability and 18-hour weightless wear.',
        logoUrl: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=200&auto=format&fit=crop&q=80',
        showcaseImages: [
          'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=900&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=900&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?w=900&auto=format&fit=crop&q=80',
        ],
        websiteUrl: 'https://lumiereatelier.example.com',
        socialLinks: {
          'Instagram': 'https://instagram.com/lumiereatelier',
          'X': 'https://x.com/lumiere_cosmetics',
        },
        contactEmail: 'connect@lumiereatelier.com',
        contactPhone: '+1 (555) 912-3450',
        categoryId: 'cat_cosmetics',
        sessionCreatedBy: 'Admin Control Center',
        isApproved: true,
      ),
      BrandModel(
        id: 'brand_kanso',
        name: 'KANSO Audio & Tech',
        tagline: 'Precision Acoustic Hi-Fi & Wireless Earwear',
        bio: 'Bespoke precision audio with beryllium drivers and CNC anodized aluminum craftsmanship.',
        logoUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=200&auto=format&fit=crop&q=80',
        showcaseImages: [
          'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=900&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=900&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=900&auto=format&fit=crop&q=80',
        ],
        websiteUrl: 'https://kansoaudio.example.com',
        socialLinks: {
          'Instagram': 'https://instagram.com/kansoaudio',
          'X': 'https://x.com/kanso_tech',
          'LinkedIn': 'https://linkedin.com/company/kanso-audio',
        },
        contactEmail: 'hello@kansoaudio.com',
        contactPhone: '+1 (555) 674-8890',
        categoryId: 'cat_electronics',
        sessionCreatedBy: 'Zubix Editorial Board',
        isApproved: true,
      ),
    ];
  }

  Future<void> fetchFromBackend() async {
    try {
      final remote = await ApiService.getBrands();
      if (remote != null && remote.isNotEmpty) {
        state = remote;
      }
    } catch (_) {}
  }

  void addBrand(BrandModel brand) {
    state = [...state, brand];
  }

  void toggleApproval(String brandId, bool isApproved) {
    state = state.map((b) {
      if (b.id == brandId) {
        return b.copyWith(isApproved: isApproved);
      }
      return b;
    }).toList();
  }
}

final brandsProvider = NotifierProvider<BrandsNotifier, List<BrandModel>>(
  BrandsNotifier.new,
);

final approvedBrandsProvider = Provider<List<BrandModel>>((ref) {
  final all = ref.watch(brandsProvider);
  return all.where((b) => b.isApproved).toList();
});

final currentCategoryBrandsProvider = Provider<List<BrandModel>>((ref) {
  final selectedCat = ref.watch(selectedCategoryProvider);
  final approved = ref.watch(approvedBrandsProvider);
  return approved.where((b) => b.categoryId == selectedCat).toList();
});
