import {
  assertBabyCryClassification,
  classifyTranscriptLocally,
  isLowSignalTranscript,
  NonBabyCryAudioError,
  normalizeCryLabel,
  pickHeuristicLabel,
  quickAnalyzeAudioFeatures,
  reconcileCryClassification,
  scoreCryTranscript,
  shouldUseDirectAudioClassification,
  transcriptIndicatesNonBabyAudio,
} from '../services/cryAnalyzer.service';

function makeTestWav(options: {
  seconds?: number;
  amplitude?: number;
  frequencyHz?: number;
  burstMs?: number;
  gapMs?: number;
} = {}): Buffer {
  const sampleRate = 8_000;
  const seconds = options.seconds ?? 4;
  const amplitude = options.amplitude ?? 0.35;
  const frequencyHz = options.frequencyHz ?? 950;
  const burstSamples = Math.floor(sampleRate * ((options.burstMs ?? 350) / 1_000));
  const gapSamples = Math.floor(sampleRate * ((options.gapMs ?? 250) / 1_000));
  const totalSamples = sampleRate * seconds;
  const dataSize = totalSamples * 2;
  const buffer = Buffer.alloc(44 + dataSize);

  buffer.write('RIFF', 0, 'ascii');
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8, 'ascii');
  buffer.write('fmt ', 12, 'ascii');
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(1, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(sampleRate * 2, 28);
  buffer.writeUInt16LE(2, 32);
  buffer.writeUInt16LE(16, 34);
  buffer.write('data', 36, 'ascii');
  buffer.writeUInt32LE(dataSize, 40);

  for (let index = 0; index < totalSamples; index += 1) {
    const cyclePosition = index % Math.max(1, burstSamples + gapSamples);
    const isBurst = cyclePosition < burstSamples;
    const value = isBurst ? Math.sin((2 * Math.PI * frequencyHz * index) / sampleRate) * amplitude : 0;
    buffer.writeInt16LE(Math.max(-32768, Math.min(32767, Math.round(value * 32767))), 44 + index * 2);
  }

  return buffer;
}

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

  it('detects transcript cues that are clearly not baby cries', () => {
    expect(transcriptIndicatesNonBabyAudio('adult speech and music playing in the background')).toBe(true);
    expect(transcriptIndicatesNonBabyAudio('[baby crying] high-pitched screaming')).toBe(false);
  });

  it('classifies transcripts locally without a second LLM pass', () => {
    const result = classifyTranscriptLocally('[hiccuping] short bursts, trapped gas, grunting between cries', 12);
    expect(result.label).toBe('burping');
    expect(result.confidence).toBeGreaterThanOrEqual(0.7);
  });

  it('creates a quick wav feature fallback for active cry-like audio', () => {
    const outcome = quickAnalyzeAudioFeatures(makeTestWav(), 'wav', 10);
    expect(outcome?.kind).toBe('analysis');
    if (outcome?.kind === 'analysis') {
      expect(['hungry', 'tired', 'pain', 'burping', 'discomfort']).toContain(outcome.result.label);
      expect(outcome.result.confidence).toBeLessThanOrEqual(0.68);
    }
  });

  it('rejects quiet wav audio in the quick feature fallback', () => {
    const outcome = quickAnalyzeAudioFeatures(makeTestWav({ amplitude: 0 }), 'wav', 10);
    expect(outcome).toMatchObject({
      kind: 'reject',
    });
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

  it('rejects model payloads that are not baby cries', () => {
    expect(() =>
      assertBabyCryClassification({
        is_baby_cry: false,
        label: null,
        confidence: 0,
        rejection_reason: 'The audio contains adult speech, not a baby cry.',
      }),
    ).toThrow(NonBabyCryAudioError);
  });
});
