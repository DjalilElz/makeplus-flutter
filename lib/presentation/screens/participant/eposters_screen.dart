// lib/presentation/screens/participant/eposters_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../data/models/eposter_gallery_item.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/eposter_service.dart';
import '../../../logic/authentication/auth_bloc.dart';

class EpostersScreen extends StatefulWidget {
  const EpostersScreen({super.key});

  @override
  State<EpostersScreen> createState() => _EpostersScreenState();
}

class _EpostersScreenState extends State<EpostersScreen> {
  late final EposterService _eposterService;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<EposterGalleryItem>? _items;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _eposterService = EposterService(ApiClient());
    _loadGallery();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGallery({String? query}) async {
    final event = context.read<AuthBloc>().state.event;
    if (event == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _eposterService.getGallery(eventId: event.id, query: query);
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger la galerie des E-Posters.';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadGallery(query: value.trim());
    });
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir le PDF'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('E-Posters'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher par titre ou auteur...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surfaceContainer(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildMessage(
        context,
        icon: Icons.error_outline,
        title: 'Erreur',
        message: _error!,
        action: TextButton(
          onPressed: () => _loadGallery(query: _searchController.text.trim()),
          child: const Text('Réessayer'),
        ),
      );
    }
    final items = _items ?? [];
    if (items.isEmpty) {
      return _buildMessage(
        context,
        icon: Icons.article_outlined,
        title: _searchController.text.trim().isEmpty
            ? 'Aucun E-Poster pour le moment'
            : 'Aucun résultat',
        message: _searchController.text.trim().isEmpty
            ? 'Les E-Posters acceptés apparaîtront ici une fois publiés.'
            : 'Essayez un autre titre ou nom d\'auteur.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadGallery(query: _searchController.text.trim()),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _EposterCard(
              item: items[index],
              onOpenPdf: _openPdf,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint(context)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textHint(context),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

// A single E-Poster card in the gallery grid -- mirrors the web gallery's
// card design: a colored header bar with the contribution number, a serif
// italic title, the author with a person icon, the submission date, and a
// "Voir le PDF" button. No thumbnail/image, since none exists server-side.
class _EposterCard extends StatelessWidget {
  final EposterGalleryItem item;
  final ValueChanged<String> onOpenPdf;

  const _EposterCard({required this.item, required this.onOpenPdf});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar with contribution number.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.eventPrimary(context),
            child: Text(
              item.contributionNumber ?? '—',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary(context)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.authors,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('dd/MM/yyyy').format(item.submittedAt),
                    style: TextStyle(fontSize: 11, color: AppColors.textHint(context)),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: item.pdfUrl != null ? () => onOpenPdf(item.pdfUrl!) : null,
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 15),
                      label: const Text('Voir le PDF', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.eventPrimary(context),
                        side: BorderSide(color: AppColors.eventPrimary(context)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
