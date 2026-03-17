# 🎙️ Murmur

<div align="right"><a href="../README.md">🇬🇧</a> <a href="README_RU.md">🇷🇺</a> <a href="README_ES.md">🇪🇸</a> <a href="README_HI.md">🇮🇳</a> <a href="README_ZH.md">🇨🇳</a> <a href="README_AR.md">🇸🇦</a> <a href="README_FR.md">🇫🇷</a> <a href="README_BN.md">🇧🇩</a> <a href="README_PT.md">🇧🇷</a> <a href="README_UR.md">🇵🇰</a></div>

**De la voix au sens, pas de la voix au texte.**

Parlez dans votre langue. Obtenez du texte dans n'importe quelle autre.

Un outil macOS dans la barre de menus qui capture votre voix et produit un texte clair et naturel dans la langue de votre choix. Pas une traduction mot a mot. Murmur comprend ce que vous voulez dire et l'ecrit comme le ferait un locuteur natif.

## 😤 Le probleme

Ecrire dans une langue etrangere, c'est lent. En general, soit vous :

- Ecrivez dans votre langue, collez dans un traducteur, puis corrigez le resultat bancal
- Ecrivez directement dans la langue cible en doutant de chaque mot, en cherchant des tournures, en relisant pour verifier que ca sonne juste
- Utilisez une IA pour traduire, puis passez du temps a retoucher parce que le resultat est trop litteral ou a cote du ton

Le probleme s'aggrave quand vous travaillez avec des agents IA. L'anglais est souvent le meilleur choix (moins de tokens, meilleure comprehension par le modele), mais vous pensez dans votre langue maternelle.

## 💡 La solution

Appuyez sur un raccourci. Dites ce que vous pensez. Recevez un message pret a envoyer dans la langue souhaitee.

```
Option+Space  →  parlez dans n'importe quelle langue  →  Option+Space
                                                              ↓
                                            le texte apparait la ou vous tapez
```

Murmur ne traduit pas mot a mot. Il prend votre pensee orale, supprime les hesitations et le bruit verbal, et produit un texte qui respecte la grammaire, le ton et les conventions de la langue cible. Le resultat se lit comme s'il avait ete ecrit, pas traduit.

## ⚙️ Comment ca marche

1. **Appuyez sur le raccourci** (`Option + Space` par defaut). Un indicateur d'enregistrement apparait.
2. **Parlez** dans n'importe quelle langue. Dites-le comme vous le pensez.
3. **Cliquez** dans n'importe quel champ de texte (navigateur, editeur, messagerie, terminal).
4. **Appuyez a nouveau sur le raccourci**. Le texte apparait la ou vous en avez besoin.

Pas de changement d'application. Pas de copier-coller. Pas de retouche.

## 🔀 Trois modes

- **Transcription** : conversion brute de la parole en texte, dans la langue parlee.
- **Clean-up** : meme langue, mais nettoyee. Plus de mots de remplissage, grammaire corrigee, phrases structurees. Les enumerations sont automatiquement mises en forme sous forme de listes.
- **Translation** : parlez dans une langue, obtenez du texte propre dans une autre. 97 langues prises en charge. Le meme nettoyage s'applique : le resultat se lit comme s'il avait ete ecrit par un locuteur natif, pas traduit.

## 📦 Installation

Telechargez `Murmur.dmg` depuis les [Releases](https://github.com/alexe-ev/Murmur/releases), puis glissez-le dans Applications.

> Non notarise. Au premier lancement : faites un clic droit sur l'application, puis Ouvrir.

### Compiler depuis les sources

```bash
git clone https://github.com/alexe-ev/Murmur.git
cd Murmur
xcodebuild -scheme Murmur -configuration Release -derivedDataPath build
cp -R build/Build/Products/Release/Murmur.app /Applications/
```

### Configuration

Au premier lancement, accordez les permissions **Microphone** et **Accessibilite**. Entrez votre [cle API OpenAI](https://platform.openai.com/api-keys) dans les Reglages.

## 📋 Prerequis

- macOS 13.0+ (Ventura ou ulterieur)
- Apple Silicon (M1/M2/M3/M4)
- Cle API OpenAI

Les enregistrements audio sont temporaires et supprimes juste apres la transcription. Votre cle API est stockee localement sur votre machine.

## 📄 Licence

[MIT](../LICENSE)
