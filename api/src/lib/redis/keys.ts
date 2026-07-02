/** Redis anahtar adlandırma — tek kaynak. */

export const RedisKeys = {
  cache: {
    homeFeed: "cache:home:feed",
    trendVideos: "cache:trend:videos",
    popularFortuneTellers: "cache:fortune:popular",
    gameList: "cache:games:list",
    profile: (userId: string) => `cache:profile:${userId}`,
    aiFortune: (hash: string) => `cache:ai:fortune:${hash}`,
  },
  presence: {
    onlineUsers: "online_users",
    user: (userId: string) => `user:${userId}`,
    roomUsers: (roomId: string) => `room:${roomId}:users`,
  },
  voice: {
    room: (roomId: string) => `room:${roomId}`,
    speakers: (roomId: string) => `room:${roomId}:speakers`,
    admins: (roomId: string) => `room:${roomId}:admins`,
    listeners: (roomId: string) => `room:${roomId}:listeners`,
  },
  music: {
    queue: (roomId: string) => `music_queue:${roomId}`,
  },
  gift: {
    stream: "gift_queue",
    group: "gift_workers",
    consumer: (instanceId: string) => `gift_worker_${instanceId}`,
  },
  shorts: {
    trending: "shorts:trending",
    video: (id: string) => `shorts:video:${id}`,
  },
  live: {
    viewers: (streamId: string) => `live:${streamId}:viewers`,
    likes: (streamId: string) => `live:${streamId}:likes`,
    comments: (streamId: string) => `live:${streamId}:comments`,
    gifts: (streamId: string) => `live:${streamId}:gifts`,
  },
  notify: {
    queue: "notification_queue",
  },
  session: {
    active: (userId: string) => `session:${userId}`,
  },
  rate: {
    login: (key: string) => `rate:login:${key}`,
    message: (key: string) => `rate:message:${key}`,
    gift: (key: string) => `rate:gift:${key}`,
    api: (key: string) => `rate:api:${key}`,
  },
  pubsub: {
    chat: "chat",
    gift: "gift",
    room: "room",
    music: "music",
    notification: "notification",
  },
} as const;

export const RedisTTL = {
  homeFeed: 60,
  trendVideos: 30,
  profile: 300,
  aiFortune: 120,
  gameList: 60,
  presenceHeartbeat: 20,
  session: 3600,
  pkCache: 1800,
} as const;
