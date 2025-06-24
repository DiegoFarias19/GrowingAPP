// lib/widgets/crop_card.dart
import 'package:flutter/material.dart';
import '../models/crop_model.dart';

class CropCard extends StatelessWidget {
  final Crop crop;
  final VoidCallback? onTap;

  const CropCard({Key? key, required this.crop, this.onTap}) : super(key: key);

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
              flex: 3,
              child: Image(
                image: _getImageProvider(crop.imageUrl ?? ''),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print(
                    'Error cargando imagen para cultivo ${crop.cropName}: $error',
                  );
                  return Image.asset(
                    'assets/images/farm_default.jpg',
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.cropName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (crop.status != null && crop.status!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Estado: ${crop.status}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
