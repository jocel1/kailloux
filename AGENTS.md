# Projet : Kailloux Adventures

## Vue d'ensemble

Jeu de plateforme/action 2D en side-scrolling style Hollow Knight ou tous les personnages sont des cailloux anthropomorphes mignons. Le joueur incarne un petit caillou qui doit prouver sa valeur en explorant differentes zones souterraines et de surface, en combattant des ennemis et en collectant des objets.

**Moteur** : Godot 4.3
**Langage** : GDScript
**Style graphique** : 2D stylise avec ambiance sombre mais coloree (style Hollow Knight)

## Concept du jeu

### Pitch
"Prouver sa valeur de Kaillou dans les profondeurs"

Le joueur incarne un petit caillou mignon avec des yeux et des expressions. Il explore des cavernes, des ruines et des forets en vue laterale. Combat rapide et precis avec esquive et attaques directionnelles.

### Personnages (tous des cailloux)
- **Joueur** : Petit caillou rond avec grands yeux expressifs, cape flottante optionnelle
- **NPCs** : Cailloux de differentes formes (ovales, anguleux, plats...), certains dorment, d'autres donnent des quetes
- **Ennemis** : Cailloux corrompus, cristaux agressifs, golems de pierre

### Ambiance visuelle cible
- Style inspire de Hollow Knight (ombres, ambiance, fluidite)
- Palette sombre avec touches de couleur vive
- Parallax scrolling pour la profondeur
- Particules pour l'atmosphere (poussieres, lueurs)
- Animations fluides et expressives

## Architecture technique

### Structure du projet Godot

```
kailloux-adventures/
├── project.godot
├── CLAUDE.md
├── assets/
│   ├── sprites/
│   │   ├── player/          # Sprites du kaillou joueur (idle, run, jump, fall, attack, dash)
│   │   ├── npcs/            # Autres kailloux (varietes)
│   │   ├── enemies/         # Ennemis
│   │   ├── items/
│   │   ├── environment/     # Tiles, backgrounds, props
│   │   └── ui/
│   ├── shaders/
│   │   ├── parallax.gdshader
│   │   └── damage_flash.gdshader
│   ├── audio/
│   │   ├── sfx/
│   │   └── music/
│   └── fonts/
├── scenes/
│   ├── player/
│   │   ├── player.tscn
│   │   └── player.gd
│   ├── world/
│   │   ├── maps/
│   │   │   ├── forgotten_caverns.tscn
│   │   │   └── crystal_depths.tscn
│   │   ├── objects/
│   │   │   ├── platform.tscn
│   │   │   ├── spike.tscn
│   │   │   ├── checkpoint.tscn
│   │   │   └── breakable_wall.tscn
│   │   └── world_manager.gd
│   ├── ui/
│   │   ├── hud.tscn
│   │   ├── inventory.tscn
│   │   ├── pause_menu.tscn
│   │   └── dialogue_box.tscn
│   ├── npcs/
│   │   ├── kaillou_npc.tscn
│   │   └── kaillou_npc.gd
│   ├── enemies/
│   │   ├── enemy_base.tscn
│   │   └── enemy_base.gd
│   └── main.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd
│   │   ├── inventory_manager.gd
│   │   ├── save_manager.gd
│   │   └── quest_manager.gd
│   ├── resources/
│   │   ├── item_data.gd
│   │   ├── quest_data.gd
│   │   └── kaillou_data.gd
│   └── utils/
│       └── helpers.gd
└── data/
    ├── items.json
    ├── quests.json
    └── kailloux_types.json
```

### Autoloads (Singletons)

Configurer dans Project Settings > Autoload :
- `GameManager` : etat global du jeu, gestion des scenes
- `InventoryManager` : inventaire du joueur, objets debloques
- `SaveManager` : sauvegarde/chargement (checkpoints)
- `QuestManager` : suivi des quetes

## Mecaniques de jeu (Style Hollow Knight)

### 1. Mouvement du joueur

#### Deplacement horizontal
- Acceleration et deceleration fluides
- Vitesse de course constante
- Animation de course avec cape flottante

#### Saut
- Hauteur variable selon duree de pression
- Coyote time (saut possible quelques frames apres quitter une plateforme)
- Jump buffer (input memorise avant atterrissage)
- Double saut (deblocable)

#### Dash
- Esquive rapide horizontale (ou 8 directions si ameliore)
- Invincibilite pendant le dash
- Cooldown court
- Particules de trainee

#### Wall mechanics (optionnel, deblocable)
- Wall slide (glisser le long des murs)
- Wall jump (sauter depuis un mur)

```gdscript
# Constantes de mouvement
const SPEED = 200.0
const JUMP_VELOCITY = -350.0
const GRAVITY = 900.0
const DASH_SPEED = 400.0
const DASH_DURATION = 0.15
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1

var velocity: Vector2 = Vector2.ZERO
var can_dash: bool = true
var is_dashing: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var facing_direction: int = 1  # 1 = droite, -1 = gauche

func _physics_process(delta):
    # Gravite (sauf pendant dash)
    if not is_dashing:
        if not is_on_floor():
            velocity.y += GRAVITY * delta
            coyote_timer -= delta
        else:
            coyote_timer = COYOTE_TIME

    # Jump buffer
    if Input.is_action_just_pressed("jump"):
        jump_buffer_timer = JUMP_BUFFER_TIME
    jump_buffer_timer -= delta

    # Saut
    if jump_buffer_timer > 0 and coyote_timer > 0:
        velocity.y = JUMP_VELOCITY
        jump_buffer_timer = 0
        coyote_timer = 0

    # Mouvement horizontal
    var direction = Input.get_axis("move_left", "move_right")
    if direction:
        velocity.x = direction * SPEED
        facing_direction = sign(direction)
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED * 0.2)

    move_and_slide()
```

### 2. Systeme de combat

#### Attaque melee (Nail equivalent)
- Attaque rapide dans 4 directions (gauche, droite, haut, bas)
- Attaque vers le bas = pogo (rebond sur ennemis/objets)
- Knockback leger sur hit
- Combo possible avec timing

#### Attaque speciale (Soul equivalent)
- Jauge qui se remplit en frappant des ennemis
- Depenser pour sort de soin ou attaque puissante

```gdscript
# Combat
var attack_direction: Vector2 = Vector2.RIGHT
var can_attack: bool = true
var soul: float = 0.0
const MAX_SOUL = 100.0

func attack():
    if not can_attack:
        return

    can_attack = false

    # Direction basee sur input
    if Input.is_action_pressed("attack_up"):
        attack_direction = Vector2.UP
    elif Input.is_action_pressed("attack_down") and not is_on_floor():
        attack_direction = Vector2.DOWN
    else:
        attack_direction = Vector2(facing_direction, 0)

    # Creer hitbox
    var hitbox = $AttackHitbox
    hitbox.position = attack_direction * 30
    hitbox.monitoring = true

    # Animation
    play_attack_animation(attack_direction)

    await get_tree().create_timer(0.15).timeout
    hitbox.monitoring = false
    can_attack = true

func _on_attack_hitbox_body_entered(body):
    if body.is_in_group("enemies"):
        body.take_damage(1, attack_direction)
        gain_soul(10)

        # Pogo si attaque vers le bas
        if attack_direction == Vector2.DOWN:
            velocity.y = JUMP_VELOCITY * 0.7
```

### 3. Systeme de degats et sante

#### Points de vie
- Masques/coeurs (comme Hollow Knight)
- Invincibilite temporaire apres degat
- Flash visuel + knockback

```gdscript
var max_health: int = 5
var current_health: int = 5
var is_invincible: bool = false

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO):
    if is_invincible:
        return

    current_health -= amount
    is_invincible = true

    # Knockback
    velocity = knockback_dir.normalized() * 200
    velocity.y = -150

    # Flash de degat
    $Sprite.material.set_shader_parameter("flash", true)

    # Timer invincibilite
    await get_tree().create_timer(1.0).timeout
    is_invincible = false
    $Sprite.material.set_shader_parameter("flash", false)

    if current_health <= 0:
        die()
```

### 4. Environnement de platformer

#### Plateformes
- Plateformes solides
- Plateformes traversables (one-way)
- Plateformes mobiles
- Plateformes qui s'effondrent

#### Dangers
- Piques (degat + respawn au dernier sol sur)
- Acide/lave (mort instantanee dans certaines zones)
- Zones sombres (necessite la bougie)

#### Checkpoints
- Bancs de repos (style Hollow Knight)
- Restaure la vie
- Point de respawn
- Sauvegarde automatique

### 5. Systeme d'objets/pouvoirs

#### Pouvoirs deblocables
- **Double saut** : Second saut en l'air
- **Dash** : Esquive rapide avec i-frames
- **Wall jump** : Sauter depuis les murs
- **Bougie** : Illuminer les zones sombres
- **Poing de pierre** : Attaque chargee puissante

### 6. NPCs et dialogues

Les NPCs sont places dans le monde et donnent :
- Indices sur l'histoire
- Quetes secondaires
- Vente d'objets/ameliorations

## Inputs a configurer

Dans Project Settings > Input Map :

| Action | Touches |
|--------|---------|
| move_left | Q, A, Fleche gauche |
| move_right | D, Fleche droite |
| jump | Espace, Z, W |
| attack | J, Clic gauche |
| attack_up | Fleche haut (+ attack) |
| attack_down | Fleche bas (+ attack) |
| dash | K, Shift |
| interact | E, Entree |
| heal | F, A |
| open_inventory | I, Tab |
| open_map | M |
| pause | Echap |

## Priorites de developpement

### Phase 1 : Core (MVP)
1. [x] Setup projet Godot avec structure de dossiers
2. [ ] Player controller platformer (gravite, saut, coyote time)
3. [ ] Dash avec i-frames
4. [ ] Systeme d'attaque directionnelle
5. [ ] Premiere zone de test
6. [ ] Collision et physique

### Phase 2 : Combat et ennemis
7. [ ] Systeme de degats joueur
8. [ ] Ennemi basique (patrol + attaque)
9. [ ] Pogo mechanic
10. [ ] Knockback et hitstun

### Phase 3 : Environnement
11. [ ] Plateformes mobiles
12. [ ] Piques et dangers
13. [ ] Checkpoints / bancs
14. [ ] Zones sombres + bougie

### Phase 4 : Contenu
15. [ ] Zone complete "Cavernes Oubliees"
16. [ ] Zone complete "Profondeurs Cristallines"
17. [ ] Boss de zone
18. [ ] NPCs et quetes

### Phase 5 : Polish
19. [ ] Animations completes
20. [ ] Particules et effets
21. [ ] Audio (SFX + musique ambiance)
22. [ ] Menu principal et sauvegarde

## Conventions de code

### GDScript
- snake_case pour variables et fonctions
- PascalCase pour classes et noms de fichiers de scenes
- Prefixer les signaux par `on_` dans les handlers
- Utiliser les typed variables : `var health: int = 100`
- Documenter les fonctions publiques avec `##`

### Organisation des scenes
- Un script par scene maximum
- Utiliser la composition (scenes enfants) plutot que l'heritage complexe
- Nommer les noeuds clairement : `PlayerSprite`, `HitBox`, `GroundCheck`

### Ressources
- Sprites en PNG ou SVG
- Taille de personnage : environ 32x32 ou 48x48 pixels
- Palette de couleurs coherente (tons sombres + accents colores)

## Notes de game design

### Ton du jeu
- Ambiance mysterieuse mais avec humour (ce sont des cailloux!)
- Monde interconnecte a explorer
- Difficulte exigeante mais juste
- Secrets et zones cachees recompensent l'exploration

### Direction artistique
- Fond sombre avec elements lumineux
- Parallax pour la profondeur
- Cailloux expressifs avec yeux brillants
- Animations fluides et impactantes

### Equilibrage combat
- Ennemis patterns clairs et lisibles
- Fenetre de reaction suffisante
- Degats du joueur et ennemis equilibres
- Checkpoints reguliers

## Commandes utiles

```bash
# Lancer le jeu depuis la ligne de commande
godot --path . --editor  # Ouvrir l'editeur
godot --path . --debug   # Lancer le jeu

# Export
godot --export-release "Windows Desktop" build/windows/kailloux.exe
godot --export-release "Linux/X11" build/linux/kailloux.x86_64
godot --export-release "Web" build/web/index.html
```

## Fonctionnalités Implémentées

### Style visuel des personnages
- **Blobs mignons** : Corps ronds style Kirby avec grands yeux expressifs
- **Mains** (pas de pieds) : Petites mains sur les côtés du corps
- **Attaque** : Les blobs lancent leurs mains comme projectiles

### Système d'attaque par projectile
- **Fichiers** : `scenes/player/arm_projectile.tscn`, `arm_projectile.gd`
- Le joueur lance sa main dans la direction choisie (4 directions)
- Le projectile inflige des dégâts aux ennemis
- Pogo bounce si attaque vers le bas en l'air
- Bonus de dégâts achetable au shop

### Génération procédurale de niveaux
- **Fichiers** : `scripts/world/procedural_map_generator.gd`, `scenes/world/maps/procedural_level.tscn`
- Taille de map progressive : 3000px + 500px par niveau
- Contraintes physiques respectées :
  - Hauteur max saut : 130px
  - Distance max saut : 200px
- Génération du sol avec trous sautables (max 200px)
- Plateformes à hauteurs variées (min 5 par niveau)
- Seed sauvegardé pour restart identique après mort

### Système de progression
- **Difficulté croissante** :
  - Niveau 1 : 3000px, ennemis vitesse 60
  - +500px et +10 vitesse par niveau
  - Densité d'ennemis augmente (multiplicateur 0.85)
- **Porte de sortie** : À la fin de chaque niveau, déclenche le niveau suivant
- **Mort** : Restart du même niveau (même seed = même map)

### Système de récompenses par hauteur
- Plus on monte = plus de récompenses
- Probabilité de coffres :
  - Sol : 5%
  - Plateformes basses : 15%
  - Plateformes moyennes : 30%
  - Plateformes hautes : 50%
- Types de coffres :
  - Normal (60%) : donne K
  - Gem (25%) : donne K x3
  - Piège (15%) : vide/dégâts

### Système de monnaie (K)
- Les ennemis drop 50K à leur mort
- Les coffres donnent des K selon leur type et hauteur
- Dépensable au shop

### Shop (Marchand)
- **Fichiers** : `scenes/world/objects/shop.tscn`, `shop.gd`
- Un seul shop par niveau, placé au sol à 80% de la map
- Items disponibles :
  - Soin : 30K (+1 PV)
  - Vitesse : 50K (+20% vitesse)
  - Force : 75K (+1 dégât)
  - Double saut : 100K

### HUD (Interface)
- **Fichiers** : `scenes/ui/hud.tscn`, `hud.gd`
- Jauge de vie avec couleur dynamique (vert → orange → rouge)
- Affichage du niveau actuel
- Compteur de K (monnaie)
- Slots d'items (1, 2, 3)

### Fichiers clés ajoutés
```
scenes/world/objects/
├── platform.tscn          # Plateforme réutilisable
├── shop.tscn + shop.gd    # Stand de marchand
├── exit_door.tscn + exit_door.gd  # Porte de fin de niveau
└── chest.gd               # Modifié pour currency_amount, is_gem_chest

scripts/world/
└── procedural_map_generator.gd  # Générateur de niveaux

assets/sprites/environment/
├── shop_stand.svg         # Sprite du marchand
└── exit_door.svg          # Sprite de la porte
```

### Variables GameManager importantes
```gdscript
var current_level: int = 1
var current_level_seed: int = 0  # Pour restart identique
var is_restart: bool = false     # Distingue mort vs niveau suivant
var currency: int = 0            # Monnaie K
```

## Ressources externes

- [Documentation Godot 4](https://docs.godotengine.org/en/stable/)
- [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Hollow Knight Wiki](https://hollowknight.fandom.com/) - Reference gameplay
