# Documentação Técnica de Ecos do Guerreiro Esquecido

Este documento detalha a arquitetura de software, subsistemas de jogabilidade, padrões de projeto, parâmetros de física, motor de síntese de áudio procedural e esteira de CI/CD do projeto Ecos do Guerreiro Esquecido.

---

## 1. Visão Geral da Arquitetura de Software

O projeto é construído na Godot Engine 4.7.2 com código-fonte em GDScript estritamente tipado. A arquitetura segue os princípios de composição orientada a nós (Node Composition), máquina de estados finitos (FSM) para controle comportamental de entidades e nós globais desacoplados registrados via Autoload para estado de sessão, persistência e áudio.

```text
src/
├── assets/          # Spritesheets, texturas de tilesets, fontes e recursos gráficos
├── autoload/        # Singletons globais carregados na inicialização
│   ├── audio_manager.gd
│   ├── game_state.gd
│   └── settings_manager.gd
├── scenes/          # Estrutura modular de cenas
│   ├── combat/      # Projéteis, flechas e detectores de colisão
│   ├── common/      # Mecanismos de cenário (portões, placas, tochas, escadas, princesa)
│   ├── enemies/     # Entidades inimigas (arqueiro espectral)
│   ├── floors/      # Cenas dos cinco andares da torre (floor_1.tscn a floor_5.tscn)
│   ├── player/      # Entidade do guerreiro e réplicas de eco
│   └── ui/          # Cenas de interface de usuário (menus, HUD e telas de encerramento)
├── export_presets.cfg
└── project.godot
```

---

## 2. Módulos Globais e Singletons (Autoload)

### 2.1 GameState (`autoload/game_state.gd`)
Responsável pelo ciclo de vida da sessão de jogo, controle de fluxo entre andares e recarregamento de fases:
- `current_floor_index: int`: Armazena o índice do andar ativo (iniciando em 1).
- `FLOOR_PATHS: Array[String]`: Vetor constante contendo os caminhos para `res://scenes/floors/floor_1.tscn` até `floor_5.tscn`.
- `start_game() -> void`: Redefine o índice para 1 e inicia a primeira fase através de `respawn_current_floor()`.
- `respawn_current_floor() -> void`: Sincroniza o índice com a cena ativa e recarrega o andar corrente quando o jogador sofre derrota, garantindo a destruição de nós residuais e reinicialização limpa.
- `go_to_next_floor() -> void`: Incrementa o índice do andar e carrega a cena subsequente. Caso o jogador conclua o quinto andar, a transição é direcionada para a tela de vitória (`res://scenes/ui/victory_screen.tscn`).

### 2.2 SettingsManager (`autoload/settings_manager.gd`)
Gerencia o armazenamento persistente em disco e a reatribuição dinâmica de teclas de controle:
- Persistência em Disco: Lê e grava parâmetros no arquivo `user://settings.cfg` através de `ConfigFile` nas seções `audio` e `controls`.
- Canais de Áudio: Controla os barramentos `Master`, `Music` e `SFX` aplicando conversão de ganho linear (0.0 a 1.0) para decibéis via função nativa `linear_to_db()`.
- Remapeamento com Resolução de Conflitos: Na função `remap_action(action_name, new_event)`, o sistema varre todas as ações mapeadas no `InputMap`. Caso a nova tecla já esteja em uso por outra ação, ela é automaticamente removida da ação anterior para prevenir comandos duplicados simultâneos.

### 2.3 AudioManager (`autoload/audio_manager.gd`)
Motor de síntese de áudio procedural que sintetiza em tempo de execução todas as músicas e efeitos sonoros diretamente na memória RAM, sem carregar arquivos WAV ou MP3 externos:
- Especificações do Motor: Resolução de 16-bits mono (`AudioStreamWAV.FORMAT_16_BITS`), taxa de amostragem de 22050 Hz (`SAMPLE_RATE = 22050`) e pool dinâmico de doze canais de reprodução (`POOL_SIZE = 12`).
- Continuidade de Fase e Alinhamento Harmônico: As músicas de fundo possuem duração exata de 4.0 segundos ($N = 88200$ amostras). Para assegurar transições contínuas sem cliques de fase no ponto de repetição, todas as frequências fundamentais $f$ são calculadas como múltiplos exatos de $0.25\text{ Hz}$ ($f \times 4.0\text{s} \in \mathbb{Z}$). O ciclo de onda é fechado rigorosamente no valor zero ao fim do buffer.
- Faixa de Conforto Acústico: As frequências fundamentais das melodias operam entre 55 Hz e 523 Hz (A1 a C5). Envelopes exponenciais suaves ($e^{-k \cdot t}$) e controle harmônico evitam tons estridentes acima de 900 Hz, prevenindo fadiga auditiva em sessões prolongadas.
- Faixas Musicais Sintetizadas:
  - Menu Principal: Dedilhado melancólico e sereno de alaúde em Lá menor (A2, E3, A3, C4, E4, D4).
  - Andar 1 (Masmorra Rústica): Modo Dórico solene e acolhedor em Ré menor (D3, F3, G3, A3).
  - Andar 2 (Salão Arcano): Tensão mística com subgraves pulsantes em Mi menor.
  - Andar 3 (Ruínas Abissais): Percussão abafada e arpejos graves em Fá menor.
  - Andar 4 (Fortaleza Carmesim): Marcha acelerada e enérgica a 170 BPM em Dó menor.
  - Andar 5 (Santuário Celestial): Harpa celestial serena e harmônicos suaves em Dó Maior.
  - Tela de Vitória: Hino nobre e triunfante em Dó Maior.
  - Tela de Tragédia: Réquiem fúnebre lúgubre com notas graves isoladas em Lá menor.
- Efeitos Sonoros Sintetizados:
  - `jump`: Onda senoidal com elevação tonal rápida de 130 Hz para 260 Hz.
  - `step`: Pulso curto de ruído branco filtrado simulando o impacto do passo.
  - `sword_swing`: Ruído modulado com envelope agudo simulando o corte do ar.
  - `sword_hit` e `hit_enemy`: Impactos com combinação de onda quadrada e ruído metálico.
  - `projectile_shoot`: Pulso rápido simulando o disparo da flecha.
  - `projectile_parry`: Ruído ressonante metálico indicando a reflexão bem-sucedida.
  - `ladder_climb`: Pulso seco em 110 Hz simulando a pegada do calçado na madeira da escada.
  - `player_death`: Curva descendente de frequência simulando o colapso do guerreiro.
  - `fall_death`: Efeito Doppler com queda tonal prolongada e atenuação de volume simulando a queda no abismo.
  - `enemy_death`: Dissolução espectral com modulação de frequência e ruído suave.
  - `echo_create`: Pulso ressonante cristalino em 440 Hz com decaimento suave.
  - `echo_collapse`: Varredura tonal descendente acompanhada por efeito reverso.
  - `pressure_plate` e `gate_open`: Cliques mecânicos e ressonâncias de pedra/ferro.
  - `artifact_pickup`: Sinal harmônico ascendente em tríade maior.
  - `button_click`: Clique nítido de interface de usuário.

---

## 3. Subsistema do Jogador (Player)

O nó raiz do guerreiro (`scenes/player/player.gd`) estende CharacterBody2D e gerencia o seguinte conjunto de parâmetros e regras de física:

### 3.1 Parâmetros e Constantes Cinemáticas
- `SPEED: float = 160.0`: Velocidade horizontal máxima de deslocamento em pixels por segundo.
- `JUMP_VELOCITY: float = -320.0`: Impulso vertical inicial aplicado no momento do salto.
- `GRAVITY: float = 900.0`: Aceleração da gravidade aplicada ao eixo vertical em pixels por segundo ao quadrado.
- `CLIMB_SPEED: float = 100.0`: Velocidade uniforme de subida e descida em escadas.
- `MAX_HEALTH: int = 3`: Quantidade máxima de pontos de vida do guerreiro.
- `INVINCIBILITY_TIME: float = 1.0`: Duração da janela de invencibilidade temporária após sofrer dano.
- `HURT_DURATION: float = 0.15`: Duração do estado de reação a dano com congelamento momentâneo de entradas.
- `ATTACK_DURATION: float = 0.25`: Duração total da animação de golpe de espada.
- `ATTACK_HITBOX_WINDOW: float = 0.12`: Janela temporal em que a área de colisão da lâmina permanece ativa para causar dano e refletir projéteis.

### 3.2 Tolerâncias de Controle e Game Feel
- `COYOTE_TIME: float = 0.05`: Temporizador iniciado no instante em que o guerreiro deixa o solo sem saltar, permitindo executar o salto mesmo que o personagem já esteja no ar logo após a borda da plataforma.
- `JUMP_BUFFER_TIME: float = 0.08`: Temporizador acionado quando o botão de salto é pressionado antes de tocar o chão, disparando o pulo no primeiro quadro de física em que o guerreiro colide com o solo.
- Salto com Altura Variável: Caso o botão de salto seja liberado antes do ápice da trajetória e a velocidade vertical seja inferior a `-100.0 px/s`, a velocidade é truncada para `-100.0 px/s`, permitindo alternar entre saltos baixos e saltos completos.

### 3.3 Máquina de Estados (State Machine)
O personagem opera através da enumeração `State { IDLE, RUN, JUMP, FALL, CLIMB, ATTACK, HURT, DEAD }`:
- `IDLE`: Repouso no solo sem velocidade horizontal.
- `RUN`: Deslocamento lateral sobre superfícies sólidas.
- `JUMP`: Ascensão vertical com velocidade vertical negativa.
- `FALL`: Queda sob a ação da gravidade ($900.0\text{ px/s}^2$).
- `CLIMB`: Gravidade zerada, deslocamento vertical a $100.0\text{ px/s}$ e horizontal a $60.0\text{ px/s}$ dentro de uma `ladder_zone`, emitindo som de passos na madeira a cada 0.28 segundos.
- `ATTACK`: Execução do golpe de lâmina com ativação da `AttackHitbox`.
- `HURT`: Piscar em vermelho com redução momentânea de controle e ativação da janela de invencibilidade de 1.0 segundo.
- `DEAD`: Reprodução do som de derrota e recarregamento automático da fase via `GameState.respawn_current_floor()`.

---

## 4. Subsistema de Ecos Temporais (Echo System)

O sistema de ecos permite ao jogador projetar e colapsar réplicas temporais para resolução de quebra-cabeças:

### 4.1 Criação de Eco
1. O jogador aciona o comando `echo_create`.
2. O script verifica a existência de uma réplica prévia através da variável `current_echo`. Caso exista, a réplica anterior é destruída via `queue_free()`.
3. A cena `res://scenes/player/echo.tscn` é instanciada e inserida na árvore de nós como filha direta do nó raiz da fase.
4. A posição global do eco é travada nas coordenadas exatas onde o guerreiro executou a invocação.
5. O sinal `echo_changed.emit(true)` é emitido para atualizar o indicador de eco no HUD.

### 4.2 Colisão e Suporte de Plataforma
- A cena do eco (`echo.tscn`) é composta por um `StaticBody2D` configurado na camada de plataformas sólidas (`Collision Layer 1`).
- O topo da réplica contém um `CollisionShape2D` com a propriedade `one_way_collision = true`. Isso permite que o guerreiro atravesse o eco por baixo ao saltar e pouse solidamente sobre sua superfície superior, utilizando-o como degrau ou apoio aéreo.

### 4.3 Colapso Temporal e Teletransporte
1. Ao acionar o comando `echo_collapse`, o script valida a presença de um `current_echo` ativo.
2. A coordenada global do guerreiro é transladada imediatamente: `global_position = current_echo.global_position`.
3. As velocidades horizontais e verticais do jogador são zeradas (`velocity = Vector2.ZERO`) para evitar desvios inerciais após o teletransporte.
4. O efeito sonoro `echo_collapse` é reproduzido e partículas de mana são emitidas no local.
5. A instância do eco é liberada da memória e o sinal `echo_changed.emit(false)` é emitido para o HUD.

---

## 5. Subsistema de Combate e Mecânica de Aparo (Parry)

### 5.1 Hitbox de Ataque da Espada
- O guerreiro possui uma `Area2D` denominada `AttackHitbox` pertencente ao grupo `player_attack`.
- Sua forma de colisão é ativada exclusivamente durante a janela de impacto da espada (`ATTACK_HITBOX_WINDOW = 0.12s`).

### 5.2 Lógica de Reflexão de Projéteis (`scenes/combat/projectile.gd`)
A classe do projétil opera com velocidade base `speed = 180.0 px/s` e direção horizontal `direction = -1` ou `1`.
Ao detectar sobreposição com a `AttackHitbox` do jogador:
1. O método `deflect(player_facing)` é disparado.
2. A flag `is_deflected` é definida como `true`.
3. A direção é invertida: `direction = new_direction`.
4. A velocidade recebe um multiplicador de aceleração de 1.4x: `speed *= 1.4` (resultando em $252.0\text{ px/s}$).
5. A vida útil do projétil é reiniciada para `lifetime = 2.8s`.
6. A orientação visual da flecha é espelhada no eixo horizontal.
7. O efeito sonoro `projectile_parry` é reproduzido.
8. Ao colidir com entidades do grupo `enemy`, o projétil refletido causa dano de 1 ponto ao inimigo através de `body.take_damage(1)`.

### 5.3 Entidade do Arqueiro Espectral (`scenes/enemies/enemy_shooter.gd`)
- Parâmetros: `max_health = 2`, `facing_direction = -1` e `auto_face_player = true`.
- Detecção e Disparo: O arqueiro orienta-se automaticamente na direção do jogador e dispara projéteis através do nó `ShootTimer`.
- Dano e Morte: Ao receber dano por lâmina ou flecha refletida, o arqueiro pisca em vermelho, reproduz o som espacializado `hit_enemy` e tem seus pontos de vida reduzidos em sua barra de pips (`HealthBar`). Ao atingir 0 de vida, o som `enemy_death` é tocado, a animação de derrota é executada e o nó é removido da cena via tween de dissolução em transparência.

---

## 6. Mecanismos Interativos e Level Design

### 6.1 Portões Arcanos (`scenes/common/gate.gd`)
- Estrutura: `StaticBody2D` com grade metálica e colisor de bloqueio.
- Abertura e Fechamento: Utiliza interpolação por `create_tween()` com transição suave, deslocando a grade verticalmente em 48 pixels e desativando o colisor de passagem quando aberto.

### 6.2 Placas de Pressão (`scenes/common/pressure_plate.gd`)
- Detecção Multicorpo: Monitora sobreposições na área de colisão através de contadores internos. O mecanismo mantém-se ativo caso o jogador e o eco estejam sobrepostos simultaneamente, desativando-se apenas quando ambos deixam a placa.
- Comunicação por Sinais: Emite o sinal `pressed(is_active)` conectado aos nós de portões e pontes correspondentes da fase.

### 6.3 Pontes Móveis (`scenes/common/bridge_platform.gd`)
- Plataformas retráteis ativadas por placas de pressão que estendem passarelas sólidas sobre fossos de espinhos para viabilizar a travessia.

### 6.4 Tochas e Iluminação (`scenes/common/torch.gd`)
- Renderização procedural vetorial com vértices de polígonos calculados em tempo real. As chamas oscilam suavemente através de funções senoidais defasadas no tempo, provendo iluminação dinâmica sem uso de texturas pesadas.

---

## 7. Interface do Usuário (UI)

- `title_screen.tscn`: Tela inicial com céu noturno estrelado, silhuetas arquitetônicas do castelo, tochas montadas sobre colunas de pedra e ouro, partículas de mana flutuantes e navegação completa por teclado e mouse.
- `options_menu.tscn`: Painel modal para controle de volume e matriz de remapeamento de comandos com validação de conflitos em tempo de execução.
- `hud.tscn`: Camada visual persistente com indicador do andar ativo e estado de eco ativo.
- `victory_screen.tscn`: Painel celestial de encerramento apresentando a narrativa da purificação do reino e opções de retorno ao menu.
- `tragedy_screen.tscn`: Tela escura apresentando o desfecho da rota trágica acompanhada por réquiem fúnebre.

---

## 8. Esteira de Integração Contínua e Exportação (CI/CD)

Configurada no GitHub Actions em `.github/workflows/export.yml`:
- Gatilhos de Execução: Disparado em eventos de push na branch `main` e publicação de tags de versão `v*`.
- Exportação Headless: Executa a ação oficial `firebelley/godot-export@v8.0.0` com o executável e templates da Godot Engine 4.7.2 apontando para o diretório `./src`.
- Nomenclatura Padronizada de Artefatos:
  - `Ecos do Guerreiro Esquecido - Linux.x86-64`
  - `Ecos do Guerreiro Esquecido - Windows.exe`
  - `Ecos do Guerreiro Esquecido - Web.zip` (com `index.html`, `index.js`, `index.wasm` e `index.pck` organizados diretamente na raiz do pacote compactado).
- Publicação de Releases: Ao publicar tags no padrão `v*`, a ação `softprops/action-gh-release@v3` anexa os três arquivos compilados diretamente na página de Releases do repositório no GitHub com suporte automático a pre-releases e geração de notas de versão.
