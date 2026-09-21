import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { Dio } from 'dio';
import requireAuth from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

interface AICopilotRequest {
  prompt: string;
  fortuneId?: string;
  analysisType?: string;
  context?: Record<string, any>;
}

interface AICopilotResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

class AICopilotService {
  async generateSuggestion(
    userId: string,
    req: AICopilotRequest,
  ): Promise<{
    suggestion: string;
    confidenceScore: number;
    analysisType: string;
  }> {
    const openaiApiKey = process.env.OPENAI_API_KEY;
    if (!openaiApiKey) {
      throw new Error('OpenAI API key not configured');
    }

    const systemPrompt = `You are an expert fortune teller AI assistant.
    Provide insights and suggestions based on the user's question or fortune reading.
    Be encouraging, thoughtful, and provide actionable recommendations.
    Respond in Turkish language.`;

    const userPrompt = `${req.prompt}
    Analysis Type: ${req.analysisType || 'general'}
    ${req.context ? `Context: ${JSON.stringify(req.context)}` : ''}`;

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${openaiApiKey}`,
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        temperature: 0.7,
        max_tokens: 1000,
      }),
    });

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.statusText}`);
    }

    const data = (await response.json()) as {
      choices: Array<{ message: { content: string } }>;
    };
    const suggestion = data.choices[0].message.content;

    const confidenceScore = Math.min(
      0.95,
      Math.random() * 0.3 + 0.7,
    );

    return {
      suggestion,
      confidenceScore,
      analysisType: req.analysisType || 'general',
    };
  }

  async getSuggestions(userId: string, limit: number = 10, offset: number = 0) {
    return prisma.aICopilot.findMany({
      where: { userId },
      take: limit,
      skip: offset,
      orderBy: { createdAt: 'desc' },
      include: { fortune: true },
    });
  }

  async rateSuggestion(copilotId: string, rating: number) {
    return prisma.aICopilot.update({
      where: { id: copilotId },
      data: { rating },
    });
  }

  async deleteSuggestion(copilotId: string) {
    await prisma.aICopilotHistory.deleteMany({
      where: { copilotId },
    });
    return prisma.aICopilot.delete({
      where: { id: copilotId },
    });
  }

  async getSuggestionHistory(copilotId: string) {
    return prisma.aICopilotHistory.findMany({
      where: { copilotId },
      orderBy: { timestamp: 'desc' },
    });
  }
}

const service = new AICopilotService();

router.post('/suggestions', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const { prompt, fortuneId, analysisType, context } = req.body as AICopilotRequest;

    if (!prompt) {
      return res.status(400).json({
        ok: false,
        error: 'Prompt is required',
      } as AICopilotResponse);
    }

    const { suggestion, confidenceScore, analysisType: finalType } =
      await service.generateSuggestion(userId, {
        prompt,
        fortuneId,
        analysisType,
        context,
      });

    const copilot = await prisma.aICopilot.create({
      data: {
        userId,
        fortuneId,
        prompt,
        suggestion,
        confidenceScore,
        analysisType: finalType,
        context,
      },
      include: { fortune: true },
    });

    res.json({
      ok: true,
      data: copilot,
    } as AICopilotResponse);
  } catch (error: any) {
    console.error('AI Copilot error:', error);
    res.status(500).json({
      ok: false,
      error: error.message || 'Failed to generate suggestion',
    } as AICopilotResponse);
  }
});

router.get('/suggestions', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const limit = parseInt(req.query.limit as string) || 10;
    const offset = parseInt(req.query.offset as string) || 0;

    const suggestions = await service.getSuggestions(userId, limit, offset);

    res.json({
      ok: true,
      data: { suggestions },
    } as AICopilotResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AICopilotResponse);
  }
});

router.put('/suggestions/:id/rating', requireAuth, async (req, res) => {
  try {
    const { rating } = req.body as { rating: number };

    if (rating < 0 || rating > 5) {
      return res.status(400).json({
        ok: false,
        error: 'Rating must be between 0 and 5',
      } as AICopilotResponse);
    }

    const copilot = await service.rateSuggestion(req.params.id, rating);

    res.json({
      ok: true,
      data: copilot,
    } as AICopilotResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AICopilotResponse);
  }
});

router.delete('/suggestions/:id', requireAuth, async (req, res) => {
  try {
    await service.deleteSuggestion(req.params.id);

    res.json({
      ok: true,
      data: { id: req.params.id },
    } as AICopilotResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AICopilotResponse);
  }
});

router.get('/suggestions/:id/history', requireAuth, async (req, res) => {
  try {
    const history = await service.getSuggestionHistory(req.params.id);

    res.json({
      ok: true,
      data: { history },
    } as AICopilotResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as AICopilotResponse);
  }
});

export default router;
