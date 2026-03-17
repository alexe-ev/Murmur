# 🎙️ Murmur

<p align="center">
<a href="../README.md"><img src="https://hatscripts.github.io/circle-flags/flags/gb.svg" width="24"></a>&nbsp;
<a href="README_RU.md"><img src="https://hatscripts.github.io/circle-flags/flags/ru.svg" width="24"></a>&nbsp;
<a href="README_HI.md"><img src="https://hatscripts.github.io/circle-flags/flags/in.svg" width="24"></a>&nbsp;
<a href="README_ZH.md"><img src="https://hatscripts.github.io/circle-flags/flags/cn.svg" width="24"></a>&nbsp;
<a href="README_AR.md"><img src="https://hatscripts.github.io/circle-flags/flags/sa.svg" width="24"></a>&nbsp;
<a href="README_FR.md"><img src="https://hatscripts.github.io/circle-flags/flags/fr.svg" width="24"></a>&nbsp;
<a href="README_BN.md"><img src="https://hatscripts.github.io/circle-flags/flags/bd.svg" width="24"></a>&nbsp;
<a href="README_PT.md"><img src="https://hatscripts.github.io/circle-flags/flags/br.svg" width="24"></a>&nbsp;
<a href="README_UR.md"><img src="https://hatscripts.github.io/circle-flags/flags/pk.svg" width="24"></a>
</p>

**De voz a significado, no de voz a texto.**

Habla en tu idioma. Recibe texto listo en cualquier otro.

Murmur no traduce palabra por palabra: capta lo que quisiste decir y lo escribe como lo diría un nativo.

## 😤 El Problema

Escribir en un idioma que no es el tuyo es lento. O bien:

- Escribes en tu idioma, lo pegas en un traductor y luego corriges el resultado extraño
- Escribes directamente en el idioma de destino, dudando de cada palabra, buscando expresiones, releyendo para ver si suena bien
- Usas IA para traducir y después pasas tiempo editando porque el resultado es demasiado literal o tiene un tono raro

Esto se vuelve peor cuando trabajas con agentes de IA, donde el inglés es la mejor opción (menos tokens, mejor comprensión del modelo), pero piensas en tu idioma nativo.

## 💡 La Solución

Presiona un atajo. Di lo que quieres decir. Obtén un mensaje listo para enviar en el idioma que necesites.

```
Option+Space  →  habla en cualquier idioma  →  Option+Space
                                                     ↓
                                       el texto limpio aparece donde escribes
```

Murmur no traduce palabra por palabra. Toma tu pensamiento hablado, elimina muletillas y ruido verbal, y produce texto que sigue la gramática, el tono y las convenciones del idioma de destino. El resultado se lee como si hubiera sido escrito, no traducido.

## ⚙️ Cómo Funciona

1. **Presiona el atajo** (por defecto `Option + Space`). Aparece un indicador de grabación.
2. **Habla** en cualquier idioma. Dilo como lo pienses.
3. **Haz clic** en cualquier campo de texto (navegador, editor, mensajero, terminal).
4. **Presiona el atajo de nuevo**. El texto aparece donde lo necesitas.

Sin cambiar de app. Sin copiar y pegar. Sin editar.

## 🔀 Tres Modos

- **Transcripción**: texto en crudo del habla en el idioma original.
- **Limpieza**: mismo idioma, pero limpio. Sin muletillas, gramática correcta, oraciones estructuradas. Las enumeraciones se formatean automáticamente como listas.
- **Traducción**: habla en un idioma, obtén texto limpio en otro. 97 idiomas soportados. Se aplica la misma limpieza: el resultado se lee como si lo hubiera escrito un hablante nativo, no como una traducción.

## 📦 Instalación

Descarga `Murmur.dmg` desde [Releases](https://github.com/alexe-ev/Murmur/releases) y arrástralo a Aplicaciones.

> No está notarizado. Para el primer inicio: haz clic derecho en la app y selecciona Abrir.

### Compilar desde el Código Fuente

```bash
git clone https://github.com/alexe-ev/Murmur.git
cd Murmur
xcodebuild -scheme Murmur -configuration Release -derivedDataPath build
cp -R build/Build/Products/Release/Murmur.app /Applications/
```

### Configuración

En el primer inicio, otorga los permisos de **Micrófono** y **Accesibilidad**. Ingresa tu [clave de API de OpenAI](https://platform.openai.com/api-keys) en Ajustes.

## 📋 Requisitos

- macOS 13.0+ (Ventura o posterior)
- Apple Silicon (M1/M2/M3/M4)
- Clave de API de OpenAI

Las grabaciones de audio son temporales y se eliminan inmediatamente después de la transcripción. Tu clave de API se almacena localmente en tu máquina.

## 📄 Licencia

[MIT](../LICENSE)
