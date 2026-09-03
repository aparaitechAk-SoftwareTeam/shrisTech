// ignore_for_file: file_names

import 'package:flutter/material.dart';

import '../RetailerCatalogue/RetailerProductDetailScreen.dart';
import '../core/userdata.dart';
import '../screens/home/owner_home_screen.dart';
import 'WishlistApis.dart';

class WishlistProductDetailScreen extends StatelessWidget {
  final WishlistItemModel item;

  const WishlistProductDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    if (UserData.instance.role.trim().toLowerCase() == 'owner') {
      return const OwnerHomeScreen();
    }
    return RetailerProductDetailScreen(product: item.product);
  }
}
