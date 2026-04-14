import { GoogleGenerativeAI } from '@google/generative-ai';

function createGeminiFlash() {
  const apiKey = process.env.GEMINI_API_KEY?.trim();
  if (!apiKey) throw new Error('GEMINI_API_KEY must be set');

  const genAI = new GoogleGenerativeAI(apiKey);
  return genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
}

let geminiFlash: ReturnType<typeof createGeminiFlash> | null = null;

export function isGeminiConfigured(): boolean {
  return Boolean(process.env.GEMINI_API_KEY?.trim());
}

export function getGeminiFlash() {
  if (!geminiFlash) {
    geminiFlash = createGeminiFlash();
  }

  return geminiFlash;
}
