/// File kind labels (website `data/kinds.js`).
const kindLabels = {
  'document': 'Document',
  'image': 'Image',
  'media': 'Audio or video',
  'data': 'Data',
  'link': 'Link',
};

String kindLabel(String kind) => kindLabels[kind] ?? 'File';
