# Guia de Integracao de Arte e Sprites

Este documento define os padroes tecnicos, dimensoes e organizacao de pastas para a substituicao dos placeholders por arte final no projeto.

## Estrutura de Diretorios

```
assets/art/
├── sprites/
│   ├── player/          # Spritesheets e animacoes do guerreiro
│   ├── echo/            # Versao espectral do guerreiro
│   ├── enemies/         # Inimigos, arqueiros e projeteis
│   ├── items/           # Reliquia, artefatos e coletaveis
│   ├── princess/        # Princesa aprisionada e resgatada
│   └── environment/     # Elementos cenicos (escadas, portoes, placas)
├── tilesets/            # Tilesets de plataformas, chao e paredes (32x32)
└── ui/                  # Icones, molduras e elementos de interface
```

## Padroes dos Personagens

### 1. Guerreiro (assets/art/sprites/player/)
- Caixa de colisão: 32 por 48 pixels
- Tamanho de quadro recomendado: 48 por 48 pixels ou 64 por 64 pixels
- Ponto de origem (pivot): Centralizado nos pés
- Animacoes necessarias:
  - idle: Guarda e respiracao (4 a 6 quadros)
  - run: Corrida (6 a 8 quadros)
  - jump: Subida do salto (2 a 3 quadros)
  - fall: Queda (2 quadros)
  - climb: Subida de escada (4 a 6 quadros)
  - attack: Golpe de espada (4 a 5 quadros)
  - hurt: Reacao ao dano (2 quadros)
  - death: Queda e derrota (6 quadros)

### 2. Eco (assets/art/sprites/echo/)
- Caixa de colisao: 32 por 48 pixels com colisao unidirecional (plataforma solida superior)
- Efeito visual: Translúcido (ciano ou espectral)

### 3. Inimigos e Projeteis (assets/art/sprites/enemies/)
- Arqueiro: 32 por 48 pixels com animacao de mirar e disparar
- Flecha: 16 por 8 pixels

### 4. Princesa e Reliquia (assets/art/sprites/princess/ e items/)
- Princesa: 32 por 48 pixels
- Reliquia: 24 por 24 pixels ou 32 por 32 pixels

## Padroes dos Andares e Cenarios

### 1. Tilesets de Chao e Paredes (assets/art/tilesets/)
- Tamanho de grade: 32 por 32 pixels
- Superficies:
  - Chao solido (blocos de pedra ancestral)
  - Plataformas semi-solidas (madeira ou lajes com colisao unidirecional)
  - Paredes e pilares de sustentacao

### 2. Objetos de Cenario (assets/art/sprites/environment/)
- Escadas: Largura padrao de 32 a 36 pixels
- Portões: 20 por 96 pixels (estados fechado e aberto)
- Placas de pressao: 36 por 12 pixels (estados normal e pressionado)
- Pontes retrateis: 200 por 24 pixels

## Sistema Modular de Slots (SpriteSlot)

Cada cena do jogo (personagem, eco, inimigos, portao, escada, artefato, princesa) possui um no dedicado chamado SpriteSlot.

1. Enquanto o SpriteSlot nao tiver uma textura atribuida, o jogo usa os visuais vetoriais proceduralmente como fallback.
2. Ao arrastar uma textura PNG para o SpriteSlot no painel do Inspector da Godot, o jogo exibe automaticamente a nova arte e oculta os placeholders sem necessidade de alterar codigo.
