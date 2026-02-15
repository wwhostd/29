# Discord Music Bot Pro (Arabic Friendly)

بوت ديسكورد احترافي لتشغيل الأغاني من YouTube باستخدام **Slash Commands** مع نظام Queue كامل وواجهة Embed جميلة.

## المميزات

- تشغيل بالبحث أو بالرابط (`/play`).
- Queue احترافي مع عرض الأغنية الحالية والقادمة.
- أوامر تشغيل أساسية: إيقاف مؤقت، استكمال، تخطي، إيقاف كامل.
- التحكم بالصوت (`/volume`) من 0% إلى 200%.
- تفعيل/إلغاء التكرار (`/loop`).
- فصل البوت من القناة (`/disconnect`).
- رسائل واضحة ومرتبة باستخدام Discord Embeds.

## المتطلبات

- Node.js 20 أو أحدث.
- Discord Bot Token + Application Client ID.
- إعطاء البوت الصلاحيات التالية على السيرفر:
  - View Channels
  - Connect
  - Speak
  - Use Slash Commands

## التثبيت

```bash
cd discord-music-bot
npm install
cp .env.example .env
```

ثم عدّل ملف `.env`:

```env
DISCORD_TOKEN=...
DISCORD_CLIENT_ID=...
DISCORD_GUILD_ID=... # اختياري لتحديث الأوامر فوراً على سيرفر محدد
DEFAULT_VOLUME=0.6
```

## نشر أوامر السلاش

```bash
npm run deploy
```

> إذا وضعت `DISCORD_GUILD_ID` سيتم النشر على نفس السيرفر بسرعة.
> بدونها سيتم النشر Global وقد يتأخر ظهور الأوامر.

## التشغيل

```bash
npm start
```

## أوامر البوت

- `/play query:<name|url>` تشغيل أغنية.
- `/pause` إيقاف مؤقت.
- `/resume` استكمال.
- `/skip` تخطي الحالي.
- `/stop` إيقاف ومسح الطابور.
- `/queue` عرض الطابور.
- `/nowplaying` عرض الحالي.
- `/volume percent:<0-200>` تغيير الصوت.
- `/loop` تشغيل/إيقاف التكرار.
- `/disconnect` إخراج البوت من الروم.

## ملاحظات مهمة

- البوت مصمم أساساً لمحتوى YouTube.
- في بعض المقاطع المحمية أو المحظورة قد يفشل التشغيل.
- يفضّل تشغيل البوت على VPS أو استضافة 24/7.

## بنية المشروع

```text
discord-music-bot/
├─ src/
│  ├─ index.js
│  ├─ config.js
│  ├─ commands/index.js
│  └─ utils/
│     ├─ player.js
│     └─ embeds.js
├─ scripts/deploy-commands.js
├─ .env.example
└─ package.json
```
