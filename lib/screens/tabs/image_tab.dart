import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../models/creative_workspace_state.dart';
import '../../models/generated_image.dart';
import '../../services/storage_service.dart';
import '../../widgets/animated_glow_button.dart';

class ImageTab extends StatefulWidget {
  const ImageTab({super.key});

  @override
  State<ImageTab> createState() => _ImageTabState();
}

class _ImageTabState extends State<ImageTab> {
  final TextEditingController _promptController = TextEditingController();
  final StorageService _storageService = const StorageService();
  double _imageCount = 2;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generate(CreativeWorkspaceState state) async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt for the image.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    await state.generateImages(
      prompt,
      count: _imageCount.round().clamp(1, 4),
    );
  }

  Future<void> _downloadImage(GeneratedImage image) async {
    final bytes = await _resolveBytes(image);
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to download image.')),
      );
      return;
    }
    try {
      final filename = 'obsdiv_image_${image.id}';
      await _storageService.saveToGallery(bytes, filename);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved to gallery.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image: $e')),
      );
    }
  }

  Future<void> _shareImage(GeneratedImage image) async {
    final bytes = await _resolveBytes(image);
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share image.')),
      );
      return;
    }
    await _storageService.shareImage(bytes, 'obsdiv_share_${image.id}');
  }

  Future<Uint8List?> _resolveBytes(GeneratedImage image) async {
    if (image.bytes != null) {
      return image.bytes;
    }
    if (image.downloadUrl.isNotEmpty) {
      final response = await http.get(Uri.parse(image.downloadUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<CreativeWorkspaceState>();
    final theme = Theme.of(context);
    final latest = workspace.recentImages;
    final gallery = workspace.imageGallery;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe your vision and generate up to four visuals.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _promptController,
            decoration: const InputDecoration(
              labelText: 'Image prompt',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Images: ${_imageCount.round()}',
                        style: theme.textTheme.bodyMedium),
                    Slider(
                      value: _imageCount,
                      min: 1,
                      max: 4,
                      divisions: 3,
                      onChanged: (value) => setState(() => _imageCount = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AnimatedGlowButton(
            label: 'Generate images',
            icon: Icons.brush_rounded,
            isBusy: workspace.isGeneratingImages,
            onPressed: () => _generate(workspace),
          ),
          if (workspace.imageError != null) ...[
            const SizedBox(height: 8),
            Text(
              workspace.imageError!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          if (latest.isNotEmpty) ...[
            Text('Fresh creations', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _ImageGrid(
              images: latest,
              onDownload: _downloadImage,
              onShare: _shareImage,
            ),
            const SizedBox(height: 20),
          ],
          if (gallery.isNotEmpty) ...[
            Text('Your gallery', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _ImageGrid(
              images: gallery,
              onDownload: _downloadImage,
              onShare: _shareImage,
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({
    required this.images,
    required this.onDownload,
    required this.onShare,
  });

  final List<GeneratedImage> images;
  final Future<void> Function(GeneratedImage) onDownload;
  final Future<void> Function(GeneratedImage) onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      itemCount: images.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final image = images[index];
        final heroTag = 'generated_${image.id}_${image.index}';
        return Hero(
          tag: heroTag,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: theme.colorScheme.surface.withOpacity(0.95),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: image.bytes != null
                      ? Image.memory(
                    image.bytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                      : Image.network(
                    image.downloadUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: theme.colorScheme.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download_rounded),
                        onPressed: () => onDownload(image),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_rounded),
                        onPressed: () => onShare(image),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}