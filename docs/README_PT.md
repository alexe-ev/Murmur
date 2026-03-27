<p align="center">
  <img src="../murmur.png" alt="Murmur" width="100%">
</p>

<p align="center">
<a href="../README.md"><img src="https://hatscripts.github.io/circle-flags/flags/gb.svg" width="24"></a>&nbsp;
<a href="README_RU.md"><img src="https://hatscripts.github.io/circle-flags/flags/ru.svg" width="24"></a>&nbsp;
<a href="README_ES.md"><img src="https://hatscripts.github.io/circle-flags/flags/es.svg" width="24"></a>&nbsp;
<a href="README_HI.md"><img src="https://hatscripts.github.io/circle-flags/flags/in.svg" width="24"></a>&nbsp;
<a href="README_ZH.md"><img src="https://hatscripts.github.io/circle-flags/flags/cn.svg" width="24"></a>&nbsp;
<a href="README_AR.md"><img src="https://hatscripts.github.io/circle-flags/flags/sa.svg" width="24"></a>&nbsp;
<a href="README_FR.md"><img src="https://hatscripts.github.io/circle-flags/flags/fr.svg" width="24"></a>&nbsp;
<a href="README_BN.md"><img src="https://hatscripts.github.io/circle-flags/flags/bd.svg" width="24"></a>&nbsp;
<a href="README_UR.md"><img src="https://hatscripts.github.io/circle-flags/flags/pk.svg" width="24"></a>
</p>

Murmur não faz tradução literal. Ele entende a ideia e escreve do jeito que um nativo escreveria.

## 😤 O Problema

Escrever em um idioma que não é o seu é lento. Você acaba:

- Escrevendo no seu idioma, colando num tradutor, e depois ajustando o resultado estranho
- Escrevendo direto no idioma-alvo, duvidando de cada palavra, pesquisando termos, relendo pra ver se soa natural
- Usando IA pra traduzir, e depois gastando tempo editando porque o resultado ficou literal demais ou com o tom errado

Isso piora quando você trabalha com agentes de IA, onde inglês é a melhor escolha (menos tokens, melhor compreensão dos modelos), mas o raciocínio acontece no seu idioma nativo.

## 💡 A Solução

Aperte um atalho. Diga o que você quer dizer. Receba uma mensagem pronta pra enviar no idioma que precisa.

```
Option+Space  →  fale em qualquer idioma  →  Option+Space
                                               ↓
                                 o texto limpo aparece onde você digita
```

O Murmur não traduz palavra por palavra. Ele pega o que você falou, remove pausas e ruídos verbais, e produz um texto que segue a gramática, o tom e as convenções do idioma-alvo. O resultado parece que foi escrito, não traduzido.

## ⚙️ Como Funciona

1. **Aperte o atalho** (padrão `Option + Space`). Um indicador de gravação aparece.
2. **Fale** em qualquer idioma. Diga do jeito que vier à cabeça.
3. **Clique** em qualquer campo de texto (navegador, editor, mensageiro, terminal).
4. **Aperte o atalho de novo**. O texto aparece onde você precisa.

Sem trocar de app. Sem copiar e colar. Sem edição.

[Assistir à demo (2 min)](https://youtube.com/shorts/4Qr3jkadVsQ)

## 🔀 Três Modos

- **Transcrição**: fala convertida em texto bruto no idioma falado.
- **Limpeza**: mesmo idioma, mas com o texto limpo. Sem palavras de preenchimento, gramática correta, frases bem estruturadas. Enumerações formatadas automaticamente como listas.
- **Tradução**: fale em um idioma, receba texto limpo em outro. 97 idiomas suportados. A mesma limpeza se aplica: o resultado parece ter sido escrito por um falante nativo, não traduzido.

## 📦 Instalação

Baixe o `Murmur.dmg` em [Releases](https://github.com/alexe-ev/Murmur/releases) e arraste para Aplicativos.

> O app não é notarizado. O macOS vai bloqueá-lo na primeira execução. Para resolver, execute no Terminal:
> ```
> xattr -cr /Applications/Murmur.app
> ```
> Depois abra o app normalmente.

### Compilar a partir do código-fonte

```bash
git clone https://github.com/alexe-ev/Murmur.git
cd Murmur
xcodebuild -scheme Murmur -configuration Release -derivedDataPath build
cp -R build/Build/Products/Release/Murmur.app /Applications/
```

### Configuração

Na primeira execução, conceda as permissões de **Microfone** e **Acessibilidade**. Insira sua [chave de API da OpenAI](https://platform.openai.com/api-keys) nas Configurações.

## 📋 Requisitos

- macOS 13.0+ (Ventura ou posterior)
- Apple Silicon (M1/M2/M3/M4)
- Chave de API da OpenAI

As gravações de áudio são temporárias e excluídas logo após a transcrição. Sua chave de API é armazenada localmente na sua máquina.

## 📄 Licença

[MIT](../LICENSE)
