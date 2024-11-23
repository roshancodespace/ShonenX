import 'package:flutter/material.dart';

class MediumCard extends StatelessWidget {
  const MediumCard({super.key});

 @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              'https://i.imgur.com/FpBVLQe.jpg', // Replace with your anime image URL
              height: 60,
              width: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          // Title and Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Attack on Titan', // Replace with anime name
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                // Progress Bar
                LinearProgressIndicator(
                  value: 0.45, // Replace with actual progress value
                  backgroundColor: Colors.grey[300],
                  color: Theme.of(context).colorScheme.primary,
                  minHeight: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Play Button
          IconButton(
            onPressed: () {
              // Play action
            },
            icon: Icon(
              Icons.play_arrow_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}