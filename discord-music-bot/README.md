# Discord Music Bot Pro (YouTube + SoundCloud)

بوت أغاني احترافي جداً لديسكورد مع **لوحة تحكم ثابتة داخل روم مخصص** + **روم طلبات سريع** + **إدارة قوائم تشغيل (Playlists)** بصلاحيات رول مخصص.

## أهم المزايا

- بانل احترافي بـ Embed يتحدث تلقائياً ويعرض:
  - اسم الأغنية الحالية + الصورة.
  - شريط تقدم (timeline slider style).
  - مستوى الصوت وعدد العناصر في الطابور.
- تحكم مباشر من البانل:
  - Join / Leave
  - Pause / Resume
  - Next (Skip) / Stop
  - Vol+ / Vol-
  - Add Song
- نظام Playlist كامل من البانل:
  - Create Playlist
  - Delete Playlist
  - Add Song to Playlist
  - Remove Song from Playlist
  - List Playlists
  - Play Playlist (Ordered / Shuffle)
- روم طلبات مخصص:
  - أرسل رابط YouTube أو SoundCloud أو اسم الأغنية فقط.
  - البوت يحذف رسالة المستخدم ثم يرسل رسالة بحث احترافية.
- قفل التحكم بالأغنية:
  - فقط الشخص الذي شغّل الأغنية الحالية يقدر Stop / Skip (حسب طلبك).
- إدارة صلاحيات Playlist عبر رول واحد تحدده أنت في `.env`.

## المتطلبات

- Node.js 20+
- صلاحيات البوت:
  - View Channels
  - Send Messages
  - Manage Messages (لحذف رسالة المستخدم في روم الطلبات)
  - Embed Links
  - Connect
  - Speak
  - Use Slash Commands

## التثبيت

```bash
cd discord-music-bot
npm install
cp .env.example .env
```

## الإعدادات

```env
DISCORD_TOKEN=...
DISCORD_CLIENT_ID=...
DISCORD_GUILD_ID=...
MUSIC_PANEL_CHANNEL_ID=...        # روم اللوحة
MUSIC_REQUEST_CHANNEL_ID=...      # روم الطلبات بالرسائل
PLAYLIST_MANAGER_ROLE_ID=...      # الرول المخول لإدارة البلاي ليست
PANEL_REFRESH_SECONDS=15          # تحديث تلقائي للوحة
DEFAULT_VOLUME=0.6
```

## نشر الأوامر

```bash
npm run deploy
```

## التشغيل

```bash
npm start
```

## خطوات الاستخدام السريعة

1. شغل البوت.
2. نفذ `/setup-panel`.
3. ادخل روم صوتي.
4. من روم البانل اضغط **Add Song** أو اكتب في روم الطلبات رابط/اسم أغنية.
5. لإدارة القوائم استخدم قائمة **Playlist Manager** داخل البانل.

## ملاحظات تقنية

- يدعم YouTube و SoundCloud.
- البحث النصي يجرب YouTube ثم SoundCloud.
- القوائم تُحفظ محلياً في: `data/playlists.json`.
- إذا واجهت مشكلة "البوت ما يتكلم":
  - تأكد من صلاحيات `Speak` و `Connect`.
  - تأكد من تثبيت dependencies كاملة (`npm install`).
  - تأكد أنك داخل روم صوتي قبل الطلب.

