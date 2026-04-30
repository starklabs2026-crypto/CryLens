import OpenAI from 'openai';
import { getSupabase, AUDIO_BUCKET } from '../lib/supabase';

export type CryLabelStr = 'hungry' | 'tired' | 'pain' | 'burping' | 'discomfort';

export interface CryAnalysisResult {
  label: CryLabelStr;
  confidence: number;
  notes: string;
}

export class NonBabyCryAudioError extends Error {
  constructor(message = 'The uploaded audio does not appear to contain a baby crying.') {
    super(message);
    this.name = 'NonBabyCryAudioError';
  }
}

const VALID_LABELS: CryLabelStr[] = ['hungry', 'tired', 'pain', 'burping', 'discomfort'];
const DIRECT_AUDIO_FORMATS = new Set(['wav', 'mp3']);
type CueScores = Record<CryLabelStr, number>;
export type ClassificationPayload = {
  is_baby_cry?: boolean;
  isBabyCry?: boolean;
  label?: string | null;
  confidence?: number;
  notes?: string;
  rejection_reason?: string;
  rejectionReason?: string;
};

const LOW_SIGNAL_PATTERNS = [
  /^\[?(baby )?cry(?:ing)?\]?$/i,
  /^\[?(baby )?wail(?:ing)?\]?$/i,
  /^\[?(baby )?fuss(?:ing)?\]?$/i,
];

const LABEL_NORMALIZERS: Array<{ label: CryLabelStr; patterns: RegExp[] }> = [
  {
    label: 'burping',
    patterns: [/\bburp(?:ing)?\b/i, /\bgas(?:sy)?\b/i, /\bhiccup(?:ing)?\b/i, /\btrapped gas\b/i],
  },
  {
    label: 'pain',
    patterns: [/\bpain(?:ful)?\b/i, /\bhurt(?:ing)?\b/i, /\bsharp\b/i, /\bhigh[- ]pitched\b/i, /\bscream(?:ing)?\b/i],
  },
  {
    label: 'tired',
    patterns: [/\btired\b/i, /\bsleepy\b/i, /\boverstimulated\b/i, /\byawn(?:ing)?\b/i, /\bwhimper(?:ing)?\b/i],
  },
  {
    label: 'hungry',
    patterns: [/\bhungr(?:y|ier)\b/i, /\bfeeding?\b/i, /\bmilk\b/i, /\bneh\b/i, /\brooting\b/i],
  },
  {
    label: 'discomfort',
    patterns: [/\bdiscomfort\b/i, /\buncomfortable\b/i, /\bfuss(?:ing|y)?\b/i, /\bcontinuous\b/i, /\bnasal\b/i],
  },
];

const HEURISTIC_CUES: Array<{ label: CryLabelStr; weight: number; pattern: RegExp }> = [
  { label: 'hungry', weight: 3.2, pattern: /\bneh\b/i },
  { label: 'hungry', weight: 2.4, pattern: /\bhungr(?:y|ier)\b/i },
  { label: 'hungry', weight: 1.8, pattern: /\bfeed(?:ing)?\b/i },
  { label: 'hungry', weight: 1.4, pattern: /\brhythmic\b/i },
  { label: 'hungry', weight: 1.4, pattern: /\brepetitive\b/i },
  { label: 'hungry', weight: 1.2, pattern: /\bbuild(?:ing|s)? gradually\b/i },
  { label: 'hungry', weight: 1.1, pattern: /\bregular pauses?\b/i },
  { label: 'tired', weight: 2.6, pattern: /\btired\b/i },
  { label: 'tired', weight: 2.2, pattern: /\byawn(?:ing)?\b/i },
  { label: 'tired', weight: 2.0, pattern: /\bsleepy\b/i },
  { label: 'tired', weight: 1.6, pattern: /\bwhimper(?:ing)?\b/i },
  { label: 'tired', weight: 1.3, pattern: /\bwhiny\b/i },
  { label: 'tired', weight: 1.2, pattern: /\bfading\b/i },
  { label: 'tired', weight: 1.0, pattern: /\bintermittent\b/i },
  { label: 'pain', weight: 2.8, pattern: /\bpain(?:ful)?\b/i },
  { label: 'pain', weight: 2.6, pattern: /\bscream(?:ing)?\b/i },
  { label: 'pain', weight: 2.4, pattern: /\bshriek(?:ing)?\b/i },
  { label: 'pain', weight: 2.0, pattern: /\bhigh[- ]pitched\b/i },
  { label: 'pain', weight: 1.7, pattern: /\bsharp\b/i },
  { label: 'pain', weight: 1.4, pattern: /\bintense\b/i },
  { label: 'pain', weight: 1.2, pattern: /\bsustained\b/i },
  { label: 'burping', weight: 3.0, pattern: /\bburp(?:ing)?\b/i },
  { label: 'burping', weight: 2.6, pattern: /\bhiccup(?:ing)?\b/i },
  { label: 'burping', weight: 2.1, pattern: /\bgas(?:sy)?\b/i },
  { label: 'burping', weight: 1.8, pattern: /\btrapped gas\b/i },
  { label: 'burping', weight: 1.2, pattern: /\bshort bursts?\b/i },
  { label: 'burping', weight: 1.1, pattern: /\bgrunt(?:ing)?\b/i },
  { label: 'discomfort', weight: 2.1, pattern: /\bdiscomfort\b/i },
  { label: 'discomfort', weight: 1.8, pattern: /\buncomfortable\b/i },
  { label: 'discomfort', weight: 1.6, pattern: /\bfuss(?:ing|y)?\b/i },
  { label: 'discomfort', weight: 1.3, pattern: /\bcontinuous\b/i },
  { label: 'discomfort', weight: 1.2, pattern: /\bdroning\b/i },
  { label: 'discomfort', weight: 1.2, pattern: /\bnasal\b/i },
  { label: 'discomfort', weight: 1.0, pattern: /\bpersistent\b/i },
];

const TRANSCRIPT_CLASSIFY_PROMPT = `You are an expert baby cry analyser with 20 years of experience.

You will be given a Whisper transcription of an uploaded audio recording. Whisper captures acoustic sounds, not just speech - it may output things like "[baby crying]", "[wailing]", "[whimpering]", "[screaming]", "[fussing]", "[hiccuping]", or describe the rhythm and intensity of the cry.

First decide whether the recording actually contains an infant/baby cry. Reject adult speech, older-child speech without crying, music, TV/audio playback, pets, mechanical sounds, silence, white noise, and general environmental noise.

If the recording does not clearly contain a baby cry, set "is_baby_cry" to false, "label" to null, confidence to 0, and explain briefly in "rejection_reason". Do not force random audio into a cry label.

Using the acoustic description and your knowledge of infant cry patterns, classify why the baby is crying.

Discomfort is a fallback bucket, not the default answer. Only choose discomfort when the transcript lacks stronger cues for hungry, tired, pain, or burping. If the signal is ambiguous, lower the confidence instead of reflexively choosing discomfort.

Cry type acoustic signatures:
- hungry: rhythmic, repetitive "neh" pattern, builds gradually, fairly regular pauses, medium pitch
- tired: whiny, intermittent, lower energy, may include yawning sounds, softer and fading
- pain: sudden, sharp, high-pitched screaming, intense and sustained, little pause between cries
- burping: short bursts of crying with hiccup-like pauses, may sound trapped or uncomfortable
- discomfort: continuous, droning, medium pitch, nasal quality - not urgent but persistent

Return ONLY a JSON object - no markdown, no explanation outside the JSON:
{
  "is_baby_cry": <true|false>,
  "label": "<hungry|tired|pain|burping|discomfort>",
  "confidence": <0.0 to 1.0>,
  "notes": "<1-2 sentences: what acoustic cues led to this classification and what the parent should do>",
  "rejection_reason": "<only when is_baby_cry is false>"
}`;

const DIRECT_AUDIO_CLASSIFY_PROMPT = `You are an expert baby cry analyser with 20 years of experience.

You will be given a raw uploaded audio recording. Do not rely on speech words. First decide whether the recording actually contains an infant/baby cry. Reject adult speech, older-child speech without crying, music, TV/audio playback, pets, mechanical sounds, silence, white noise, and general environmental noise.

If the recording does not clearly contain a baby cry, set "is_baby_cry" to false, "label" to null, confidence to 0, and explain briefly in "rejection_reason". Do not force random audio into a cry label.

If the recording does contain a baby cry, classify the most likely reason for the cry using acoustic features such as onset speed, pitch, intensity, cadence, pause length, escalation or fading, and hiccuping / grunting / trapped-gas-like patterns.

Discomfort is a fallback bucket, not the default answer. Only choose discomfort when the cry lacks stronger cues for hungry, tired, pain, or burping. If the signal is ambiguous, lower the confidence instead of defaulting to discomfort.

Cry type acoustic signatures:
- hungry: rhythmic, repetitive, builds gradually, fairly regular pauses, medium pitch
- tired: whiny, intermittent, lower energy, softer and fading, may sound fussier than urgent
- pain: sudden, sharp, high-pitched, intense and sustained, little pause between cries
- burping: short bursts with hiccup-like pauses, grunting, trapped-gas or post-feed discomfort feel
- discomfort: continuous, droning, medium pitch, nasal quality, persistent but not urgent

Return ONLY a JSON object - no markdown, no explanation outside the JSON:
{
  "is_baby_cry": <true|false>,
  "label": "<hungry|tired|pain|burping|discomfort>",
  "confidence": <0.0 to 1.0>,
  "notes": "<1-2 sentences: what acoustic cues led to this classification and what the parent should do>",
  "rejection_reason": "<only when is_baby_cry is false>"
}`;

function getOpenAIClient(): OpenAI {
  const apiKey = process.env.OPENAI_API_KEY?.trim();
  if (!apiKey) throw new Error('OPENAI_API_KEY must be set');
  return new OpenAI({ apiKey });
}

export function normalizeCryLabel(raw: string | null | undefined): CryLabelStr | null {
  const value = String(raw ?? '')
    .trim()
    .toLowerCase()
    .replace(/[_-]+/g, ' ');

  if (!value) return null;
  if (VALID_LABELS.includes(value as CryLabelStr)) return value as CryLabelStr;

  for (const entry of LABEL_NORMALIZERS) {
    if (entry.patterns.some((pattern) => pattern.test(value))) {
      return entry.label;
    }
  }

  return null;
}

export function isLowSignalTranscript(transcript: string): boolean {
  const normalized = transcript
    .trim()
    .toLowerCase()
    .replace(/[^\w\s\[\]]+/g, ' ')
    .replace(/\s+/g, ' ');

  return LOW_SIGNAL_PATTERNS.some((pattern) => pattern.test(normalized));
}

export function scoreCryTranscript(transcript: string): CueScores {
  const scores: CueScores = {
    hungry: 0,
    tired: 0,
    pain: 0,
    burping: 0,
    discomfort: 0,
  };

  for (const cue of HEURISTIC_CUES) {
    if (cue.pattern.test(transcript)) {
      scores[cue.label] += cue.weight;
    }
  }

  return scores;
}

export function pickHeuristicLabel(scores: CueScores): CryLabelStr | null {
  const ranked = [...VALID_LABELS]
    .map((label) => ({ label, score: scores[label] }))
    .sort((a, b) => b.score - a.score);

  const top = ranked[0];
  const second = ranked[1];
  if (!top || top.score < 1.8) return null;
  if (second && top.score - second.score < 0.75) return null;
  return top.label;
}

export function reconcileCryClassification(
  transcript: string,
  result: { label: string | null | undefined; confidence: number; notes: string },
): CryAnalysisResult {
  const heuristicScores = scoreCryTranscript(transcript);
  const heuristicLabel = pickHeuristicLabel(heuristicScores);
  const normalizedLabel = normalizeCryLabel(result.label);
  const lowSignal = isLowSignalTranscript(transcript);

  let finalLabel = normalizedLabel;
  let finalConfidence = Math.min(1, Math.max(0, Number(result.confidence) || 0.7));
  let finalNotes = String(result.notes ?? '').slice(0, 500).trim();

  if (!finalLabel && heuristicLabel) {
    finalLabel = heuristicLabel;
    finalConfidence = Math.max(finalConfidence, 0.72);
  }

  if (heuristicLabel && finalLabel === 'discomfort' && heuristicLabel !== 'discomfort' && !lowSignal) {
    finalLabel = heuristicLabel;
    finalConfidence = Math.max(finalConfidence, 0.74);
    if (finalNotes) {
      finalNotes = `Updated from fallback discomfort based on stronger ${heuristicLabel} acoustic cues. ${finalNotes}`;
    }
  }

  if (!finalLabel) {
    finalLabel = lowSignal ? 'discomfort' : (heuristicLabel ?? 'discomfort');
  }

  if (!finalNotes) {
    finalNotes = lowSignal
      ? 'The recording had limited acoustic detail, so this is a low-confidence best estimate.'
      : `Classification was supported by transcript cues associated with ${finalLabel}.`;
  }

  return {
    label: finalLabel,
    confidence: finalConfidence,
    notes: finalNotes.slice(0, 500),
  };
}

export function shouldUseDirectAudioClassification(ext: string): boolean {
  return DIRECT_AUDIO_FORMATS.has(ext.trim().toLowerCase());
}

function parseClassificationPayload(raw: string): ClassificationPayload {
  const jsonStr = raw.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '').trim();

  try {
    return JSON.parse(jsonStr);
  } catch {
    throw new Error(`OpenAI returned non-JSON: ${raw.slice(0, 200)}`);
  }
}

function babyCryDecision(payload: ClassificationPayload): boolean | null {
  if (typeof payload.is_baby_cry === 'boolean') return payload.is_baby_cry;
  if (typeof payload.isBabyCry === 'boolean') return payload.isBabyCry;
  return null;
}

export function assertBabyCryClassification(payload: ClassificationPayload): void {
  if (babyCryDecision(payload) !== false) return;

  const reason = String(payload.rejection_reason ?? payload.rejectionReason ?? payload.notes ?? '').trim();
  throw new NonBabyCryAudioError(
    reason || 'The uploaded audio does not appear to contain a baby crying. Please record or import a clear baby cry.',
  );
}

function getAssistantText(
  content:
    | string
    | Array<{
        type?: string;
        text?: string;
        refusal?: string;
      }>
    | null
    | undefined,
): string {
  if (typeof content === 'string') return content.trim();
  if (!Array.isArray(content)) return '';

  return content
    .map((part) => {
      if (typeof part?.text === 'string') return part.text;
      if (typeof part?.refusal === 'string') return part.refusal;
      return '';
    })
    .join('\n')
    .trim();
}

async function transcribeWithWhisper(audioBuffer: Buffer, ext: string): Promise<string> {
  const openai = getOpenAIClient();
  const mimeMap: Record<string, string> = {
    wav: 'audio/wav',
    m4a: 'audio/mp4',
    mp4: 'audio/mp4',
    mp3: 'audio/mpeg',
    ogg: 'audio/ogg',
    webm: 'audio/webm',
    aac: 'audio/aac',
  };
  const mime = mimeMap[ext] ?? 'audio/wav';
  const filename = `cry.${ext || 'wav'}`;
  const models = [
    ...new Set(
      [process.env.OPENAI_TRANSCRIBE_MODEL?.trim(), 'gpt-4o-mini-transcribe', 'whisper-1'].filter(
        (value): value is string => Boolean(value),
      ),
    ),
  ];

  for (const model of models) {
    try {
      const file = new File([audioBuffer], filename, { type: mime });
      const transcription = await openai.audio.transcriptions.create({
        model,
        file,
        response_format: 'verbose_json',
        prompt: 'Describe the uploaded audio literally. If it contains a baby crying, use cue words like [baby crying], [rhythmic], [whimpering], [hiccuping], [high-pitched screaming], [intermittent], [continuous], [nasal], [fading], or [escalating]. If it is speech, music, silence, pets, TV, or other non-baby-cry audio, describe that instead. Avoid generic outputs when more acoustic detail is present.',
      });

      const verbose = transcription as unknown as {
        text?: string;
        segments?: Array<{ text?: string }>;
      };
      const segmentText = (verbose.segments ?? [])
        .map((segment) => segment.text?.trim())
        .filter((value): value is string => Boolean(value));
      const text = [verbose.text?.trim(), ...segmentText]
        .filter((value, index, all): value is string => Boolean(value) && all.indexOf(value) === index)
        .join(' | ')
        .trim();

      console.log(`[CryAnalyzer] ${model} transcript: "${text}"`);
      return text || '[baby crying]';
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      console.warn(`[CryAnalyzer] ${model} transcription failed: ${msg}`);
    }
  }

  return '[baby crying]';
}

async function classifyAudioDirectly(audioBuffer: Buffer, format: 'wav' | 'mp3', durationSec: number): Promise<CryAnalysisResult> {
  const openai = getOpenAIClient();
  const completion = await openai.chat.completions.create({
    model: process.env.OPENAI_AUDIO_MODEL?.trim() || 'gpt-audio',
    messages: [
      { role: 'system', content: DIRECT_AUDIO_CLASSIFY_PROMPT },
      {
        role: 'user',
        content: [
          {
            type: 'text',
            text: `This is a ${durationSec}-second user-submitted audio recording. First verify it contains a real baby crying. If it does, classify the dominant likely cause of the cry.`,
          },
          {
            type: 'input_audio',
            input_audio: {
              data: audioBuffer.toString('base64'),
              format,
            },
          },
        ],
      },
    ],
    temperature: 0.2,
    max_tokens: 220,
  });

  const raw = getAssistantText(completion.choices[0]?.message?.content);
  if (!raw) {
    throw new Error('OpenAI returned an empty response for direct audio classification');
  }

  const parsed = parseClassificationPayload(raw);
  assertBabyCryClassification(parsed);

  const normalized = normalizeCryLabel(parsed.label);
  if (!normalized) {
    throw new Error(`Unknown label from OpenAI audio model: ${parsed.label}`);
  }

  return {
    label: normalized,
    confidence: Math.min(1, Math.max(0, Number(parsed.confidence) || 0.7)),
    notes: String(parsed.notes ?? '').slice(0, 500).trim() || 'Classified from direct cry audio features.',
  };
}

async function classifyTranscriptWithOpenAI(transcript: string, durationSec: number): Promise<CryAnalysisResult> {
  const openai = getOpenAIClient();
  const heuristicScores = scoreCryTranscript(transcript);
  const userMessage = `Whisper transcription of a ${durationSec}-second user-submitted audio recording: "${transcript}"

Heuristic acoustic cue scores from the transcript:
- hungry: ${heuristicScores.hungry.toFixed(1)}
- tired: ${heuristicScores.tired.toFixed(1)}
- pain: ${heuristicScores.pain.toFixed(1)}
- burping: ${heuristicScores.burping.toFixed(1)}
- discomfort: ${heuristicScores.discomfort.toFixed(1)}

First verify the transcript indicates a real baby crying. If it does, classify why this baby is crying.`;

  const completion = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: TRANSCRIPT_CLASSIFY_PROMPT },
      { role: 'user', content: userMessage },
    ],
    temperature: 0.3,
    max_tokens: 200,
  });

  const raw = getAssistantText(completion.choices[0]?.message?.content) ?? '';
  const parsed = parseClassificationPayload(raw);
  assertBabyCryClassification(parsed);

  const normalized = normalizeCryLabel(parsed.label);
  if (!normalized && !pickHeuristicLabel(heuristicScores)) {
    throw new Error(`Unknown label from OpenAI: ${parsed.label}`);
  }

  return reconcileCryClassification(transcript, {
    label: normalized,
    confidence: Number(parsed.confidence) || 0.7,
    notes: String(parsed.notes ?? ''),
  });
}

export async function analyzeCryAudio(audioStoragePath: string, durationSec?: number): Promise<CryAnalysisResult> {
  const { data: signedData, error: signedError } = await getSupabase().storage
    .from(AUDIO_BUCKET)
    .createSignedUrl(audioStoragePath, 120);

  if (signedError || !signedData?.signedUrl) {
    throw new Error('Failed to create signed URL for audio file');
  }

  const response = await fetch(signedData.signedUrl);
  if (!response.ok) {
    throw new Error(`Failed to download audio: ${response.status}`);
  }

  const arrayBuffer = await response.arrayBuffer();
  const audioBuffer = Buffer.from(arrayBuffer);
  const ext = audioStoragePath.split('.').pop()?.toLowerCase() ?? '';
  if (shouldUseDirectAudioClassification(ext)) {
    try {
      console.log(`[CryAnalyzer] Using direct audio classification for .${ext} input`);
      return await classifyAudioDirectly(audioBuffer, ext as 'wav' | 'mp3', durationSec ?? 5);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      console.warn(`[CryAnalyzer] Direct audio classification failed, falling back to transcription: ${msg}`);
    }
  }

  const transcript = await transcribeWithWhisper(audioBuffer, ext);
  return classifyTranscriptWithOpenAI(transcript, durationSec ?? 5);
}
