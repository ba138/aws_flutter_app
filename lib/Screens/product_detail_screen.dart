import 'package:flutter/material.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String productDescription;
  final double productPrice;
  final String imagePath;
  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.productDescription,
    required this.productPrice,
    required this.imagePath,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Image.network(widget.imagePath),
          Text(widget.productName),
          Text(widget.productDescription),
          Text('\$${widget.productPrice.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}
