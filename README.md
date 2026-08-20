# Ecos do Guerreiro Esquecido

Projeto desenvolvido na Godot Engine 4.

## Descricao

Ecos do Guerreiro Esquecido e um jogo de plataforma e quebra cabeca 2D focado no uso estrategico de ecos temporarios, combate com espada e reflexao de projeteis.

O jogador assume o controle de um guerreiro que desperta sem memorias em um santuario invadido por uma nevoa espectral. Para resgatar a princesa e recuperar suas lembrancas, e necessario escalar cinco andares repletos de desafios, armadilhas e inimigos.

## Mecanicas Principais

- Movimentacao: Andar para esquerda e direita, pular e subir escadas.
- Criacao de Eco: Invoca um clone espectral estatico que serve como plataforma temporaria solida. O guerreiro pode subir no eco para alcancar locais mais altos.
- Colapso de Eco: Teletransporta instantaneamente o guerreiro para a posicao exata onde o eco foi criado.
- Combate: Golpe horizontal com a espada capaz de derrotar inimigos e rebater flechas e projeteis de volta aos atiradores.
- Game Feel: Coyote Time de 0.05s, Jump Buffer de 0.08s e pulo com altura variavel.

## Estrutura do Projeto

- assets/: Recursos de arte, fontes e documentacao tecnica de sprites.
- autoload/: Gerenciadores globais do jogo.
  - game_state.gd: Controle de fluxo de andares e reinicio de fase.
  - settings_manager.gd: Gerenciador de configuracoes, volume e remapeamento de controles.
  - audio_manager.gd: Motor de audio procedural em 16-bits e trilhas sonoras por andar.
- scenes/:
  - player/: Cena do guerreiro e do eco.
  - enemies/: Inimigos e arqueiros.
  - combat/: Projeteis e flechas.
  - common/: Portões, placas de pressao, escadas, pontes, artefato e princesa.
  - floors/: Andares 1 ao 5 do templo.
  - ui/: Telas de titulo, prologo, pausa, opcoes, ajuda, vitoria e HUD.

## Controles Padrao

- Andar: A e D ou Setas Esquerda e Direita
- Subir Escada: W ou Seta Cima
- Descer Escada: S ou Seta Baixo
- Pular: Barra de Espaco
- Atacar: X
- Criar Eco: C
- Colapsar Eco / Teleportar: V
- Pausar: ESC

Todas as teclas podem ser remapeadas livremente no menu de Opcoes com deteccao automatica de conflito.

## Como Executar

1. Abra o Godot Engine 4.
2. Importe o arquivo project.godot localizado na raiz do projeto.
3. Pressione F5 para executar o jogo.
