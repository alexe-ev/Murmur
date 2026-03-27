<p align="center">
  <img src="../murmur.png" alt="Murmur" width="100%">
</p>

<p align="center">
<a href="../README.md"><img src="https://hatscripts.github.io/circle-flags/flags/gb.svg" width="24"></a>&nbsp;
<a href="README_RU.md"><img src="https://hatscripts.github.io/circle-flags/flags/ru.svg" width="24"></a>&nbsp;
<a href="README_ES.md"><img src="https://hatscripts.github.io/circle-flags/flags/es.svg" width="24"></a>&nbsp;
<a href="README_HI.md"><img src="https://hatscripts.github.io/circle-flags/flags/in.svg" width="24"></a>&nbsp;
<a href="README_ZH.md"><img src="https://hatscripts.github.io/circle-flags/flags/cn.svg" width="24"></a>&nbsp;
<a href="README_FR.md"><img src="https://hatscripts.github.io/circle-flags/flags/fr.svg" width="24"></a>&nbsp;
<a href="README_BN.md"><img src="https://hatscripts.github.io/circle-flags/flags/bd.svg" width="24"></a>&nbsp;
<a href="README_PT.md"><img src="https://hatscripts.github.io/circle-flags/flags/br.svg" width="24"></a>&nbsp;
<a href="README_UR.md"><img src="https://hatscripts.github.io/circle-flags/flags/pk.svg" width="24"></a>
</p>

Murmur مو ترجمة حرفية. يفهم إيش تقصد ويكتبها مثل ما يكتبها واحد لغته الأم.

## 😤 المشكلة

الكتابة بلغة غير لغتك الأم عملية بطيئة. إما أنك:

- تكتب بلغتك، ثم تلصق النص في مترجم، ثم تصلح النتيجة الركيكة
- تكتب مباشرة باللغة المطلوبة، وتشكّ في كل كلمة، وتبحث عن المعاني، وتعيد القراءة لتتأكد أن الكلام يبدو طبيعياً
- تستخدم الذكاء الاصطناعي للترجمة، ثم تقضي وقتاً في التعديل لأن النتيجة حرفية أو بنبرة خاطئة

المشكلة تزداد عند العمل مع وكلاء الذكاء الاصطناعي، حيث الإنجليزية هي الخيار الأفضل (عدد رموز أقل، فهم أفضل من النماذج)، لكن التفكير يحدث بلغتك الأم.

## 💡 الحل

اضغط اختصاراً. قل ما تريد. واحصل على رسالة جاهزة للإرسال باللغة التي تحتاجها.

```
Option+Space  →  تحدّث بأي لغة  →  Option+Space
                                        ↓
                          النص الجاهز يظهر حيث تكتب
```

Murmur لا يترجم كلمة بكلمة. بل يأخذ فكرتك المنطوقة، ويزيل الحشو والضجيج اللفظي، وينتج نصاً يتبع قواعد اللغة المطلوبة ونبرتها وأعرافها. النتيجة تبدو كأنها كُتبت ابتداءً، لا كأنها تُرجمت.

## ⚙️ كيف يعمل

1. **اضغط الاختصار** (الافتراضي `Option + Space`). يظهر مؤشر التسجيل.
2. **تحدّث** بأي لغة. قلها كما تفكّر بها.
3. **انقر** في أي حقل نصي (متصفح، محرر، تطبيق مراسلة، طرفية).
4. **اضغط الاختصار مرة أخرى**. يظهر النص حيث تحتاجه.

بدون تبديل بين التطبيقات. بدون نسخ ولصق. بدون تعديل.

[شاهد العرض التوضيحي (دقيقتان)](https://youtube.com/shorts/4Qr3jkadVsQ)

## 🔀 ثلاثة أوضاع

- **النسخ الصوتي**: تحويل الكلام إلى نص كما هو بلغة المتحدث.
- **التنظيف**: نفس اللغة، لكن بعد التنظيف. بدون كلمات حشو، بقواعد صحيحة، وجمل منظّمة. التعدادات تُنسّق تلقائياً كقوائم.
- **الترجمة**: تحدّث بلغة واحصل على نص مرتّب بلغة أخرى. يدعم 97 لغة. نفس التنظيف يُطبّق: النتيجة تبدو كأن متحدثاً أصلياً كتبها، لا كأنها تُرجمت.

## 📦 التثبيت

حمّل `Murmur.dmg` من [الإصدارات](https://github.com/alexe-ev/Murmur/releases)، واسحبه إلى Applications.

> التطبيق غير موثّق من Apple. سيحظره macOS عند أول تشغيل. لحل المشكلة، نفّذ في Terminal:
> ```
> xattr -cr /Applications/Murmur.app
> ```
> ثم افتح التطبيق بشكل عادي.

### البناء من المصدر

```bash
git clone https://github.com/alexe-ev/Murmur.git
cd Murmur
xcodebuild -scheme Murmur -configuration Release -derivedDataPath build
cp -R build/Build/Products/Release/Murmur.app /Applications/
```

### الإعداد

عند أول تشغيل، امنح صلاحيات **Microphone** و**Accessibility**. أدخل مفتاح [OpenAI API](https://platform.openai.com/api-keys) في الإعدادات.

## 📋 المتطلبات

- macOS 13.0+ (Ventura أو أحدث)
- Apple Silicon (M1/M2/M3/M4)
- مفتاح OpenAI API

التسجيلات الصوتية مؤقتة وتُحذف فور انتهاء النسخ. مفتاح API يُخزّن محلياً على جهازك.

## 📄 الترخيص

[MIT](../LICENSE)
