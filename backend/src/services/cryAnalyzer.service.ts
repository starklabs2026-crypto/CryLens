import OpenAI from 'openai';
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

const CLASSIFY_PROMPT = `You are an expert baby cry analyser with 20 years of experience.

You will be given a Whisper transcription of a baby cry recording. Whisper captures acoustic sounds, not just speech — it may output things like "[baby crying]", "[wailing]", "[whimpering]", "[screaming]", "[fussing]", "[hiccuping]", or describe the rhythm and intensity of the cry.

Using the acoustic description and your knowledge of infant cry patterns, classify why the baby is crying.

Cry type acoustic signatures:
- hungry: rhythmic, repetitive "neh" pattern, builds gradually, fairly regular pauses, medium pitch
- tired: whiny, intermittent, lower energy, may include yawning sounds, softer and fading
- pain: sudden, sharp, high-pitched screaming, intense and sustained, little pause between cries
- burping: short bursts of crying with hiccup-like pauses, may sound trapped or uncomfortable
- discomfort: continuous, droning, medium pitch, nasal quality — not urgent but persistent

Return ONLY a JSON object — no markdown, no explanation outside the JSON:
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

async function transcribeWithHuggingFace(audioBuffer: Buffer, mimeType: string): Promise<string> {
  const hfToken = process.env.HUGGINGFACE_API_KEY?.trim();
  const model = 'openai/whisper-large-v3';

  const headers: Record<string, string> = { 'Content-Type': mimeType };
  if (hfToken) headers['Authorization'] = `Bearer ${hfToken}`;

  const response = await fetch(
    `https://api-inference.huggingface.co/models/${model}`,
    { method: 'POST', headers, body: audioBuffer }
  );

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`HuggingFace transcription failed (${response.status}): ${err.slice(0, 200)}`);
  }

  const result = await response.json() as { text?: string; error?: string };
  if (result.error) throw new Error(`HuggingFace error: ${result.error}`);
  return result.text ?? '[baby crying]';
}

async function classifyWithOpenAI(transcript: string, durationSec: number): Promise<CryAnalysisResult> {
  const openai = getOpenAIClient();

  const userMessage = `Whisper transcription of a ${durationSec}-second baby cry recording: "${transcript}"

Classify why this baby is crying.`;

  const completion = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: CLASSIFY_PROMPT },
      { role: 'user',   content: userMessage },
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

  const label = parsed.label?.toLowerCase() as CryLabelStr;
  if (!VALID_LABELS.includes(label)) {
    throw new Error(`Unknown label from OpenAI: ${parsed.label}`);
  }

  return {
    label,
    confidence: Math.min(1, Math.max(0, Number(parsed.confidence) || 0.7)),
    notes: String(parsed.notes ?? '').slice(0, 500),
  };
}

export async function analyzeCryAudio(audioStoragePath: string, durationSec?: number): Promise<CryAnalysisResult> {
  // 1. Get signed URL for the stored audio
  const { data: signedData, error: signedError } = await supabase.storage
    .from(AUDIO_BUCKET)
    .createSignedUrl(audioStoragePath, 120);

  if (signedError || !signedData?.signedUrl) {
    throw new Error('Failed to create signed URL for audio file');
  }

  // 2. Download audio
  const response = await fetch(signedData.signedUrl);
  if (!response.ok) {
    throw new Error(`Failed to download audio: ${response.status}`);
  }

  const arrayBuffer = await response.arrayBuffer();
  const audioBuffer = Buffer.from(arrayBuffer);

  // 3. Derive MIME type
  const ext = audioStoragePath.split('.').pop()?.toLowerCase() ?? '';
  const mimeType = AUDIO_MIME_TYPES[ext] ?? 'audio/wav';

  // 4. HuggingFace Whisper → transcript
  const transcript = await transcribeWithHuggingFace(audioBuffer, mimeType);
  console.log(`[CryAnalyzer] Whisper transcript: "${transcript}"`);

  // 5. OpenAI gpt-4o-mini → classify + notes
  return classifyWithOpenAI(transcript, durationSec ?? 5);
}
