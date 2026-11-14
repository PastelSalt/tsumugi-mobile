/// Legal documents (website `pages/legal/legalMeta.js`). The policies are drafts: they show a
/// draft banner and are not presented as final. Switch to published only after owner and legal review.
class LegalInfo {
  const LegalInfo({
    required this.slug,
    required this.label,
    required this.title,
    required this.description,
    required this.version,
  });

  final String slug;
  final String label;
  final String title;
  final String description;
  final String version;
}

const legalIsDraft = true;

const legalDocuments = {
  'privacy-policy': LegalInfo(
    slug: 'privacy-policy',
    label: 'Privacy Policy / Privacy Notice',
    title: 'A clear thread for your information.',
    description: 'How Moeko Works plans to handle information when you visit or use Tsumugi.',
    version: '0.1 (draft)',
  ),
  'terms-of-service': LegalInfo(
    slug: 'terms-of-service',
    label: 'Terms of Service / Terms and Conditions',
    title: 'The shared rules for making together.',
    description: 'The planned terms for using Tsumugi and protecting the work brought into it.',
    version: '0.1 (draft)',
  ),
  'cookie-and-local-storage-policy': LegalInfo(
    slug: 'cookie-and-local-storage-policy',
    label: 'Cookie & Local Storage Policy',
    title: 'A thoughtful approach to browser storage.',
    description: 'How Tsumugi may use cookies, local storage, session storage, and similar browser technologies.',
    version: '0.1 (draft)',
  ),
};

/// Short names for links to the legal pages.
const legalLinks = [
  ('privacy-policy', 'Privacy Policy'),
  ('terms-of-service', 'Terms of Service'),
  ('cookie-and-local-storage-policy', 'Cookie & Local Storage Policy'),
];

/// Everything the app writes to device storage. The mobile demo stores nothing, so this is empty.
/// Update it in the same change as any feature that persists data.
const storageInventory = <String>[];
