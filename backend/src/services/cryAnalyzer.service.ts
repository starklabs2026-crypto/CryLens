import { geminiFlash } from '../lib/gemini';
import { supabase, AUDIO_BUCKET } from '../lib/supabase';

export type CryLabelStr = 'hungry' | 'tired' | 'pain' | 'burping' | 'discomfort';

export interface CryAnalysisResult {
  label: CryLabelStr;
  confidence: number;   // 0–1
  notes: string;
}

const VALID_LABELS: CryLabelStr[] = ['hungry', 'tired', 'pain', 'burping', 'discomfort'];

const AUDIO_MIME_TYPES: Record<string, string> = {
  m4a:  'audio/mp4',
  mp4:  'audio/mp4',
  mp3:  'audio/mpeg',
  wav:  'audio/wav',
  ogg:  'audio/ogg',
  webm: 'audio/webm',
  aac:  'audio/aac',
};

const SYSTEM_PROMPT = `You are an expert baby cry analyser. Listen carefully to the audio and determine why the baby is crying.

Classify the cry as exactly ONE of these labels:
- hungry   : cry when the baby needs to be fed
- tired    : fussing or whimpering when sleepy
- pain     : sharp, intense, high-pitched cries indicating discomfort or pain
- burping  : intermittent cries with pauses, usually after feeding
- discomfort : sustained cries due to environmental discomfort (temperature, wet diaper, etc.)

Return ONLY a JSON object with no markdown, no code fences, exactly this shape:
{
  "label": "<one of the five labels>",
  "confidence": <number between 0.0 and 1.0>,
  "notes": "<one or two sentences explaining the specific acoustic cues that led to this classification>"
}`;

export async function analyzeCryAudio(audioStoragePath: string): Promise<CryAnalysisResult> {
  // 1. Get a short-lived signed URL for the stored audio
  const { data: signedData, error: signedError } = await supabase.storage
    .from(AUDIO_BUCKET)
    .createSignedUrl(audioStoragePath, 120); // 2-minute window

  if (signedError || !signedData?.signedUrl) {
    throw new Error('Failed to create signed URL for audio file');
  }

  // 2. Download audio bytes
  const response = await fetch(signedData.signedUrl);
  if (!response.ok) {
    throw new Error(`Failed to download audio: ${response.status} ${response.statusText}`);
  }

  const arrayBuffer = await response.arrayBuffer();
  const base64Audio = Buffer.from(arrayBuffer).toString('base64');

  // 3. Derive MIME type from file extension
  const ext = audioStoragePath.split('.').pop()?.toLowerCase() ?? '';
  const mimeType = AUDIO_MIME_TYPES[ext] ?? 'audio/mp4';

  // 4. Send to Gemini 2.0 Flash
  const result = await geminiFlash.generateContent([
    SYSTEM_PROMPT,
    {
      inlineData: {
        mimeType,
        data: base64Audio,
      },
    },
  ]);

  const raw = result.response.text().trim();

  // 5. Strip accidental markdown fences if model adds them
  const jsonStr = raw.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '').trim();

  let parsed: { label: string; confidence: number; notes: string };
  try {
    parsed = JSON.parse(jsonStr);
  } catch {
    throw new Error(`Gemini returned non-JSON response: ${raw.slice(0, 200)}`);
  }

  const label = parsed.label?.toLowerCase() as CryLabelStr;
  if (!VALID_LABELS.includes(label)) {
    throw new Error(`Gemini returned unknown label: ${parsed.label}`);
  }

  const confidence = Math.min(1, Math.max(0, Number(parsed.confidence) || 0));
  const notes = String(parsed.notes ?? '').slice(0, 500);

  return { label, confidence, notes };
}
