import {
  isLowSignalTranscript,
  normalizeCryLabel,
  pickHeuristicLabel,
  reconcileCryClassification,
  scoreCryTranscript,
  shouldUseDirectAudioClassification,
} from '../services/cryAnalyzer.service';

describe('cryAnalyzer.service heuristics', () => {
  it('normalizes common synonyms to supported labels', () => {
    expect(normalizeCryLabel('needs burping')).toBe('burping');
    expect(normalizeCryLabel('high-pitched screaming')).toBe('pain');
    expect(normalizeCryLabel('sleepy / overtired')).toBe('tired');
    expect(normalizeCryLabel('feeding cry')).toBe('hungry');
    expect(normalizeCryLabel('uncomfortable fussing')).toBe('discomfort');
  });

  it('treats generic baby crying text as low signal', () => {
    expect(isLowSignalTranscript('[baby crying]')).toBe(true);
    expect(isLowSignalTranscript('baby crying')).toBe(true);
    expect(isLowSignalTranscript('[hiccuping] short bursts of crying')).toBe(false);
  });

  it('picks burping when hiccup-like cues are strongest', () => {
    const scores = scoreCryTranscript('[hiccuping] short bursts, trapped gas, grunting between cries');
    expect(pickHeuristicLabel(scores)).toBe('burping');
  });

  it('uses the direct audio classifier only for wav and mp3 inputs', () => {
    expect(shouldUseDirectAudioClassification('wav')).toBe(true);
    expect(shouldUseDirectAudioClassification('mp3')).toBe(true);
    expect(shouldUseDirectAudioClassification('m4a')).toBe(false);
    expect(shouldUseDirectAudioClassification('aac')).toBe(false);
  });

  it('overrides fallback discomfort when transcript has stronger pain cues', () => {
    const result = reconcileCryClassification(
      '[high-pitched screaming] sudden sharp sustained cry with little pause',
      {
        label: 'discomfort',
        confidence: 0.61,
        notes: 'The cry sounds persistent.',
      },
    );

    expect(result.label).toBe('pain');
    expect(result.confidence).toBeGreaterThanOrEqual(0.74);
  });

  it('keeps discomfort for genuinely low-signal transcripts', () => {
    const result = reconcileCryClassification('[baby crying]', {
      label: 'discomfort',
      confidence: 0.58,
      notes: '',
    });

    expect(result.label).toBe('discomfort');
    expect(result.notes.length).toBeGreaterThan(0);
  });
});
