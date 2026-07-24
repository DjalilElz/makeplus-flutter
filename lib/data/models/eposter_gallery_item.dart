// lib/data/models/eposter_gallery_item.dart

/// A single accepted E-Poster in the event's public gallery -- mirrors the
/// backend's `/api/eposter/{event_id}/gallery/` endpoint, which returns the
/// same data as the web public_gallery.html page (no thumbnail/image
/// exists server-side, only a PDF).
class EposterGalleryItem {
  final String id;
  final String? contributionNumber;
  final String title;
  final String authors;
  final String coAuthors;
  final DateTime submittedAt;
  final String? pdfUrl;

  const EposterGalleryItem({
    required this.id,
    this.contributionNumber,
    required this.title,
    required this.authors,
    this.coAuthors = '',
    required this.submittedAt,
    this.pdfUrl,
  });

  factory EposterGalleryItem.fromJson(Map<String, dynamic> json) {
    return EposterGalleryItem(
      id: json['id'] as String,
      contributionNumber: json['contribution_number'] as String?,
      title: json['title'] as String? ?? '',
      authors: json['authors'] as String? ?? '',
      coAuthors: json['co_authors'] as String? ?? '',
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      pdfUrl: json['pdf_url'] as String?,
    );
  }
}
