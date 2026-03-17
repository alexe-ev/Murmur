# 🎙️ Murmur

<p align="center">
<a href="../README.md"><img src="https://hatscripts.github.io/circle-flags/flags/gb.svg" width="24"></a>&nbsp;
<a href="README_RU.md"><img src="https://hatscripts.github.io/circle-flags/flags/ru.svg" width="24"></a>&nbsp;
<a href="README_ES.md"><img src="https://hatscripts.github.io/circle-flags/flags/es.svg" width="24"></a>&nbsp;
<a href="README_HI.md"><img src="https://hatscripts.github.io/circle-flags/flags/in.svg" width="24"></a>&nbsp;
<a href="README_ZH.md"><img src="https://hatscripts.github.io/circle-flags/flags/cn.svg" width="24"></a>&nbsp;
<a href="README_AR.md"><img src="https://hatscripts.github.io/circle-flags/flags/sa.svg" width="24"></a>&nbsp;
<a href="README_FR.md"><img src="https://hatscripts.github.io/circle-flags/flags/fr.svg" width="24"></a>&nbsp;
<a href="README_PT.md"><img src="https://hatscripts.github.io/circle-flags/flags/br.svg" width="24"></a>&nbsp;
<a href="README_UR.md"><img src="https://hatscripts.github.io/circle-flags/flags/pk.svg" width="24"></a>
</p>

**কথা থেকে মানে, শুধু অক্ষর নয়।**

নিজের ভাষায় বলুন। যেকোনো ভাষায় তৈরি টেক্সট পান।

নিজের ভাষায় যা মনে আসে বলুন, অন্য ভাষায় পরিষ্কার টেক্সট পান। Murmur শব্দে শব্দে অনুবাদ করে না। আপনি কী বোঝাতে চাইছেন সেটা ধরে, তারপর সেই ভাষার মানুষ যেভাবে লেখে সেভাবে লিখে দেয়।

## 😤 সমস্যা

নিজের মাতৃভাষা ছাড়া অন্য ভাষায় লেখা ধীর। সাধারণত দুটোর একটা হয়:

- নিজের ভাষায় লিখে অনুবাদকে পেস্ট করেন, তারপর বেমানান ফলাফল ঠিক করেন
- সরাসরি টার্গেট ভাষায় লেখেন, প্রতিটি শব্দ নিয়ে দ্বিধায় থাকেন, খুঁজে দেখেন, বারবার পড়ে নিশ্চিত হন ঠিক শোনাচ্ছে কিনা
- AI দিয়ে অনুবাদ করেন, তারপর সময় ব্যয় করেন সম্পাদনায় কারণ আউটপুট খুব আক্ষরিক বা সুরে মেলে না

AI এজেন্টদের সাথে কাজ করলে সমস্যা আরও বাড়ে। ইংরেজি সেখানে ভালো পছন্দ (কম টোকেন, মডেলের বোধগম্যতা ভালো), কিন্তু চিন্তা তো মাতৃভাষাতেই হয়।

## 💡 সমাধান

হটকি চাপুন। যা বলতে চান বলুন। আপনার প্রয়োজনীয় ভাষায় রেডি-টু-সেন্ড মেসেজ পান।

```
Option+Space  →  যেকোনো ভাষায় বলুন  →  Option+Space
                                              ↓
                                আপনি যেখানে টাইপ করছেন সেখানে
                                পরিষ্কার টেক্সট চলে আসে
```

Murmur শব্দে শব্দে অনুবাদ করে না। এটি আপনার বলা চিন্তাটি নেয়, ফিলার ও অপ্রয়োজনীয় শব্দ বাদ দেয়, এবং টার্গেট ভাষার ব্যাকরণ, সুর ও রীতি অনুসারে টেক্সট তৈরি করে। ফলাফল পড়লে মনে হয় লেখা হয়েছে, অনুবাদ নয়।

## ⚙️ কীভাবে কাজ করে

1. **হটকি চাপুন** (ডিফল্ট `Option + Space`)। একটি রেকর্ডিং ইন্ডিকেটর দেখা যাবে।
2. **বলুন** যেকোনো ভাষায়। যেভাবে মাথায় আসে সেভাবে বলুন।
3. **ক্লিক করুন** যেকোনো টেক্সট ফিল্ডে (ব্রাউজার, এডিটর, মেসেঞ্জার, টার্মিনাল)।
4. **আবার হটকি চাপুন**। টেক্সট সেখানেই চলে আসবে।

অ্যাপ সুইচিং নেই। কপি-পেস্ট নেই। এডিটিং নেই।

[ডেমো দেখুন (২ মিনিট)](https://youtube.com/shorts/4Qr3jkadVsQ)

## 🔀 তিনটি মোড

- **Transcription**: কথ্য ভাষায় সরাসরি স্পিচ-টু-টেক্সট।
- **Clean-up**: একই ভাষা, কিন্তু পরিষ্কার। ফিলার শব্দ বাদ, সঠিক ব্যাকরণ, গোছানো বাক্য। তালিকা স্বয়ংক্রিয়ভাবে ফরম্যাট হয়ে যায়।
- **Translation**: এক ভাষায় বলুন, অন্য ভাষায় পরিষ্কার টেক্সট পান। ৯৭টি ভাষা সমর্থিত। একই ক্লিনআপ প্রযোজ্য: আউটপুট পড়লে মনে হয় স্থানীয় মানুষ লিখেছে, অনুবাদ নয়।

## 📦 ইনস্টল

[Releases](https://github.com/alexe-ev/Murmur/releases) থেকে `Murmur.dmg` ডাউনলোড করে Applications-এ টেনে আনুন।

> অ্যাপটি নোটারাইজড নয়। macOS প্রথমবার চালু করতে গেলে ব্লক করবে। সমাধানের জন্য Terminal-এ চালান:
> ```
> xattr -cr /Applications/Murmur.app
> ```
> এরপর স্বাভাবিকভাবে অ্যাপ খুলুন।

### সোর্স থেকে বিল্ড

```bash
git clone https://github.com/alexe-ev/Murmur.git
cd Murmur
xcodebuild -scheme Murmur -configuration Release -derivedDataPath build
cp -R build/Build/Products/Release/Murmur.app /Applications/
```

### সেটআপ

প্রথমবার চালু করলে **Microphone** ও **Accessibility** পারমিশন দিন। Settings-এ আপনার [OpenAI API key](https://platform.openai.com/api-keys) দিন।

## 📋 প্রয়োজনীয়তা

- macOS 13.0+ (Ventura বা তার পরের)
- Apple Silicon (M1/M2/M3/M4)
- OpenAI API key

অডিও রেকর্ডিং সাময়িক এবং ট্রান্সক্রিপশনের পরই মুছে ফেলা হয়। আপনার API key আপনার মেশিনে লোকালি সংরক্ষিত থাকে।

## 📄 লাইসেন্স

[MIT](../LICENSE)
