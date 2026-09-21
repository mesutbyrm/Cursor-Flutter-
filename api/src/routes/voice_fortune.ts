import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import multer from 'multer';
import requireAuth from '../middleware/requireAuth';

const router = Router();
const prisma = new PrismaClient();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 25 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('audio/')) {
      cb(null, true);
    } else {
      cb(new Error('Only audio files are allowed'));
    }
  },
});

interface VoiceFortuneResponse {
  ok: boolean;
  data?: any;
  error?: string;
}

class VoiceFortuneService {
  async uploadAudio(
    userId: string,
    file: Express.Multer.File,
  ): Promise<{
    voiceFortuneId: string;
    duration: number;
    audioUrl: string;
  }> {
    const audioUrl = `https://storage.example.com/voice/${Date.now()}_${file.originalname}`;

    const voiceFortune = await prisma.voiceFortune.create({
      data: {
        userId,
        audioUrl,
        duration: 0,
        processingStatus: 'pending',
        metadata: {
          originalName: file.originalname,
          mimeType: file.mimetype,
          size: file.size,
        },
      },
    });

    const processingJob = await prisma.voiceProcessingJob.create({
      data: {
        voiceFortuneId: voiceFortune.id,
        status: 'queued',
        provider: 'openai',
      },
    });

    return {
      voiceFortuneId: voiceFortune.id,
      duration: 0,
      audioUrl,
    };
  }

  async transcribeAudio(voiceFortuneId: string): Promise<string> {
    const openaiApiKey = process.env.OPENAI_API_KEY;
    if (!openaiApiKey) {
      throw new Error('OpenAI API key not configured');
    }

    const voiceFortune = await prisma.voiceFortune.findUnique({
      where: { id: voiceFortuneId },
    });

    if (!voiceFortune) {
      throw new Error('Voice fortune not found');
    }

    try {
      const processingJob = await prisma.voiceProcessingJob.findUnique({
        where: { voiceFortuneId },
      });

      if (!processingJob) {
        throw new Error('Processing job not found');
      }

      const mockTranscription =
        'Bu ses kaydında fal okuma işlemi yer almaktadır. AI modeli sesi analiz ederek uygun bir fal çıktısı sunacaktır.';

      const updated = await prisma.voiceFortune.update({
        where: { id: voiceFortuneId },
        data: {
          transcription: mockTranscription,
          processingStatus: 'completed',
          processedAt: new Date(),
        },
      });

      await prisma.voiceProcessingJob.update({
        where: { id: processingJob.id },
        data: {
          status: 'completed',
          progress: 100,
          completedAt: new Date(),
        },
      });

      return mockTranscription;
    } catch (error: any) {
      await prisma.voiceProcessingJob.update({
        where: { voiceFortuneId },
        data: {
          status: 'failed',
          error: error.message,
        },
      });

      throw error;
    }
  }

  async generateFortuneFromVoice(voiceFortuneId: string) {
    const voiceFortune = await prisma.voiceFortune.findUnique({
      where: { id: voiceFortuneId },
      include: { user: true },
    });

    if (!voiceFortune) {
      throw new Error('Voice fortune not found');
    }

    if (!voiceFortune.transcription) {
      throw new Error('Transcription not available');
    }

    const fortuneText = `Sesli Fal Okuması

Transkripsiyon: ${voiceFortune.transcription}

Yapay Zeka Tarafından Üretilen Fal:
Bu fal, ses kaydınız ve içerdiği enerji analizine dayanarak oluşturulmuştur. Şu anda dikkat etmeniz gereken noktalar:

1. Açık Bakış: Geleceğe umutla bakın, fırsatları değerlendirin
2. İç Huzur: Kendi sesine kulak ver, içsel rehberliğe güven
3. Yeni Başlangıçlar: Yakında önemli değişikliklerin işaretleri

Şanslı Sayı: ${Math.floor(Math.random() * 100)}
Şanslı Renk: Turkuaz`;

    const fortune = await prisma.userFortune.create({
      data: {
        userId: voiceFortune.userId,
        type: 'voice',
        fortuneText,
        answer: fortuneText.substring(0, 100),
      },
    });

    await prisma.voiceFortune.update({
      where: { id: voiceFortuneId },
      data: { fortuneId: fortune.id },
    });

    return fortune;
  }

  async getVoiceFortunes(userId: string, limit: number = 20, offset: number = 0) {
    return prisma.voiceFortune.findMany({
      where: { userId },
      include: { fortune: true },
      take: limit,
      skip: offset,
      orderBy: { createdAt: 'desc' },
    });
  }

  async getVoiceFortuneDetail(voiceFortuneId: string) {
    return prisma.voiceFortune.findUnique({
      where: { id: voiceFortuneId },
      include: { fortune: true },
    });
  }

  async deleteVoiceFortune(voiceFortuneId: string) {
    await prisma.voiceProcessingJob.deleteMany({
      where: { voiceFortuneId },
    });

    return prisma.voiceFortune.delete({
      where: { id: voiceFortuneId },
    });
  }

  async getProcessingStatus(voiceFortuneId: string) {
    return prisma.voiceProcessingJob.findUnique({
      where: { voiceFortuneId },
    });
  }
}

const service = new VoiceFortuneService();

router.post('/upload', requireAuth, upload.single('audio'), async (req, res) => {
  try {
    const userId = req.userId!;

    if (!req.file) {
      return res.status(400).json({
        ok: false,
        error: 'No audio file provided',
      } as VoiceFortuneResponse);
    }

    const { voiceFortuneId, audioUrl, duration } = await service.uploadAudio(
      userId,
      req.file,
    );

    res.json({
      ok: true,
      data: { voiceFortuneId, audioUrl, duration },
    } as VoiceFortuneResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as VoiceFortuneResponse);
  }
});

router.post('/:id/transcribe', requireAuth, async (req, res) => {
  try {
    const voiceFortuneId = req.params.id;

    const transcription = await service.transcribeAudio(voiceFortuneId);

    res.json({
      ok: true,
      data: { transcription },
    } as VoiceFortuneResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as VoiceFortuneResponse);
  }
});

router.post('/:id/generate-fortune', requireAuth, async (req, res) => {
  try {
    const voiceFortuneId = req.params.id;

    const fortune = await service.generateFortuneFromVoice(voiceFortuneId);

    res.json({
      ok: true,
      data: fortune,
    } as VoiceFortuneResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as VoiceFortuneResponse);
  }
});

router.get('/', requireAuth, async (req, res) => {
  try {
    const userId = req.userId!;
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = parseInt(req.query.offset as string) || 0;

    const voiceFortunes = await service.getVoiceFortunes(userId, limit, offset);

    res.json({
      ok: true,
      data: { voiceFortunes },
    } as VoiceFortuneResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as VoiceFortuneResponse);
  }
});

router.get('/:id', requireAuth, async (req, res) => {
  try {
    const voiceFortune = await service.getVoiceFortuneDetail(req.params.id);

    if (!voiceFortune) {
      return res.status(404).json({
        ok: false,
        error: 'Voice fortune not found',
      } as VoiceFortuneResponse);
    }

    res.json({
      ok: true,
      data: voiceFortune,
    } as VoiceFortuneResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as VoiceFortuneResponse);
  }
});

router.get('/:id/status', requireAuth, async (req, res) => {
  try {
    const status = await service.getProcessingStatus(req.params.id);

    res.json({
      ok: true,
      data: status,
    } as VoiceFortuneResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as VoiceFortuneResponse);
  }
});

router.delete('/:id', requireAuth, async (req, res) => {
  try {
    await service.deleteVoiceFortune(req.params.id);

    res.json({
      ok: true,
      data: { id: req.params.id },
    } as VoiceFortuneResponse);
  } catch (error: any) {
    res.status(500).json({
      ok: false,
      error: error.message,
    } as VoiceFortuneResponse);
  }
});

export default router;
