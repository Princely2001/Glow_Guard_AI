import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/test_models.dart';
import '../widgets/common_widgets.dart';
import '../Chemical_expert/instructions_screen.dart';
import '../Chemical_expert/prediction_result_screen.dart';
import '../services/Chemical_expert/chemical_test_controller.dart';

//  DESIGN TOKENS  (light theme)
class _Clr {
  static const bg          = Color(0xFFF5F7FA);
  static const card        = Color(0xFFFFFFFF);
  static const primary     = Color(0xFF1A6EFF);
  static const label       = Color(0xFF0F1C3F);
  static const sublabel    = Color(0xFF6B7A99);
  static const border      = Color(0xFFDDE3EF);
  static const shadow      = Color(0x14102050);
  static const chipSel     = Color(0xFF1A6EFF);
  static const chipUnsel   = Color(0xFFEFF2FA);
  static const chipSelTxt  = Color(0xFFFFFFFF);
  static const chipUnselTxt= Color(0xFF4B5A7A);
  static const beforeBg    = Color(0xFFFFF8EC);
  static const afterBg     = Color(0xFFECFDF5);
  static const beforeBorder= Color(0xFFFFCB6B);
  static const afterBorder = Color(0xFF34D399);
  static const beforeTag   = Color(0xFFF59E0B);
  static const afterTag    = Color(0xFF10B981);
}
//  SCREEN

class StartTestScreen extends StatefulWidget {
  final String? requestedUserId;
  final String? appointmentId;

  const StartTestScreen({
    super.key,
    this.requestedUserId,
    this.appointmentId,
  });

  @override
  State<StartTestScreen> createState() => _StartTestScreenState();
}

class _StartTestScreenState extends State<StartTestScreen>
    with SingleTickerProviderStateMixin {
  late final ChemicalTestController _controller;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = ChemicalTestController();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  String _testTypeLabel(TestType t) =>
      t.toString().split('.').last.toUpperCase();

  Future<void> _handleAnalyze() async {
    if (_controller.before == null || _controller.after == null) {
      _showSnack('Please add BOTH Before and After photos.', isError: true);
      return;
    }
    try {
      final pred = await _controller.analyze();
      if (pred != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PredictionResultScreen(
              prediction: pred,
              testType: _controller.type,
              before: _controller.before!,
              after: _controller.after!,
              mergedPreviewPng: _controller.mergedPreviewPng,
              onSaveToDatabase: (String expertNote) =>
                  _controller.saveToDatabase(
                    userId: widget.requestedUserId ?? 'unknown_user',
                    appointmentId: widget.appointmentId,
                    expertNote: expertNote,
                  ),
              onRequestProfessionalTest: (String expertNote) =>
                  _controller.requestProfessionalTest(
                    userId: widget.requestedUserId ?? 'unknown_user',
                    appointmentId: widget.appointmentId,
                    expertNote: expertNote,
                  ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              color: Colors.white),
        ),
        backgroundColor: isError ? const Color(0xFFE53935) : _Clr.afterTag,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  //BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Clr.bg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(18, 110, 18, 40),
            children: [
              //Hero
              _HeroHeader(
                modelReady: _controller.modelReady,
                lastPrediction: _controller.lastPrediction,
              ),
              const SizedBox(height: 22),

              //Test Type
              const _SectionLabel(
                  icon: Icons.science_outlined, text: 'Test Type'),
              const SizedBox(height: 10),
              _TestTypeCard(
                current: _controller.type,
                onSelect: _controller.setTestType,
                labelOf: _testTypeLabel,
              ),
              const SizedBox(height: 24),

              //Photos
              const _SectionLabel(
                  icon: Icons.photo_camera_outlined, text: 'Sample Photos'),
              const SizedBox(height: 10),
              _PhotoRow(
                beforeFile: _controller.before,
                afterFile: _controller.after,
                onBeforeCamera: () =>
                    _controller.pickBefore(ImageSource.camera),
                onBeforeGallery: () =>
                    _controller.pickBefore(ImageSource.gallery),
                onAfterCamera: () =>
                    _controller.pickAfter(ImageSource.camera),
                onAfterGallery: () =>
                    _controller.pickAfter(ImageSource.gallery),
              ),
              const SizedBox(height: 24),

              //Combined Preview
              if (_controller.before != null &&
                  _controller.after != null) ...[
                const _SectionLabel(
                    icon: Icons.compare_rounded,
                    text: 'Combined Preview'),
                const SizedBox(height: 10),
                _MergedPreviewCard(bytes: _controller.mergedPreviewPng),
                const SizedBox(height: 24),
              ],

              // Analyze Button
              _AnalyzeButton(
                busy: _controller.busy,
                modelReady: _controller.modelReady,
                onPressed: _handleAnalyze,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: _GlassIconBtn(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.maybePop(context),
      ),
      title: const Text(
        'Chemical Test',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: _Clr.label,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      actions: [
        _GlassIconBtn(
          icon: Icons.menu_book_outlined,
          tooltip: 'Instructions',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const InstructionsScreen()),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
//  HERO HEADER
class _HeroHeader extends StatelessWidget {
  final bool modelReady;
  final dynamic lastPrediction;

  const _HeroHeader({required this.modelReady, this.lastPrediction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A6EFF), Color(0xFF0099FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A6EFF).withOpacity(0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // icon bubble
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Analysis Ready',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: modelReady
                            ? const Color(0xFF34D399)
                            : const Color(0xFFFFCB6B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      modelReady
                          ? 'ML Model loaded'
                          : 'Loading ML model…',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                if (lastPrediction != null) ...[
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Last: ${lastPrediction!.label}  •  '
                          '${(100 * lastPrediction!.confidence).toStringAsFixed(1)}%'
                          '${lastPrediction!.isUnclear ? ' (Unclear)' : ''}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
//  SECTION LABEL
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: _Clr.primary),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _Clr.label,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

//  TEST TYPE CARD
class _TestTypeCard extends StatelessWidget {
  final TestType current;
  final ValueChanged<TestType> onSelect;
  final String Function(TestType) labelOf;

  const _TestTypeCard({
    required this.current,
    required this.onSelect,
    required this.labelOf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _Clr.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Clr.border),
        boxShadow: [
          BoxShadow(
              color: _Clr.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Wrap(
        spacing: 9,
        runSpacing: 9,
        children: TestType.values.map((t) {
          final selected = t == current;
          return GestureDetector(
            onTap: () => onSelect(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? _Clr.chipSel : _Clr.chipUnsel,
                borderRadius: BorderRadius.circular(30),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: _Clr.primary.withOpacity(0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
                    : [],
              ),
              child: Text(
                labelOf(t),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? _Clr.chipSelTxt
                      : _Clr.chipUnselTxt,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

//  PHOTO ROW  (Before + After side by side)

class _PhotoRow extends StatelessWidget {
  final dynamic beforeFile;
  final dynamic afterFile;
  final VoidCallback onBeforeCamera;
  final VoidCallback onBeforeGallery;
  final VoidCallback onAfterCamera;
  final VoidCallback onAfterGallery;

  const _PhotoRow({
    required this.beforeFile,
    required this.afterFile,
    required this.onBeforeCamera,
    required this.onBeforeGallery,
    required this.onAfterCamera,
    required this.onAfterGallery,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SinglePhotoCard(
              label: 'BEFORE',
              sublabel: 'Left sample',
              bgColor: _Clr.beforeBg,
              borderColor: _Clr.beforeBorder,
              tagColor: _Clr.beforeTag,
              file: beforeFile,
              onCamera: onBeforeCamera,
              onGallery: onBeforeGallery,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SinglePhotoCard(
              label: 'AFTER',
              sublabel: 'Right sample',
              bgColor: _Clr.afterBg,
              borderColor: _Clr.afterBorder,
              tagColor: _Clr.afterTag,
              file: afterFile,
              onCamera: onAfterCamera,
              onGallery: onAfterGallery,
            ),
          ),
        ],
      ),
    );
  }
}
//  SINGLE PHOTO CARD

class _SinglePhotoCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color bgColor;
  final Color borderColor;
  final Color tagColor;
  final dynamic file; // XFile
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _SinglePhotoCard({
    required this.label,
    required this.sublabel,
    required this.bgColor,
    required this.borderColor,
    required this.tagColor,
    required this.file,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: file != null ? _Clr.card : bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label bar
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    sublabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tagColor.withOpacity(0.80),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Image area
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: file != null
                ? _ImagePreview(file: file)
                : _EmptyPhotoPlaceholder(
                bgColor: bgColor, tagColor: tagColor),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: _SmallPhotoBtn(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: tagColor,
                    onTap: onCamera,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SmallPhotoBtn(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: tagColor,
                    onTap: onGallery,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


//  IMAGE PREVIEW  — full-color, crisp, no tint overlay

class _ImagePreview extends StatelessWidget {
  final dynamic file; // XFile
  const _ImagePreview({required this.file});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 150,
            child: Center(
                child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return SizedBox(
          height: 150,
          width: double.infinity,
          child: Image.memory(
            snap.data!,
            fit: BoxFit.cover,
            // No color filter — render exactly as captured
            gaplessPlayback: true,
          ),
        );
      },
    );
  }
}


//  EMPTY PLACEHOLDER

class _EmptyPhotoPlaceholder extends StatelessWidget {
  final Color bgColor;
  final Color tagColor;

  const _EmptyPhotoPlaceholder({
    required this.bgColor,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      color: bgColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 36, color: tagColor.withOpacity(0.55)),
            const SizedBox(height: 8),
            Text(
              'Tap to add photo',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tagColor.withOpacity(0.60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


//  SMALL PHOTO BUTTON

class _SmallPhotoBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallPhotoBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


//  MERGED PREVIEW CARD

class _MergedPreviewCard extends StatelessWidget {
  final Uint8List? bytes;
  const _MergedPreviewCard({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _Clr.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Clr.border),
        boxShadow: [
          BoxShadow(
              color: _Clr.shadow,
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: bytes == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
          fit: StackFit.expand,
          children: [
            // image — full color, no overlay
            Image.memory(bytes!, fit: BoxFit.cover),
            // white divider line at center
            Center(
              child: Container(
                width: 2,
                color: Colors.white.withOpacity(0.70),
              ),
            ),
            // BEFORE label
            Positioned(
              left: 12,
              bottom: 12,
              child: _ImageBadge(
                  label: 'BEFORE',
                  color: _Clr.beforeTag),
            ),
            // AFTER label
            Positioned(
              right: 12,
              bottom: 12,
              child:
              _ImageBadge(label: 'AFTER', color: _Clr.afterTag),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ImageBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.40), blurRadius: 8)
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}


//  ANALYZE BUTTON

class _AnalyzeButton extends StatelessWidget {
  final bool busy;
  final bool modelReady;
  final VoidCallback onPressed;

  const _AnalyzeButton({
    required this.busy,
    required this.modelReady,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = !busy && modelReady;
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 58,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
            colors: [Color(0xFF1A6EFF), Color(0xFF0099FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
              : LinearGradient(colors: [
            Colors.grey.shade300,
            Colors.grey.shade300
          ]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled
              ? [
            BoxShadow(
              color: const Color(0xFF1A6EFF).withOpacity(0.36),
              blurRadius: 18,
              offset: const Offset(0, 7),
            )
          ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              busy ? 'Analyzing…' : 'Analyze with ML',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color:
                enabled ? Colors.white : Colors.grey.shade600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


//  GLASS ICON BUTTON  (AppBar)

class _GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onTap;

  const _GlassIconBtn({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: _Clr.card,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _Clr.border),
            boxShadow: [
              BoxShadow(
                  color: _Clr.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Icon(icon, size: 18, color: _Clr.label),
        ),
      ),
    );
  }
}