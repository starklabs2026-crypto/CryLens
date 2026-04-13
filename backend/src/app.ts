import 'dotenv/config';
import express, { Application, Request, Response, NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';

import authRoutes from './routes/auth.routes';
import babyRoutes from './routes/baby.routes';
import analysisRoutes from './routes/analysis.routes';

const app: Application = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

app.get('/health', (_req: Request, res: Response): void => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use('/auth', authRoutes);
app.use('/babies', babyRoutes);
app.use('/analysis', analysisRoutes);

app.use((_req: Request, res: Response): void => {
  res.status(404).json({ error: 'Route not found' });
});

app.use((err: Error, _req: Request, res: Response, _next: NextFunction): void => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

export default app;
