# Octo Ink Hell

Bullet-hell / horde-survival roguelite em Godot 4.7 (GDScript, Forward+).

Voce controla um polvo bioluminescente numa arena submersa. A tinta e municao,
mas cada tiro tambem mancha a tela: quanto mais voce atira, menos voce enxerga.
Pra limpar, troca o cuspidor de tinta pelo rodo e esfrega as manchas na mao,
gastando fluido de limpeza que so os inimigos dropam.

## Rodando

Abre a pasta no Godot 4.7 e F5. Pela linha de comando:

    godot --path .

Controles: WASD/setas anda, mouse mira, botao esquerdo usa a ferramenta atual,
botao direito troca entre cuspidor e rodo, Espaco/Shift da dash.

As input actions sao registradas em codigo no `game_events.gd`, nao no
project.godot.

## Mecanica central

Atirar nao escurece a tela. Cada tiro carimba uma mancha de verdade num
CanvasLayer em screen-space (`InkOverlay`), que nao acompanha a camera. O
formato vem da arma (`splat_style`: streak, blob ou burst) e a mancha e rotada
na direcao do tiro e arremessada pra fora, entao metralhar pra um lado suja
aquele lado da tela.

Qualquer coisa que mata precisa custar visao. A poca do dash com Ink Trail
causa dano, entao ela tambem carimba mancha, senao dava pra limpar as ondas
atropelando todo mundo com a tela impecavel. Dash sem dano continua de graca.

A cor do projetil nao e a cor da mancha de proposito. A mancha precisa ser
mais escura que o chao pra ocluir, e um projetil dessa cor sumiria em cima dela.

Limpar e ativo. No modo rodo o cursor do sistema some e o overlay desenha o
rodo no lugar. Segurando o botao esquerdo voce apaga as manchas embaixo do
cursor (`InkOverlay.wipe_at`), arrastando por cima delas. Isso gasta fluido
(`CleanerSystem`) e enquanto limpa voce nao atira, entao a horda acumula.

## Arena

Arena fechada de 2200x1400 (`scripts/world/arena.gd`). Antes o mapa era
infinito e o jogo ficava trivial: andar de re atirando ganhava de qualquer
horda porque nada te encurralava.

Nada colide fisicamente com as paredes. Os corpos ficam com `collision_mask = 0`
igual ao resto do projeto e quem se move se clampa sozinho no
`Arena.clamp_position()`. A camera usa a arena como `limit_*`, os projeteis
somem ao encostar na parede e o WaveManager rejeita spawn fora dos limites.

## Upgrades

Terminou a onda, o jogo pausa e sorteia tres cartas (clique ou tecla 1/2/3).
Voce tem 15 segundos; se acabar, uma roleta corre pelas cartas e para numa
sozinha. O contador roda em PROCESS_MODE_ALWAYS porque a arvore esta pausada.

O sorteio espalha entre Offensive / Mobility / Utility pra escolha ser entre
estilos de jogo, e nao tres sabores de "mais dano". Upgrade que bateu o
`max_stacks` sai do pool.

O pool foi montado em cima da propria tensao do jogo: upgrade ofensivo suja a
tela mais rapido (Dense Ink aumenta a mancha, Hair Trigger carimba mais por
segundo) e o ramo Utility compra visao de volta, ate o Diluted Ink, que troca
dano por tela limpa.

Sao 12 upgrades em `resources/upgrades/`. Pra adicionar um: joga o .tres la e
lista no `UpgradePool.ALL`.

Duas coisas pra lembrar mexendo nisso:

Upgrade nunca escreve dentro de WeaponData/EnemyData. Esses .tres sao
preloaded, entao todo mundo compartilha a mesma instancia em cache, que
sobrevive ao `reload_current_scene()`. Gravar um buff ali carregava o build da
run anterior pra proxima e ia acumulando pra sempre. A Weapon guarda o .tres
como base imutavel e uma copia `runtime` por instancia com os upgrades
aplicados; o resto pergunta pro `UpgradeSystem.value(stat, base)`.

O intervalo entre ondas nao e timer. `SceneTree.create_timer()` vem com
`process_always = true`, entao um timer continuaria contando com a tela de
upgrade pausando a arvore e a proxima onda cairia por cima. O WaveManager
espera o `upgrade_selected`, que a tela emite mesmo quando nao tem mais nada
pra oferecer, senao o pool vazio travava a run.

## Arquitetura

Os sistemas conversam por um signal bus (`GameEvents`, autoload) em vez de
guardar referencia um do outro. Inimigos e armas sao data-driven em Resource
customizado (.tres), entao balanceamento e mexer em arquivo, nao em codigo.

    autoload/
      game_events.gd        signal bus + input map
    resources/
      weapon_data.gd        custo, projeteis, formato da mancha
      enemy_data.gd         hp, velocidade, dano, chance de drop
      upgrade_data.gd       categoria, descricao, efeitos, stacks
      upgrade_effect.gd     um stat + add + mult
    scripts/
      main.gd               monta e liga o mundo na ordem certa
      world/arena.gd        clamp, spawn, limites de camera
      player/
        player.gd           movimento, mira, dash, troca de ferramenta, HP
        ink_system.gd       reservatorio de tinta
        cleaner_system.gd   reservatorio de fluido de limpeza
        weapon.gd           dispara, gasta tinta, emite shot_fired
        upgrade_system.gd   upgrades da run -> valor final dos stats
      combat/projectile.gd
      enemies/
        enemy_base.gd       persegue, dano por contato, sorteia drop
        swarmer.gd
      systems/
        ink_overlay.gd      mancha na tela + wipe_at + cursor do rodo
        wave_manager.gd     ondas escalonadas
        upgrade_pool.gd     roster + sorteio de 3 cartas
      effects/
      pickups/
      ui/
        hud.gd
        upgrade_screen.gd   draft entre ondas, 15s + roleta

Os .tscn sao stubs de um no so. Todo entity ainda e placeholder desenhado
proceduralmente no `_draw`. Quando a arte real chegar e so trocar os `_draw`
por Sprite2D/AnimatedSprite2D dentro de cada cena, sem mexer na logica.

Camadas de colisao: 1 player, 2 inimigos, 4 projetil do player, 8 pickups.
Nada bloqueia nada fisicamente (mask 0), tudo passa por Area2D.

## Proximos passos

- Shooter e Boss como subclasses de EnemyBase, com padroes de tiro em Timer + await
- Object pooling de projeteis e inimigos quando a contagem subir
- Glow bioluminescente: ligar hdr_2d + WorldEnvironment e empurrar as cores
  brilhantes acima de 1.0
- XP e level usando o `EnemyData.xp_value`, que ja existe mas nao e usado

## Status

Anda, mira, dash, atira gastando tinta e sujando a tela conforme arma e angulo,
troca pro rodo e limpa gastando fluido, ondas escalonadas de Swarmer numa arena
fechada, drops de limpeza, draft de upgrade entre ondas com 12 upgrades em tres
categorias e HUD funcionando. Importa e roda no Godot 4.7.
