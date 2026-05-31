enum IngestionStage {
  fileSelected('file-selected'),
  extracting('extracting'),
  assembling('assembling'),
  writing('writing'),
  needsAiProcessing('needs-ai-processing'),
  complete('complete'),
  error('error');

  const IngestionStage(this.wireValue);

  final String wireValue;
}
