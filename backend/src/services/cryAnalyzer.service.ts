import OpenAI from 'openai';
import { getSupabase, AUDIO_BUCKET } from '../lib/supabase';

export type CryLabelStr = 'hungry' | 'tired' | 'pain' | 'burping' | 'discomfort';

export interface CryAnalysisResult {
  label: CryLabelStr;
  confidence: number;
  notes: string;
}

const VALID_LABELS: CryLabelStr[] = ['hungry', 'tired', 'pain', 'burping', 'discomfort'];
type CueScores = Record<CryLabelStr, number>;

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

const CLASSIFY_PROMPT = `You are an expert baby cry analyser with 20 years of experience.

You will be given a Whisper transcription of a baby cry recording. Whisper captures acoustic sounds, not just speech - it may output things like "[baby crying]", "[wailing]", "[whimpering]", "[screaming]", "[fussing]", "[hiccuping]", or describe the rhythm and intensity of the cry.

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
  "label": "<hungry|tired|pain|burping|discomfort>",
  "confidence": <0.0 to 1.0>,
  "notes": "<1-2 sentences: what acoustic cues led to this classification and what the parent should do>"
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

  try {
    const file = new File([audioBuffer], filename, { type: mime });
    const transcription = await openai.audio.transcriptions.create({
      model: 'whisper-1',
      file,
      response_format: 'verbose_json',
      prompt: 'This is an infant cry recording. If there is no speech, return a short literal sound description using cue words like [rhythmic], [whimpering], [hiccuping], [high-pitched screaming], [intermittent], [continuous], [nasal], [fading], or [escalating]. Avoid generic outputs like "baby crying" when more acoustic detail is present.',
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

    console.log(`[CryAnalyzer] Whisper transcript: "${text}"`);
    return text || '[baby crying]';
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.warn(`[CryAnalyzer] Whisper failed: ${msg}`);
    return '[baby crying]';
  }
}

async function classifyWithOpenAI(transcript: string, durationSec: number): Promise<CryAnalysisResult> {
  const openai = getOpenAIClient();
  const heuristicScores = scoreCryTranscript(transcript);
  const userMessage = `Whisper transcription of a ${durationSec}-second baby cry recording: "${transcript}"

Heuristic acoustic cue scores from the transcript:
- hungry: ${heuristicScores.hungry.toFixed(1)}
- tired: ${heuristicScores.tired.toFixed(1)}
- pain: ${heuristicScores.pain.toFixed(1)}
- burping: ${heuristicScores.burping.toFixed(1)}
- discomfort: ${heuristicScores.discomfort.toFixed(1)}

Classify why this baby is crying.`;

  const completion = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: CLASSIFY_PROMPT },
      { role: 'user', content: userMessage },
    ],
    temperature: 0.3,
    max_tokens: 200,
  });

  const raw = completion.choices[0]?.message?.content?.trim() ?? '';
  const jsonStr = raw.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '').trim();

  let parsed: { label: string; confidence: number; notes: string };
  try {
    parsed = JSON.parse(jsonStr);
  } catch {
    throw new Error(`OpenAI returned non-JSON: ${raw.slice(0, 200)}`);
  }

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
  const transcript = await transcribeWithWhisper(audioBuffer, ext);

  return classifyWithOpenAI(transcript, durationSec ?? 5);
}
