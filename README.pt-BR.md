# DRAQOS — Dynamic Render of Artistic QR (código aberto)

Crie QR codes com suas formas, cores e imagens — e mantenha QRs **dinâmicos**
cujo destino você edita depois, servidos com privacidade do seu próprio
computador via Tailscale. Licença MIT, aprendendo e melhorando sempre.

> 🇬🇧 English version: [README.md](README.md).

## O que é

- **Estúdio estático**: editor artístico completo — cores do traço/fundo
  (color picker próprio), imagem de fundo, molduras (quadrado, coração, A4
  deitado 1:1,414, áureo 1:1,618, proporção livre), pontos (quadrado,
  redondo, coração), os 3 olhos configuráveis separadamente, contraste
  automático sobre a imagem, ícone central (PNG/SVG, com opção estética de
  "invadir transparências"), correção de erro nível H, quiet zone
  respeitada, botão **Testar leitura** (decodificação zxing2) e exportação
  **PNG / SVG / PDF**.
- **QRs dinâmicos**: o código impresso guarda uma URL estável
  `https://<maquina>.<tailnet>.ts.net/r/<id>`; você edita o destino quando
  quiser, sem reimprimir. Servidos pelo `draqosd`, um daemon Dart headless
  no seu PC, com contagem de scans (só data/hora — **sem IP, sem dados
  pessoais**).
- **Interface Sci-Fi de game**: nenhum botão com cara de nativo; painéis
  metálicos com bisel, brilho neon, cantoneiras e scanlines, tudo via
  design tokens (`DraqosTokens`) num lugar só.

## Instalação (caminho simples por plataforma)

Baixe a [release mais recente](../../releases) (tags `v*`):

| Plataforma | Arquivo | Notas |
|---|---|---|
| Android | `draqos-*-android.apk` (ou `-android-debug.apk`) | Veja *Assinatura do APK* |
| Windows | `draqos-*-windows-setup.exe` | Inclui app + `draqosd`; tarefa opcional de iniciar no logon |
| Linux (Debian/Ubuntu/Pop!) | `draqos_*_amd64.deb` | Daemon + app + unidade systemd |
| Linux (Fedora/openSUSE) | `draqos-*.x86_64.rpm` | Mesmo conteúdo do `.deb` |
| Linux (qualquer distro) | `draqos-*-linux-x86_64.tar.gz` | Portátil: app + daemon + unit |

Depois de instalar o pacote Linux:

```bash
sudo systemctl start draqosd
systemctl status draqosd
```

### Assinatura do APK

Releases feitas **sem** os secrets de assinatura trazem um **APK assinado
com chave debug** (`-android-debug.apk`): serve para testar/instalar
manualmente, **não** para a Play Store. Para publicar na loja, os
mantenedores configuram os secrets `ANDROID_KEYSTORE_BASE64`,
`ANDROID_STORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` e
geram nova tag — o workflow publica então um `draqos-*-android.apk`
devidamente assinado.

## Parear Android ↔ PC

1. No PC: instale o Tailscale, faça login e garanta o `tailscaled` rodando.
2. Inicie o `draqosd` (systemd no Linux, tarefa de logon no Windows, ou pelo
   app desktop na aba **Daemon**, que inicia/para um daemon local).
3. App desktop → aba **Pair** → **Show pairing QR**. Ele mostra um QR com a
   URL da tailnet + token de admin.
4. App Android → aba **Pair** → cole o código `draqos://pair?...`
   (leitura pela câmera está planejada; colar funciona em todo lugar).
5. A aba **Dynamic** agora lista/cria/edita seus QRs dinâmicos.

## Ativar QRs dinâmicos públicos (Tailscale Funnel)

Só o caminho de redirect `/r/<id>` é exposto; a API admin fica na tailnet.

```bash
# canal tailnet (admin + editores)
tailscale serve --bg --https=443 http://127.0.0.1:8471

# canal público: SOMENTE /r/* (portas do Funnel: 443, 8443 ou 10000;
# a mesma porta não pode ser Serve e Funnel ao mesmo tempo)
tailscale funnel --bg --https=443 --set-path=/r http://127.0.0.1:8471/r
```

Os QRs dinâmicos impressos ficam como `https://meupc.minha-tail.ts.net/r/abc123`.

## Limitações honestas

- **PC desligado = QR dinâmico fora do ar.** A resolução passa pela sua
  máquina; se ela dormir, desligar ou o Tailscale cair, os scans falham.
  QRs estáticos funcionam sempre.
- **Renomear máquina/tailnet quebra os QRs dinâmicos impressos** (a URL
  carrega o nome DNS). O app avisa antes dessas ações; reimprima depois.
- **Android permite uma VPN por vez**: o Tailscale precisa ser a VPN ativa
  para o editor alcançar o PC.
- **O Funnel exige HTTPS + atributo de funnel** na policy da tailnet (o CLI
  guia na primeira vez) e até ~10 min para o DNS público propagar.
- Leitura do pareamento pela câmera não está na v0.1.0 (cole o código).
- Export PDF aproxima pontos redondos/coração como círculos; o SVG é exato.

## Compilar do zero

```bash
flutter pub get            # pub workspace na raiz do repo
dart tool/check_architecture.dart
dart test packages/draqos_core packages/draqos_client packages/draqos_server
flutter test packages/draqos_ui packages/draqos_render apps/draqos_app
dart compile exe packages/draqos_server/bin/draqosd.dart -o build/draqosd
```

Contrato da API: [`docs/api.yaml`](docs/api.yaml). Arquitetura:
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md). Decisões:
[`docs/DECISIONS.md`](docs/DECISIONS.md). Como contribuir:
[`CONTRIBUTING.md`](CONTRIBUTING.md).

## Privacidade

O contador de scans guarda **só data/hora**. Sem IPs, sem user agents, sem
dados pessoais — garantido por teste automatizado
(`PRAGMA table_info(scans)`).
