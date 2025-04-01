import 'package:flutter/material.dart';

class ImageGalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageGalleryViewer({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _ImageGalleryViewerState createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Photo ${_currentIndex + 1}/${widget.imageUrls.length}',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          // Toggle between gallery and fullscreen view
          IconButton(
            icon: Icon(_isFullScreen ? Icons.grid_view : Icons.fullscreen),
            onPressed: () {
              setState(() {
                _isFullScreen = !_isFullScreen;
              });
            },
          ),
          // Close button
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Main image display
          Expanded(
            child: _isFullScreen
                ? _buildFullScreenView()
                : _buildPageView(),
          ),

          // Thumbnail gallery at the bottom (only visible in gallery mode)
          if (!_isFullScreen)
            Container(
              height: 80,
              color: Colors.black,
              child: _buildThumbnailGallery(),
            ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.imageUrls.length,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _isFullScreen = true;
            });
          },
          child: Center(
            child: Image.network(
              widget.imageUrls[index],
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullScreenView() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isFullScreen = false;
          });
        },
        child: Stack(
          children: [
            // Center image
            Center(
              child: Image.network(
                widget.imageUrls[_currentIndex],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),

            // Navigation arrows
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  if (_currentIndex > 0)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentIndex--;
                        });
                        _pageController.animateToPage(
                          _currentIndex,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 60,
                        color: Colors.transparent,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Next button
                  if (_currentIndex < widget.imageUrls.length - 1)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentIndex++;
                        });
                        _pageController.animateToPage(
                          _currentIndex,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 60,
                        color: Colors.transparent,
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailGallery() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: widget.imageUrls.length,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            width: 64,
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: _currentIndex == index ? Colors.blue : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                widget.imageUrls[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}