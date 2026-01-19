import 'package:flutter/material.dart';

class ListItem {
  final String title;
  final String subtitle;
  final String author;
  final String date;
  final String? emoji;
  final String? imageUrl;

  const ListItem({
    required this.title,
    required this.subtitle,
    required this.author,
    required this.date,
    this.emoji,
    this.imageUrl,
  });
}

class ListItemWidget extends StatelessWidget {
  final ListItem item;

  const ListItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.blue[100],
                      alignment: Alignment.center,
                      child: Text(
                        item.emoji ?? '📦',
                        style: const TextStyle(fontSize: 32.0),
                      ),
                    ),
            ),
            const SizedBox(width: 16.0),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    item.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          item.author,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        item.date,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
