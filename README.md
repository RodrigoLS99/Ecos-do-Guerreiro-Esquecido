# Ecos do Guerreiro Esquecido

Um jogo de plataforma e quebra-cabeça 2D focado no domínio estratégico de ecos temporais, combate com espada e reflexão de projéteis, desenvolvido com a **Godot Engine 4**.

---

## Sinopse

Há eras, o reino prosperava sob a luz da sagrada **Relíquia dos Ecos**, guardada pela Princesa no topo do Templo Ancestral. Quando uma névoa espectral emergiu dos abismos apagando as memórias de todos os povos, a torre foi selada e corrompida.

Você é o **Guerreiro Esquecido**, que desperta nas profundezas da masmorra. Dominando os ecos do seu próprio passado, você deve superar as armadilhas dos cinco andares corrompidos, recuperar o artefato divino e decidir o destino do reino e da humanidade.

---

## Mecânicas Principais

| Mecânica | Descrição |
| :--- | :--- |
| **Movimentação & Plataforma** | Andar, saltar, subir escadas e atravessar plataformas unidirecionais com física responsiva (*Coyote Time* de 0.05s e *Jump Buffer* de 0.08s). |
| **Criação de Eco** | Projeta um clone espectral estático no ar ou no chão que serve como plataforma sólida temporária. |
| **Colapso / Teletransporte** | Teletransporta instantaneamente o guerreiro de volta para a posição exata onde o eco foi gerado. |
| **Combate & Aparo (*Parry*)** | Golpe horizontal com espada capaz de derrotar guardiões corrompidos e rebater flechas e projéteis mágicos de volta aos atacantes. |
| **Progressão por Andares** | 5 andares com identidades visuais e mecânicas próprias, indo da alvenaria rústica ao ápice da corrupção e ao santuário celestial. |
| **Finais Múltiplos** | Rota da Vitória com epílogo narrativo da redenção do reino ou Rota Trágica secreta. |

---

## Controles Padrão

| Ação | Teclado (Padrão) |
| :--- | :--- |
| **Mover para Esquerda** | `A` |
| **Mover para Direita** | `D` |
| **Subir Escada / Olhar para Cima** | `W` |
| **Descer Escada / Descer Plataforma** | `S` |
| **Pular** | `Espaço` |
| **Atacar com a Espada** | `X` |
| **Criar Eco** | `C` |
| **Colapsar Eco / Teleportar** | `V` |
| **Menu de Pausa** | `ESC` |

> *Todas as teclas podem ser remapeadas livremente no menu de **Opções** com detecção e resolução de conflitos de teclas em tempo real.*

---

## Estrutura do Projeto

```text
├── assets/                  # Recursos de arte, spritesheets, frames e fontes
├── autoload/                # Singletons globais do sistema
│   ├── audio_manager.gd     # Motor de áudio procedural em 16-bits e trilhas sonoras por andar
│   ├── game_state.gd        # Controle de estado de jogo, andares e respawn
│   └── settings_manager.gd  # Persistência de preferências, volume e remapeamento de teclas
├── scenes/
│   ├── combat/              # Projéteis, flechas e zonas de aparo
│   ├── common/              # Portões, tochas, placas de pressão, artefatos, runas e princesa
│   ├── enemies/             # Inimigos arcanos e arqueiros
│   ├── floors/              # Cenas dos 5 andares (floor_1.tscn a floor_5.tscn)
│   ├── player/              # Guerreiro e projeções de eco espectral
│   └── ui/                  # Telas de título, prólogo, pausa, opções, vitória e tragédia
├── export_presets.cfg       # Presets de compilação multiplataforma
├── project.godot            # Arquivo mestre de configuração da Godot Engine
└── .github/workflows/       # Pipeline de CI/CD para compilação e publicação automática
```

---

## Design de Áudio Procedural

O jogo utiliza um sintetizador procedural integrado em 16-bits (`SAMPLE_RATE = 22050 Hz`) com trilhas musicais contínuas dedicadas para cada andar:
- **Andar 1**: Exploração nobre e serena em Modo Dórico.
- **Andar 2**: Tensão mística crescente com sub-graves.
- **Andar 3**: Ruínas abissais ritmadas com pulso de perigo.
- **Andar 4**: Marcha sombria acelerada e dinâmica em ~170 BPM.
- **Andar 5**: Hino sagrado puro com harpa celestial aveludada.
- **Menu**: Canção nostálgica com dedilhado suave de alaúde.
- **Vitória**: Hino orquestral nobre do Reino Renascido.
- **Tragédia**: Réquiem fúnebre lúgubre com sino solene e violoncelo.

---

## Como Executar Localmente

### Pré-requisitos
- [Godot Engine 4.x](https://godotengine.org/download) instalada.

### Executando no Editor
1. Clone este repositório:
   ```bash
   git clone https://github.com/seu-usuario/Ecos-do-Guerreiro-Esquecido.git
   ```
2. Abra a **Godot Engine 4**.
3. Clique em **Importar** e selecione o arquivo `project.godot` na raiz do projeto.
4. Pressione `F5` ou clique no botão **Play** no canto superior direito para rodar o jogo.

---

## Compilação e Exportação Multiplataforma

O projeto está configurado para exportação nas seguintes plataformas:
- **Linux**: `Ecos do Guerreiro Esquecido - Linux.x86-64`
- **Windows**: `Ecos do Guerreiro Esquecido - Windows.exe`
- **Web**: `Ecos do Guerreiro Esquecido - Web.zip` (compatível com navegadores modernos, GitHub Pages e Itch.io)

### Integração Contínua (GitHub Actions)
O pipeline automatizado em `.github/workflows/export.yml` compila o projeto em todas as plataformas a cada push e anexa os pacotes de distribuição automaticamente nas **Releases** ao criar tags no padrão `v*` (ex: `v1.0.0`).
