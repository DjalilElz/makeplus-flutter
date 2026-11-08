import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/theme/app_colors.dart';

/// Shows a PDF from a URL inside the app (e.g. an e-poster).
///
/// Handing the URL to another app depended on what the phone has installed
/// (the default PDF app of the test phone answered "Impossible d'afficher le
/// PDF"), and those apps don't get the app's extra trusted root for
/// wemakeplus.com. Downloading here does; "open elsewhere" stays available.
class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerScreen({super.key, required this.url, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _path;
  String? _error;
  int _pages = 0;
  int _page = 0;
  PDFViewController? _controller;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    setState(() {
      _path = null;
      _error = null;
    });
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/pdf_${widget.url.hashCode.toUnsigned(32)}.pdf';
      final file = File(path);
      if (!await file.exists() || await file.length() == 0) {
        // Renamed only when complete: a cut-off download is never reused.
        final partial = '$path.part';
        await Dio().download(widget.url, partial);
        await File(partial).rename(path);
      }
      if (mounted) setState(() => _path = path);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible de charger le PDF.');
      }
    }
  }

  Future<void> _openElsewhere() async {
    final ok = await launchUrl(
      Uri.parse(widget.url),
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune application pour ouvrir ce PDF'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Ouvrir dans une autre application',
            icon: const Icon(Icons.open_in_new),
            onPressed: _openElsewhere,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: AppColors.textHint(context)),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(onPressed: _download, child: const Text('Réessayer')),
              TextButton(
                onPressed: _openElsewhere,
                child: const Text('Ouvrir dans une autre application'),
              ),
            ],
          ),
        ),
      );
    }
    if (_path == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        PDFView(
          key: ValueKey(_path),
          filePath: _path!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          defaultPage: 0,
          onViewCreated: (controller) => _controller = controller,
          onRender: (pages) {
            _controller?.setPage(0);
            if (mounted) setState(() => _pages = pages ?? 0);
          },
          onPageChanged: (page, _) {
            if (mounted && page != null) setState(() => _page = page);
          },
          onError: (_) {
            if (mounted) {
              setState(() => _error = 'Impossible d\'afficher le PDF.');
            }
          },
        ),
        if (_pages > 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_page + 1} / $_pages',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
