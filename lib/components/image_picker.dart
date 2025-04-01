import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerComponent extends StatefulWidget {
  final Function(List<File>) onNewImagesSelected;
  final Function(int)? onExistingImageRemoved;
  final List<String> existingImageUrls;
  final List<File> initialImages;
  final double itemHeight;
  final double itemWidth;
  final int crossAxisCount;
  final String placeholder;
  final BorderRadius borderRadius;

  const ImagePickerComponent({
    Key? key,
    required this.onNewImagesSelected,
    this.onExistingImageRemoved,
    this.existingImageUrls = const [],
    this.initialImages = const [],
    this.itemHeight = 100,
    this.itemWidth = 100,
    this.crossAxisCount = 3,
    this.placeholder = 'Tap to add photos',
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  }) : super(key: key);

  @override
  State<ImagePickerComponent> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerComponent> {
  final ImagePicker _picker = ImagePicker();
  late List<File> _newImages;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _newImages = List.from(widget.initialImages);
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      setState(() => _isLoading = true);

      final List<XFile> pickedFiles = source == ImageSource.camera
          ? await _picker.pickImage(source: source).then((file) => file != null ? [file] : [])
          : await _picker.pickMultiImage(imageQuality: 80);

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _newImages.addAll(pickedFiles.map((file) => File(file.path)));
          widget.onNewImagesSelected(_newImages);
        });
      }
    } catch (e) {
      print('Error picking images: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
      widget.onNewImagesSelected(_newImages);
    });
  }

  void _removeExistingImage(int index) {
    widget.onExistingImageRemoved?.call(index);
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImages(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImages(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = widget.existingImageUrls.length + _newImages.length + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: widget.itemWidth / widget.itemHeight,
          ),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            if (index < widget.existingImageUrls.length) {
              return _buildImageItem(
                imageUrl: widget.existingImageUrls[index],
                isExisting: true,
                onRemove: () => _removeExistingImage(index),
              );
            }

            final newIndex = index - widget.existingImageUrls.length;
            if (newIndex < _newImages.length) {
              return _buildImageItem(
                imageFile: _newImages[newIndex],
                onRemove: () => _removeNewImage(newIndex),
              );
            }

            return _buildAddButton();
          },
        ),
        if (_isLoading) const LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildImageItem({
    String? imageUrl,
    File? imageFile,
    bool isExisting = false,
    VoidCallback? onRemove,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            image: DecorationImage(
              image: imageUrl != null
                  ? NetworkImage(imageUrl)
                  : FileImage(imageFile!) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        if (isExisting)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Existing',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: widget.borderRadius,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_photo_alternate, color: Colors.grey),
              const SizedBox(height: 4),
              Text(
                widget.placeholder,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}