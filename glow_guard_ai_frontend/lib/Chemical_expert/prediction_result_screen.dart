import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../models/test_models.dart';
import '../services/Chemical_expert/ml/ingredient_classifier.dart';
//  DESIGN TOKENS  — mirrors StartTestScreen exactly

class _Clr {
  static const bg           = Color(0xFFF5F7FA);
  static const card         = Color(0xFFFFFFFF);
  static const primary      = Color(0xFF1A6EFF);
  static const primaryLight = Color(0xFF0099FF);
  static const label        = Color(0xFF0F1C3F);
  static const sublabel     = Color(0xFF6B7A99);
  static const border       = Color(0xFFDDE3EF);
  static const shadow       = Color(0x14102050);

  // Status — safe
  static const safeAccent   = Color(0xFF10B981);
  static const safeBg       = Color(0xFFECFDF5);
  static const safeBorder   = Color(0xFF34D399);

  // Status — danger
  static const dangerAccent = Color(0xFFEF4444);
  static const dangerBg     = Color(0xFFFFF1F1);
  static const dangerBorder = Color(0xFFFCA5A5);

  // Status — unclear
  static const warnAccent   = Color(0xFFF59E0B);
  static const warnBg       = Color(0xFFFFF8EC);
  static const warnBorder   = Color(0xFFFFCB6B);

  // Before / After (same as StartTestScreen)
  static const beforeBg     = Color(0xFFFFF8EC);
  static const afterBg      = Color(0xFFECFDF5);
  static const beforeBorder = Color(0xFFFFCB6B);
  static const afterBorder  = Color(0xFF34D399);
  static const beforeTag    = Color(0xFFF59E0B);
  static const afterTag     = Color(0xFF10B981);
}

//  SCREEN

class PredictionResultScreen extends StatefulWidget {
  final MlPrediction prediction;
  final TestType testType;
  final dynamic before;
  final dynamic after;
  final Uint8List? mergedPreviewPng;

  final Future<String> Function(String expertNote)? onSaveToDatabase;
  final Future<void>   Function(String expertNote)? onRequestProfessionalTest;

  const PredictionResultScreen({
    super.key,
    required this.prediction,
    required this.testType,
    required this.before,
    required this.after,
    required this.mergedPreviewPng,
    this.onSaveToDatabase,
    this.onRequestProfessionalTest,
  });

  @override
  State<PredictionResultScreen> createState() => _PredictionResultScreenState();
}

class _PredictionResultScreenState extends State<PredictionResultScreen>
    with TickerProviderStateMixin {

  late final AnimationController _enterCtrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slideUp;

  final TextEditingController _noteCtrl = TextEditingController();

  bool _sending = false;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade    = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  //  Helpers
  bool get _isSafe    => widget.prediction.label.toLowerCase().trim() == 'safe';
  bool get _isUnclear => widget.prediction.isUnclear;

  Color get _accent => _isUnclear ? _Clr.warnAccent
      : (_isSafe ? _Clr.safeAccent : _Clr.dangerAccent);

  Color get _statusBg => _isUnclear ? _Clr.warnBg
      : (_isSafe ? _Clr.safeBg : _Clr.dangerBg);

  Color get _statusBorder => _isUnclear ? _Clr.warnBorder
      : (_isSafe ? _Clr.safeBorder : _Clr.dangerBorder);

  IconData get _statusIcon => _isUnclear
      ? Icons.help_outline_rounded
      : (_isSafe ? Icons.verified_rounded : Icons.warning_rounded);

  String get _statusTitle => _isUnclear
      ? 'Result Unclear'
      : (_isSafe ? 'Looks Safe ✓' : 'Danger Detected');

  String get _statusSubtitle => _isUnclear
      ? 'The model is not confident. Please confirm with an advanced chemical test.'
      : (_isSafe
      ? 'No harmful ingredient strongly detected in this sample.'
      : 'A harmful ingredient pattern was detected in this sample.');

  String _testTypeLabel(TestType t) =>
      t.toString().split('.').last.toUpperCase();

  String _prettyProbs() {
    final probs = widget.prediction.probs
        .map((v) => (v * 100).toStringAsFixed(1))
        .toList();
    if (probs.length == 4) {
      return 'Safe ${probs[0]}%  •  HQ ${probs[1]}%  •  Hg ${probs[2]}%  •  Steroids ${probs[3]}%';
    }
    return probs.join('  •  ');
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      String id = '';
      if (widget.onSaveToDatabase != null) {
        id = await widget.onSaveToDatabase!(_noteCtrl.text.trim());
      } else {
        await Future.delayed(const Duration(milliseconds: 900));
      }
      if (!mounted) return;
      _showSnack(id.isEmpty ? 'Test result saved.' : 'Saved ✅  Record: $id');
    } catch (e) {
      if (mounted) _showSnack('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleRequestPro() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      if (widget.onRequestProfessionalTest != null) {
        await widget.onRequestProfessionalTest!(_noteCtrl.text.trim());
      } else {
        await Future.delayed(const Duration(milliseconds: 900));
      }
      if (!mounted) return;
      _showSnack('Professional test requested successfully.');
    } catch (e) {
      if (mounted) _showSnack('Failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              color: Colors.white)),
      backgroundColor: isError ? const Color(0xFFEF4444) : _Clr.safeAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    ));
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Clr.bg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slideUp,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 110, 18, 40),
            children: [
              // 1. Status Hero
              _StatusHeroCard(
                accent: _accent,
                statusBg: _statusBg,
                statusBorder: _statusBorder,
                statusIcon: _statusIcon,
                statusTitle: _statusTitle,
                statusSubtitle: _statusSubtitle,
                label: widget.prediction.label,
                testTypeLabel: _testTypeLabel(widget.testType),
                confidence: widget.prediction.confidence.clamp(0.0, 1.0),
                isUnclear: _isUnclear,
                margin: widget.prediction.margin,
                probsLine: _prettyProbs(),
              ),
              const SizedBox(height: 20),

              // 2. Unclear Recommendations
              if (_isUnclear) ...[
                _RecommendationsCard(accent: _accent),
                const SizedBox(height: 20),
              ],

              // 3. Combined Preview
              _SectionLabel(icon: Icons.compare_rounded, text: 'Combined Preview'),
              const SizedBox(height: 10),
              _MergedPreviewCard(bytes: widget.mergedPreviewPng),
              const SizedBox(height: 20),

              // ── 4. Before / After
              _SectionLabel(icon: Icons.photo_camera_outlined, text: 'Sample Photos'),
              const SizedBox(height: 10),
              _BeforeAfterRow(before: widget.before, after: widget.after),
              const SizedBox(height: 24),

              //  5. Expert Notes
              _SectionLabel(icon: Icons.edit_note_rounded, text: 'Expert Notes'),
              const SizedBox(height: 10),
              _ExpertNoteField(controller: _noteCtrl),
              const SizedBox(height: 22),

              // 6. Action Buttons ─
              _ActionRow(
                saving: _saving,
                sending: _sending,
                onSave: _handleSave,
                onRequestPro: _handleRequestPro,
              ),
              const SizedBox(height: 12),

              //  7. Run Another
              _RunAnotherBtn(onTap: () => Navigator.pop(context)),
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
        'Test Result',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: _Clr.label,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
    );
  }
}


//  STATUS HERO CARD

class _StatusHeroCard extends StatelessWidget {
  final Color accent, statusBg, statusBorder;
  final IconData statusIcon;
  final String statusTitle, statusSubtitle, label, testTypeLabel, probsLine;
  final double confidence;
  final bool isUnclear;
  final double margin;

  const _StatusHeroCard({
    required this.accent,
    required this.statusBg,
    required this.statusBorder,
    required this.statusIcon,
    required this.statusTitle,
    required this.statusSubtitle,
    required this.label,
    required this.testTypeLabel,
    required this.confidence,
    required this.isUnclear,
    required this.margin,
    required this.probsLine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Clr.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusBorder, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _Clr.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chips row
          Row(
            children: [
              _StatusChip(text: label, bg: statusBg, fg: accent),
              const SizedBox(width: 8),
              _StatusChip(
                text: testTypeLabel,
                bg: const Color(0xFFEFF2FA),
                fg: _Clr.sublabel,
              ),
              const Spacer(),
              // confidence badge
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(statusIcon, color: accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _Clr.label,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusSubtitle,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _Clr.sublabel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Confidence bar
          Row(
            children: [
              const Text(
                'Confidence',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _Clr.label,
                ),
              ),
              const Spacer(),
              Text(
                '${(confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: confidence),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: _Clr.border,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),

          if (isUnclear) ...[
            const SizedBox(height: 10),
            Text(
              'Confidence margin: ${(margin * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _Clr.sublabel,
              ),
            ),
          ],

          const SizedBox(height: 14),
          // Divider
          Container(height: 1, color: _Clr.border),
          const SizedBox(height: 12),

          // Probability breakdown
          Text(
            probsLine,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _Clr.sublabel,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const _StatusChip({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}


//  RECOMMENDATIONS CARD  (unclear only)
class _RecommendationsCard extends StatelessWidget {
  final Color accent;
  const _RecommendationsCard({required this.accent});

  static const _recs = [
    'Lab confirmation recommended — result is uncertain.',
    'For Hydroquinone / Steroids: HPLC or GC-MS (lab test).',
    'For Mercury: ICP-MS or AAS (lab test).',
    'If for medical/skin use, consult a qualified professional.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Clr.warnBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Clr.warnBorder, width: 1.4),
        boxShadow: [
          BoxShadow(
              color: _Clr.warnAccent.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _Clr.warnAccent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.science_rounded,
                    color: _Clr.warnAccent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Recommended Next Steps',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _Clr.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._recs.map(
                (t) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _Clr.warnAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _Clr.label,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


//  COMBINED / MERGED PREVIEW CARD
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
              color: _Clr.shadow, blurRadius: 16, offset: const Offset(0, 6))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: bytes == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(bytes!, fit: BoxFit.cover),
            // centre divider
            Center(
              child: Container(
                  width: 2,
                  color: Colors.white.withOpacity(0.75)),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: _ImageBadge(
                  label: 'BEFORE', color: _Clr.beforeTag),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: _ImageBadge(
                  label: 'AFTER', color: _Clr.afterTag),
            ),
          ],
        ),
      ),
    );
  }
}


//  BEFORE / AFTER PHOTO ROW  — crisp, full-colour, clearly labelled

class _BeforeAfterRow extends StatelessWidget {
  final dynamic before;
  final dynamic after;
  const _BeforeAfterRow({required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _PhotoCard(
              label: 'BEFORE',
              sublabel: 'Left sample',
              bgColor: _Clr.beforeBg,
              borderColor: _Clr.beforeBorder,
              tagColor: _Clr.beforeTag,
              file: before,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PhotoCard(
              label: 'AFTER',
              sublabel: 'Right sample',
              bgColor: _Clr.afterBg,
              borderColor: _Clr.afterBorder,
              tagColor: _Clr.afterTag,
              file: after,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final String label, sublabel;
  final Color bgColor, borderColor, tagColor;
  final dynamic file; // XFile or File

  const _PhotoCard({
    required this.label,
    required this.sublabel,
    required this.bgColor,
    required this.borderColor,
    required this.tagColor,
    required this.file,
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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label bar
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.12),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(18)),
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

          // Image — full-colour, no tint, crisp
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18)),
            child: file == null
                ? Container(
              height: 160,
              color: bgColor,
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 36,
                  color: tagColor.withOpacity(0.45),
                ),
              ),
            )
                : _FileImage(file: file, height: 160),
          ),
        ],
      ),
    );
  }
}

/// Works for both XFile (readAsBytes) and dart:io File
class _FileImage extends StatelessWidget {
  final dynamic file;
  final double height;
  const _FileImage({required this.file, required this.height});

  @override
  Widget build(BuildContext context) {
    // dart:io File
    if (file is File) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Image.file(
          file as File,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const _ImageError(),
        ),
      );
    }
    // XFile — read bytes once
    return FutureBuilder<Uint8List>(
      future: (file as dynamic).readAsBytes(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return SizedBox(
            height: height,
            child:
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return SizedBox(
          height: height,
          width: double.infinity,
          child: Image.memory(
            snap.data!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const _ImageError(),
          ),
        );
      },
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 160,
    child: Center(
        child: Icon(Icons.broken_image_outlined,
            size: 32, color: _Clr.sublabel)),
  );
}


//  EXPERT NOTES FIELD

class _ExpertNoteField extends StatelessWidget {
  final TextEditingController controller;
  const _ExpertNoteField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: TextField(
        controller: controller,
        maxLines: 4,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _Clr.label,
          height: 1.6,
        ),
        decoration: InputDecoration(
          hintText:
          'Enter your analysis or notes about the result before saving…',
          hintStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _Clr.sublabel,
          ),
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _Clr.card,
        ),
      ),
    );
  }
}

//  ACTION ROW  (Save | Request Pro Test)
class _ActionRow extends StatelessWidget {
  final bool saving, sending;
  final VoidCallback onSave, onRequestPro;

  const _ActionRow({
    required this.saving,
    required this.sending,
    required this.onSave,
    required this.onRequestPro,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Save button — outlined style
        Expanded(
          child: GestureDetector(
            onTap: saving ? null : onSave,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 52,
              decoration: BoxDecoration(
                color: _Clr.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _Clr.primary, width: 1.6),
                boxShadow: [
                  BoxShadow(
                      color: _Clr.primary.withOpacity(0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (saving)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(_Clr.primary)),
                    )
                  else
                    const Icon(Icons.save_rounded,
                        color: _Clr.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    saving ? 'Saving…' : 'Save to DB',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _Clr.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Request Pro — filled gradient
        Expanded(
          child: GestureDetector(
            onTap: sending ? null : onRequestPro,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 52,
              decoration: BoxDecoration(
                gradient: sending
                    ? LinearGradient(colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade300
                ])
                    : const LinearGradient(
                  colors: [Color(0xFF1A6EFF), Color(0xFF0099FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: sending
                    ? []
                    : [
                  BoxShadow(
                    color: _Clr.primary.withOpacity(0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (sending)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  else
                    const Icon(Icons.biotech_rounded,
                        color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    sending ? 'Requesting…' : 'Req. Pro Test',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: sending
                          ? Colors.grey.shade600
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
//  RUN ANOTHER TEST BUTTON
class _RunAnotherBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _RunAnotherBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF2FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _Clr.border),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, color: _Clr.sublabel, size: 18),
            SizedBox(width: 8),
            Text(
              'Run Another Test',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _Clr.sublabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  SECTION LABEL  — same as StartTestScreen
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

//  IMAGE BADGE  (overlay label on merged preview)
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
          BoxShadow(color: color.withOpacity(0.40), blurRadius: 8)
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
//  GLASS ICON BUTTON  (AppBar)  — same as StartTestScreen

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