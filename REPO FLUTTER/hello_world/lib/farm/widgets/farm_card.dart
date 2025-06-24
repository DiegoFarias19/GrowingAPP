// lib/widgets/farm_card.dart
import 'package:flutter/material.dart';
import '../models/farm_model.dart';

class FarmCard extends StatelessWidget {
  final Farm farm;
  final VoidCallback? onTap;

  const FarmCard({Key? key, required this.farm, this.onTap}) : super(key: key);

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    } else if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    }
    return AssetImage('assets/images/farm_default.jpg');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3, // Dale más espacio a la imagen
              child: Image(
                image: _getImageProvider(
                  farm.imageUrl ?? 'assets/images/farm_default.jpg',
                ),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print(
                    'Error cargando imagen para granja ${farm.farmName}: $error',
                  );
                  return Image.asset(
                    'assets/images/farm_default.jpg',
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            Expanded(
              flex: 2, // Espacio para el texto
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.farmName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
