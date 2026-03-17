# 🎙️ Murmur

<p align="center">
<a href="../README.md"><img src="https://hatscripts.github.io/circle-flags/flags/gb.svg" width="24"></a>&nbsp;
<a href="README_ES.md"><img src="https://hatscripts.github.io/circle-flags/flags/es.svg" width="24"></a>&nbsp;
<a href="README_HI.md"><img src="https://hatscripts.github.io/circle-flags/flags/in.svg" width="24"></a>&nbsp;
<a href="README_ZH.md"><img src="https://hatscripts.github.io/circle-flags/flags/cn.svg" width="24"></a>&nbsp;
<a href="README_AR.md"><img src="https://hatscripts.github.io/circle-flags/flags/sa.svg" width="24"></a>&nbsp;
<a href="README_FR.md"><img src="https://hatscripts.github.io/circle-flags/flags/fr.svg" width="24"></a>&nbsp;
<a href="README_BN.md"><img src="https://hatscripts.github.io/circle-flags/flags/bd.svg" width="24"></a>&nbsp;
<a href="README_PT.md"><img src="https://hatscripts.github.io/circle-flags/flags/br.svg" width="24"></a>&nbsp;
<a href="README_UR.md"><img src="https://hatscripts.github.io/circle-flags/flags/pk.svg" width="24"></a>
</p>

**Голос в смысл, а не голос в текст.**

Наговори мысль на своём языке. Получи готовый текст на другом.

Murmur не переводит дословно: он берёт то, что ты сказал, и пишет так, как написал бы носитель.

## 😤 Проблема

Писать на неродном языке долго. Варианты такие:

- Пишете на своём языке, вставляете в переводчик, потом правите корявый результат
- Пишете сразу на целевом языке, сомневаетесь в каждом слове, гуглите, перечитываете, проверяете, звучит ли нормально
- Переводите через AI, а потом редактируете, потому что перевод слишком буквальный или не попадает в тон

С AI-агентами всё ещё хуже: английский работает лучше (меньше токенов, модель лучше понимает), но думаете вы на родном языке.

## 💡 Решение

Нажали хоткей. Сказали, что хотели. Получили готовое сообщение на нужном языке.

```
Option+Space  →  говорите на любом языке  →  Option+Space
                                                ↓
                                  чистый текст появляется там, где вы печатаете
```

Murmur не переводит дословно. Он берёт вашу мысль, убирает слова-паразиты и речевой мусор и выдаёт текст, который соответствует грамматике, тону и нормам целевого языка. Результат читается так, будто его написали, а не перевели.

## ⚙️ Как это работает

1. **Нажмите хоткей** (по умолчанию `Option + Space`). Появится индикатор записи.
2. **Говорите** на любом языке. Формулируйте как думаете.
3. **Кликните** в любое текстовое поле (браузер, редактор, мессенджер, терминал).
4. **Нажмите хоткей ещё раз**. Текст появится там, где нужно.

Без переключения приложений. Без копирования. Без редактирования.

## 🔀 Три режима

- **Transcription**: сырая расшифровка речи на языке, на котором вы говорили.
- **Clean-up**: тот же язык, но текст вычищен. Без слов-паразитов, с правильной грамматикой и структурой. Перечисления автоматически оформляются как списки.
- **Translation**: говорите на одном языке, получаете чистый текст на другом. Поддерживается 97 языков. Текст проходит ту же обработку: результат читается так, как если бы его написал носитель, а не перевёл.

## 📦 Установка

Скачайте `Murmur.dmg` из [Releases](https://github.com/alexe-ev/Murmur/releases), перетащите в Applications.

> Приложение не нотаризовано. macOS заблокирует его при первом запуске. Чтобы исправить, выполните в Терминале:
> ```
> xattr -cr /Applications/Murmur.app
> ```
> После этого откройте приложение как обычно.

### Сборка из исходников

```bash
git clone https://github.com/alexe-ev/Murmur.git
cd Murmur
xcodebuild -scheme Murmur -configuration Release -derivedDataPath build
cp -R build/Build/Products/Release/Murmur.app /Applications/
```

### Настройка

При первом запуске дайте разрешения на **Микрофон** и **Универсальный доступ** (Accessibility). Введите ваш [ключ OpenAI API](https://platform.openai.com/api-keys) в настройках.

## 📋 Требования

- macOS 13.0+ (Ventura и новее)
- Apple Silicon (M1/M2/M3/M4)
- Ключ OpenAI API

Аудиозаписи временные и удаляются сразу после расшифровки. Ваш API-ключ хранится локально на вашем устройстве.

## 📄 Лицензия

[MIT](../LICENSE)
