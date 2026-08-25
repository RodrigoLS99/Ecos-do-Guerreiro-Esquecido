# Documentação do Jogo

Este diretório centraliza toda a documentação de concepção, design de sistemas, narrativa e engenharia técnica de Ecos do Guerreiro Esquecido, projeto desenvolvido por Ricardo Martins da Silva e Rodrigo Leandro dos Santos para a disciplina de Projeto de Jogos Digitais da Universidade Federal do Agreste de Pernambuco (UFAPE).

---

## Índice de Documentos

### 1. Documentos Formais de Design (Concepção e GDD)
- [definicao_do_projeto.pdf](definicao_do_projeto.pdf):
  - Identificação: Atividade 05 - Definição do Projeto.
  - Conteúdo: Estabelece o escopo inicial, tema de fantasia medieval retro inspirado no clássico *Forgotten Warrior* (era J2ME/Flash), público-alvo (14 a 35 anos e comunidade de speedruns), narrativa do esquecimento e o diferencial mecânico das sombras temporais (Ecos).
- [one_page_gdd_ecos_do_guerreiro_esquecido.pdf](one_page_gdd_ecos_do_guerreiro_esquecido.pdf):
  - Identificação: Atividade 07 - One Page Game Design Document (OPGDD).
  - Conteúdo: Sumário executivo consolidando High Concept, gênero (Plataforma 2D e Ação), plataformas pretendidas (Windows, Linux e Web), pilares de combate com timing de espada e regras centrais de jogo em formato de página única.
- [sgdd_ecos_do_guerreiro_esquecido.pdf](sgdd_ecos_do_guerreiro_esquecido.pdf):
  - Identificação: Short Game Design Document (SGDD).
  - Conteúdo: Especificação sistemática cobrindo o fluxo de jogo (da tela de título ao encerramento), regras de criação e colapso de ecos, armadilhas de cenário (espinhos e lâminas), confronto com sentinelas corrompidas e requisitos técnicos de arte e programação.

### 2. Universo e Narrativa
- [historia_e_universo.md](historia_e_universo.md):
  - Conteúdo: Crônica integral do reino, a emergência da névoa corruptora, o aprisionamento da Princesa no topo da torre, a ambientação temática dos cinco andares e a existência dos múltiplos desfechos da jornada mantidos sob mistério.

### 3. Engenharia de Software e Arquitetura Técnica
- [documentacao_tecnica.md](documentacao_tecnica.md):
  - Conteúdo: Especificação técnica detalhada cobrindo a arquitetura em GDScript tipado na Godot Engine 4.7.2, FSM e equações cinemáticas do jogador (`SPEED = 160.0`, `JUMP_VELOCITY = -320.0`, `GRAVITY = 900.0`, `CLIMB_SPEED = 100.0`, Coyote Time de 0.05s e Jump Buffer de 0.08s), ciclo de vida dos ecos temporais, lógica de aparo e reflexão de projéteis (`speed * 1.4` e inversão vetorial), motor de áudio procedural em 16-bits com alinhamento harmônico de fase e esteira automatizada de CI/CD no GitHub Actions.
