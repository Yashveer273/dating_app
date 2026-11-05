import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Function to trigger the Rating Popup Dialog with details passed from the parent context.
void showRatingDialog(
  BuildContext context, {
  required String id,
  required String name,
  required String imageUrl,
  Function(int score, String id)? onRatingSubmitted,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.8),
    builder: (BuildContext context) {
      return RatingPopupDialog(
        id: id,
        name: name,
        imageUrl: imageUrl,
        onRatingSubmitted: onRatingSubmitted,
      );
    },
  );
}

class RatingPopupDialog extends StatefulWidget {
  // Required properties passed from parent
  final String id;
  final String name;
  final String imageUrl;
  final Function(int score, String id)? onRatingSubmitted;

  const RatingPopupDialog({
    super.key,
    required this.id,
    required this.name,
    required this.imageUrl,
    this.onRatingSubmitted,
  });

  @override
  State<RatingPopupDialog> createState() => _RatingPopupDialogState();
}

class _RatingPopupDialogState extends State<RatingPopupDialog> {
  int _selectedRating = 0;
  bool _isCopied = false;

  // Action function using the passed dynamic ID property
  void _copyHandle() {
    // Formatting handle with @ if not already formatted
    final String formattedId = widget.id.startsWith('@')
        ? widget.id
        : '@${widget.id}';

    Clipboard.setData(ClipboardData(text: formattedId));
    setState(() {
      _isCopied = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $formattedId for ${widget.name} to clipboard!'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(
          0xFFE91E63,
        ).withOpacity(0.9), // Pink theme snackbar
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  // Action function when rating is selected
  void _handleStarTap(int starNumber) {
    setState(() {
      _selectedRating = starNumber;
    });

    // Execute callback passing dynamic ratings & parent ID
    if (widget.onRatingSubmitted != null) {
      widget.onRatingSubmitted!(starNumber, widget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedId = widget.id.startsWith('@')
        ? widget.id
        : '@${widget.id}';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            color: const Color(0xFFFF4081).withOpacity(0.3),
            width: 1.5,
          ),
          // Pink-tinted deep radial gradient
          gradient: const RadialGradient(
            center: Alignment(0.0, -0.4),
            radius: 1.15,
            colors: [
              Color(0xFF4A1A2C), // Soft deep magenta/pink accent top
              Color(0xFF261019), // Mid dark pinkish maroon
              Color(0xFF0F080C), // Pure dark background
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFE91E63,
              ).withOpacity(0.25), // Subtle pink glow shadow
              blurRadius: 35,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Close Button
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.black.withOpacity(0.4),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ),
            ),

            // Header Title: "Give the rating"
            const Text(
              'Give the rating',
              style: TextStyle(
                fontFamily: 'Serif',
                fontStyle: FontStyle.italic,
                fontSize: 22,
                color: Color(0xFFFFD1DC), // Soft pinkish white title tint
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Twisted / Tilted Profile Image Frame
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective tilt
                ..rotateZ(-0.07) // ~ -4 deg rotation
                ..rotateY(0.10) // ~ 6 deg perspective
                ..rotateX(0.03),
              child: Container(
                width: 170,
                height: 215,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(
                      0xFFFF80AB,
                    ).withOpacity(0.4), // Pink frame stroke
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC2185B).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    widget.imageUrl, // Dynamic Image URL from parent
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF2E1520),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            color: Color(0xFFFF4081),
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Dynamic Person Name from parent
            Text(
              widget.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Serif',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            // Dynamic ID (@handle) with Pink Accent Copy Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4081).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF80AB).withOpacity(0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      formattedId,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFD1DC),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _copyHandle,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        _isCopied ? Icons.check_circle : Icons.copy_rounded,
                        size: 15,
                        color: _isCopied
                            ? const Color(0xFF69F0AE)
                            : const Color(0xFFFF4081),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rating instruction label
            const Text(
              'TAP TO RATE (1 - 5)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Color(0xFFFF80AB), // Pink tint label
              ),
            ),
            const SizedBox(height: 6),

            // Horizontal 1 to 5 Stars Row (Pink/Gold interactive states)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starNumber = index + 1;
                final isSelected = starNumber <= _selectedRating;
                return IconButton(
                  splashRadius: 24,
                  iconSize: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isSelected
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: isSelected
                        ? const Color(0xFFFF4081)
                        : Colors.white24, // Bright pink when selected
                  ),
                  onPressed: () => _handleStarTap(starNumber),
                );
              }),
            ),
            const SizedBox(height: 6),

            // Dynamic Feedback Text
            AnimatedOpacity(
              opacity: _selectedRating > 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                _selectedRating > 0
                    ? 'Rated $_selectedRating star${_selectedRating > 1 ? 's' : ''} for ${widget.name}!'
                    : '',
                style: const TextStyle(
                  color: Color(0xFFFF80AB),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
