import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'متجر الأهلي',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // زخرفة ذهبية في الخلفية
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset('assets/images/gold_pattern.png', repeat: ImageRepeat.repeat),
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: 6, // عينة من المنتجات
            itemBuilder: (context, index) {
              return FadeInUp(
                delay: Duration(milliseconds: index * 100),
                child: _buildProductCard(index),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(int index) {
    final products = [
      {'name': 'قميص الأهلي الأساسي', 'price': '1200', 'image': 'https://via.placeholder.com/300x400?text=Ahly+Jersey'},
      {'name': 'قميص التدريب', 'price': '850', 'image': 'https://via.placeholder.com/300x400?text=Training+Kit'},
      {'name': 'وشاح النادي', 'price': '250', 'image': 'https://via.placeholder.com/300x400?text=Scarf'},
      {'name': 'قبعة الأهلي', 'price': '300', 'image': 'https://via.placeholder.com/300x400?text=Cap'},
      {'name': 'حقيبة رياضية', 'price': '600', 'image': 'https://via.placeholder.com/300x400?text=Bag'},
      {'name': 'كرة قدم الأهلي', 'price': '450', 'image': 'https://via.placeholder.com/300x400?text=Ball'},
    ];

    final product = products[index % products.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: CachedNetworkImage(
                imageUrl: product['image']!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name']!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${product['price']} ج.م",
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Icon(Icons.add_shopping_cart, color: Colors.amber, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
