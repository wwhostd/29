# Discord Music Bot Pro (Arabic Friendly)

بوت ديسكورد احترافي لتشغيل الأغاني من YouTube باستخدام **Slash Commands + Control Panel** مع نظام Queue كامل وواجهة Embed جميلة.

## المميزات

- تشغيل بالبحث أو بالرابط (`/play`) أو من خلال زر **Add Song** في البانل.
- **بانل تحكم احترافي** داخل روم محدد (أزرار: Add / Pause / Resume / Skip / Queue / Stop).
- Queue احترافي مع عرض الأغنية الحالية والقادمة.
- عند إضافة الأغنية تبدأ مباشرة إذا البوت فاضي (Auto Play).
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
  - Send Messages
  - Use Slash Commands
  - Embed Links

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
MUSIC_PANEL_CHANNEL_ID=... # روم نصي مخصص للبانل
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

## تفعيل البانل (مرة واحدة)

بعد تشغيل البوت واكتمال نشر الأوامر:

1. نفّذ الأمر `/setup-panel` (يتطلب صلاحية Manage Server).
2. البوت سيرسل لوحة التحكم داخل الروم المحدد في `MUSIC_PANEL_CHANNEL_ID`.
3. المستخدم يضغط **Add Song** ويكتب اسم/رابط الأغنية مباشرة من Modal.

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
- `/setup-panel` إرسال بانل التحكم للروم المخصص.

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
