# Ecos do Guerreiro Esquecido

Jogo de plataforma e quebra-cabeça 2D focado no domínio estratégico de ecos temporais, combate com espada e reflexão de projéteis, desenvolvido com a Godot Engine 4.7.2.

[![Jogue no Itch.io](https://img.shields.io/badge/Itch.io-Jogue%20Online-fa5c5c?style=for-the-badge&logo=itchdotio&logoColor=white)](https://rodrigols99.itch.io/ecos-do-guerreiro-esquecido)

---

## 1. Sinopse

Em um reino assolado por uma névoa densa que apaga gradativamente as memórias de todos os seres vivos, a Princesa, guardiã da Relíquia dos Ecos, foi capturada e aprisionada no topo de uma torre ancestral em ruínas.

O jogador assume o controle do Guerreiro Esquecido, o único combatente imune aos efeitos da névoa. Despertando nas profundezas da torre sem lembranças de seu passado, ele deve ascender pelos cinco andares da torre sagrada, superando armadilhas mecânicas, sentinelas armadas e enigmas de transposição espacial para resgatar a Princesa e restaurar as memórias do reino.

---

## 2. Mecânicas Centrais

| Mecânica | Descrição |
| :--- | :--- |
| **Movimentação e Plataforma** | Deslocamento horizontal ágil, pulo com altura variável, escalada em escadas de madeira e travessia de plataformas unidirecionais. |
| **Tolerâncias de Salto (*Game Feel*)** | Sistema com *Coyote Time* (0.05s) e *Jump Buffer* (0.08s), garantindo precisão máxima nos controles. |
| **Criação de Eco** | Projeção de uma réplica espectral sólida no espaço da fase. A cópia atua como plataforma estática temporária para alcançar locais elevados e transpor abismos. |
| **Colapso Temporal** | Teletransporte instantâneo do guerreiro de volta para a coordenada exata onde o eco foi projetado, cancelando o momento inercial. |
| **Combate e Aparo (*Parry*)** | Golpe horizontal com espada capaz de derrotar sentinelas e rebater flechas e projéteis arcanos diretamente aos atiradores. |
| **Progressão por Andares** | Cinco andares com identidades visuais próprias, desafios mecânicos crescentes e trilhas sonoras dedicadas. |
| **Múltiplos Finais** | Rota da Vitória ou Rota Trágica. |

---

## 3. Controles Padrão

| Ação | Tecla Padrão | Descrição |
| :--- | :--- | :--- |
| Mover para a Esquerda | A | Deslocamento horizontal para a esquerda |
| Mover para a Direita | D | Deslocamento horizontal para a direita |
| Subir Escada | W | Movimentação vertical ascendente em escadas |
| Descer Escada | S | Movimentação vertical descendente em escadas |
| Pular | Barra de Espaço | Salto com altura variável |
| Atacar com a Espada | J | Golpe de lâmina e reflexão de projéteis |
| Invocar Eco | K | Criação de réplica espectral sólida |
| Colapsar Eco (Teleporte) | L | Teletransporte instantâneo para a posição do eco |
| Pausar Jogo | ESC | Abertura do menu de pausa |

Todas as teclas podem ser remapeadas livremente no menu de Opções durante a execução, com suporte a detecção e resolução automática de conflitos de teclas.

---

## 4. Estrutura do Repositório

```text
├── .github/
│   └── workflows/
│       └── export.yml            # Esteira de CI/CD para compilação multiplataforma
├── docs/                         # Documentação formal do projeto
│   ├── README.md                 # Índice geral da documentação
│   ├── atividades/               # Atividades acadêmicas de game design
│   └── jogo/                     # Concepção, narrativa e arquitetura técnica do jogo
├── src/                          # Código-fonte, cenas e recursos do jogo em Godot 4
│   ├── assets/                   # Texturas, spritesheets e fontes
│   ├── autoload/                 # Gerenciadores globais de estado, áudio e configurações
│   ├── scenes/                   # Cenas modulares (jogador, fases, interface, combate)
│   ├── export_presets.cfg        # Perfis de exportação para Linux, Windows e Web
│   └── project.godot             # Arquivo principal de configuração da Godot Engine
└── README.md
```

Para aprofundar-se na narrativa e na ambientação dos andares, consulte a [História e Universo do Jogo](docs/jogo/historia_e_universo.md).

Para detalhes sobre a arquitetura de software, cinemática e subsistemas técnicos, consulte a [Documentação Técnica do Jogo](docs/jogo/documentacao_tecnica.md).

---

## 5. Como Executar Localmente

### Pré-requisitos
- [Godot Engine](https://godotengine.org/download) versão 4.7.2 (ou versão do Godot 4 que seja compatível).

### Execução no Editor
1. Clone este repositório:
   ```bash
   git clone https://github.com/RodrigoLS99/Ecos-do-Guerreiro-Esquecido.git
   ```
2. Abra o executável da Godot Engine e selecione a opção **Importar**.
3. Navegue até a pasta clonada e selecione o arquivo `project.godot` localizado dentro do diretório `src/`.
4. Pressione **F5** ou clique no botão **Executar** no canto superior direito para iniciar o jogo a partir da tela de título.
