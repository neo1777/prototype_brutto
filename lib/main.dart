// ╔═══════════════════════════════════════════════════════════════════╗
// ║  🎮 IL PROTOTIPO BRUTTO — Un Dungeon Crawler in Un Solo File    ║
// ║                                                                   ║
// ║  Questo file è una prefazione pratica al libro                   ║
// ║  "Guida Universale al Game Development con Flutter & Flame"      ║
// ║                                                                   ║
// ║  ISTRUZIONI:                                                      ║
// ║  1. Crea un progetto: flutter create prototype_brutto             ║
// ║  2. Aggiungi flame: ^1.34.0 al pubspec.yaml                     ║
// ║  3. Sostituisci lib/main.dart con questo file                    ║
// ║  4. flutter run                                                   ║
// ║                                                                   ║
// ║  STRUTTURA:                                                       ║
// ║  - VERSIONE 1 (riga ~30):  Il gioco base — funziona!            ║
// ║  - VERSIONE 2 (riga ~200): +1 nemico — inizia a scricchiolare   ║
// ║  - VERSIONE 3 (riga ~280): +inventario — crolla tutto           ║
// ║                                                                   ║
// ║  Dopo aver provato tutte e 3 le versioni, capirai perché        ║
// ║  servono 80 capitoli per fare un gioco BENE. 💪                  ║
// ╚═══════════════════════════════════════════════════════════════════╝

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Cambia questo valore per provare le 3 versioni ───
const int gameVersion = 1; // 1 = base, 2 = +pipistrello, 3 = +inventario

// 🚩 NOTA: Stiamo mettendo TUTTO in un solo file.
// Funziona per 150 righe. Vedremo tra poco cosa succede a 300.

// 🚩 NOTA: Variabili globali per lo stato di gioco.
// Chi le gestisce? Tutti. Chi le resetta? Speriamo qualcuno.
// → Nel libro (Cap 037) vedremo il sistema Save/Load con serializzazione.
int score = 0;
int hp = 3;
bool isGameOver = false;
bool isInvincible = false;
double invincibleTimer = 0;
double difficultyTimer = 0;
double speedMultiplier = 1.0;
double potionSpawnTimer = 0;
final Random _rng = Random();

// Versione 3: inventario globale
List<String> inventory = []; // 'hp', 'speed', 'shield'
bool hasSpeedBoost = false;
double speedBoostTimer = 0;
bool hasShield = false;
double shieldTimer = 0;

void main() {
  runApp(GameWidget(game: PrototypeBruttoGame()));
}

// ╔══════════════════════════════════════════════════════════════════╗
// ║  🎮 VERSIONE 1: IL GIOCO BASE                                   ║
// ║  ~150 righe — Funziona. È divertente. È un incubo da espandere. ║
// ╚══════════════════════════════════════════════════════════════════╝

class PrototypeBruttoGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Player player;
  final List<Enemy> enemies = [];
  final List<Potion> potions = [];
  late TextComponent hpText;
  late TextComponent scoreText;
  double _aliveTimer = 0;

  @override
  Color backgroundColor() => const Color(0xFF2A2A2A);

  @override
  Future<void> onLoad() async {
    _resetState();

    player = Player();
    player.position = size / 2;
    add(player);

    for (int i = 0; i < 3; i++) {
      _spawnSlime();
    }

    if (gameVersion >= 2) {
      _spawnBat();
    }

    hpText = TextComponent(
      text: _hpString(),
      position: Vector2(16, 16),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
    add(hpText);

    scoreText = TextComponent(
      text: 'Score: 0',
      anchor: Anchor.topRight,
      position: Vector2(size.x - 16, 16),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
    add(scoreText);
  }

  void _resetState() {
    score = 0;
    hp = 3;
    isGameOver = false;
    isInvincible = false;
    invincibleTimer = 0;
    difficultyTimer = 0;
    speedMultiplier = 1.0;
    potionSpawnTimer = 0;
    inventory.clear();
    hasSpeedBoost = false;
    speedBoostTimer = 0;
    hasShield = false;
    shieldTimer = 0;
  }

  String _hpString() => 'HP: ${'❤️' * hp}${'🖤' * (3 - hp)}';

  void _spawnSlime() {
    final e = Enemy(type: 'slime');
    e.position = Vector2(
      50 + _rng.nextDouble() * (size.x - 100),
      50 + _rng.nextDouble() * (size.y - 100),
    );
    enemies.add(e);
    add(e);
  }

  // 🚩 NOTA: Per controllare le collisioni usiamo il check distanza manuale.
  // Funziona con 3 nemici. Con 300? Controlliamo 300x300 = 90.000 coppie al frame.
  // → Nel libro (Cap 031) vedremo Broadphase/Narrowphase che scala.

  void _spawnBat() {
    final e = Enemy(type: 'bat');
    e.position = Vector2(
      50 + _rng.nextDouble() * (size.x - 100),
      50 + _rng.nextDouble() * (size.y - 100),
    );
    enemies.add(e);
    add(e);
  }

  void _spawnPotion() {
    final types = gameVersion >= 3 ? ['hp', 'speed', 'shield'] : ['hp'];
    final type = types[_rng.nextInt(types.length)];
    final p = Potion(type: type);
    p.position = Vector2(
      30 + _rng.nextDouble() * (size.x - 60),
      30 + _rng.nextDouble() * (size.y - 60),
    );
    potions.add(p);
    add(p);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    // Punteggio per sopravvivenza
    _aliveTimer += dt;
    if (_aliveTimer >= 1.0) {
      _aliveTimer -= 1.0;
      score += 1;
    }

    // Spawn pozioni ogni 5 secondi (max 3 attive)
    potionSpawnTimer += dt;
    if (potionSpawnTimer >= 5.0 && potions.length < 3) {
      potionSpawnTimer = 0;
      _spawnPotion();
    }

    // Difficoltà crescente ogni 30 secondi
    difficultyTimer += dt;
    if (difficultyTimer >= 30.0) {
      difficultyTimer = 0;
      speedMultiplier += 0.15;
    }

    // Invincibilità dopo danno
    if (isInvincible) {
      invincibleTimer -= dt;
      if (invincibleTimer <= 0) isInvincible = false;
    }

    // Timer effetti versione 3
    if (gameVersion >= 3) {
      if (hasSpeedBoost) {
        speedBoostTimer -= dt;
        if (speedBoostTimer <= 0) hasSpeedBoost = false;
      }
      if (hasShield) {
        shieldTimer -= dt;
        if (shieldTimer <= 0) hasShield = false;
      }
    }

    // 🚩 NOTA: Il player SA come disegnarsi, muoversi, E gestire le collisioni.
    // In architettura questo si chiama "God Object" — fa tutto lui.
    // → Nel libro (Cap 006) vedremo il Component System che risolve questo.

    // Collisioni player-nemico
    for (final e in enemies) {
      if (player.position.distanceTo(e.position) < 28) {
        if (!isInvincible) {
          // 🚩 NOTA: Quando il nemico tocca il player, decrementiamo HP qui.
          // Ma se volessimo veleno? Scudo? Resistenza al fuoco?
          // Dovremmo toccare QUESTO codice ogni volta.
          // → Nel libro (Cap 040) vedremo il sistema Status Effects modulare.
          if (gameVersion >= 3 && hasShield) {
            hasShield = false;
            shieldTimer = 0;
          } else {
            final damage = (gameVersion >= 2 && e.type == 'bat') ? 1 : 1;
            hp -= damage;
          }
          isInvincible = true;
          invincibleTimer = 1.0;
          if (hp <= 0) {
            hp = 0;
            isGameOver = true;
            add(GameOverScreen(onRestart: _restart));
          }
        }
      }
    }

    // Collisioni player-pozione
    for (final p in List<Potion>.from(potions)) {
      if (player.position.distanceTo(p.position) < 24) {
        if (gameVersion >= 3) {
          // Versione 3: raccogli nell'inventario (max 3 slot)
          if (inventory.length < 3) {
            inventory.add(p.type);
            score += 10;
            potions.remove(p);
            remove(p);
          }
        } else {
          // Versione 1-2: uso immediato
          if (hp < 3) hp += 1;
          score += 10;
          potions.remove(p);
          remove(p);
        }
      }
    }

    hpText.text = _hpString();
    scoreText.text = 'Score: $score';

    // UI inventario versione 3
    if (gameVersion >= 3) {
      scoreText.text = 'Score: $score  │  Inv: ${_invString()}';
    }
  }

  String _invString() {
    if (inventory.isEmpty) return '(vuoto)';
    return inventory.map((t) {
      switch (t) {
        case 'hp':
          return '🔴';
        case 'speed':
          return '🔵';
        case 'shield':
          return '🟡';
        default:
          return '?';
      }
    }).join(' ');
  }

  void _restart() {
    removeAll(children);
    enemies.clear();
    potions.clear();
    onLoad();
  }
}

// ─── PLAYER ───

class Player extends PositionComponent
    with KeyboardHandler, HasGameReference<PrototypeBruttoGame> {
  static const double _baseSpeed = 150;
  final Vector2 _direction = Vector2.zero();

  Player() : super(size: Vector2(24, 40), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Corpo
    add(RectangleComponent(
      size: Vector2(20, 28),
      position: Vector2(2, 12),
      paint: Paint()..color = const Color(0xFF4488FF),
    ));
    // Testa
    add(CircleComponent(
      radius: 8,
      position: Vector2(12, 8),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFFFFDDAA),
    ));
    // Spada
    add(RectangleComponent(
      size: Vector2(4, 18),
      position: Vector2(22, 14),
      paint: Paint()..color = const Color(0xFFCCCCCC),
    ));

    // Indicatore scudo (versione 3)
    if (gameVersion >= 3) {
      add(CircleComponent(
        radius: 22,
        position: Vector2(12, 20),
        anchor: Anchor.center,
        paint: Paint()
          ..color = const Color(0x00000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      ));
    }
  }

  double get _speed {
    double s = _baseSpeed;
    if (gameVersion >= 3 && hasSpeedBoost) s *= 1.6;
    return s;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    position += _direction.normalized() * _speed * dt;

    // Clamp nei bordi
    final gs = game.size;
    position.x = position.x.clamp(12, gs.x - 12);
    position.y = position.y.clamp(20, gs.y - 20);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _direction.setZero();
    if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      _direction.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      _direction.y += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      _direction.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      _direction.x += 1;
    }

    // 🚩 NOTA: Input per usare oggetti nell'inventario (versione 3).
    // Tasti 1-2-3 hardcodati. E se cambiamo layout? E se il giocatore
    // vuole rimappare i tasti? Ogni modifica = toccare questa funzione.
    // → Nel libro (Cap 033) vedremo Input Mapping configurabile.
    if (gameVersion >= 3) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.digit1) _useItem(0);
        if (event.logicalKey == LogicalKeyboardKey.digit2) _useItem(1);
        if (event.logicalKey == LogicalKeyboardKey.digit3) _useItem(2);
      }
    }

    return true;
  }

  void _useItem(int slot) {
    if (slot >= inventory.length) return;
    final item = inventory.removeAt(slot);
    switch (item) {
      case 'hp':
        if (hp < 3) hp += 1;
        break;
      case 'speed':
        hasSpeedBoost = true;
        speedBoostTimer = 5.0;
        break;
      case 'shield':
        hasShield = true;
        shieldTimer = 8.0;
        break;
    }
  }
}

// ─── ENEMY ───

// 🚩 NOTA: Una sola classe Enemy gestisce TUTTI i tipi di nemici.
// Per ora "funziona", ma guarda quanti if(type==...) ci sono dentro.
// → Nel libro (Cap 006, 029) ogni nemico è un Component indipendente.
//   Aggiungi un file, registri il tipo, e il resto del codice non cambia.

class Enemy extends PositionComponent
    with HasGameReference<PrototypeBruttoGame> {
  final String type;
  Vector2 _velocity = Vector2.zero();
  double _changeTimer = 0;
  double _changeInterval = 2;

  // Pipistrello: inseguimento
  bool _chasing = true;
  double _chaseTimer = 0;

  Enemy({required this.type})
      : super(size: Vector2(28, 28), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    if (type == 'slime') {
      // Corpo slime (ovale verde)
      add(RectangleComponent(
        size: Vector2(26, 20),
        position: Vector2(1, 8),
        paint: Paint()..color = const Color(0xFF2D8B2D),
      ));
      add(CircleComponent(
        radius: 13,
        position: Vector2(14, 14),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF2D8B2D),
      ));
      // Occhi
      add(CircleComponent(
        radius: 4,
        position: Vector2(7, 6),
        anchor: Anchor.center,
        paint: Paint()..color = Colors.white,
      ));
      add(CircleComponent(
        radius: 4,
        position: Vector2(21, 6),
        anchor: Anchor.center,
        paint: Paint()..color = Colors.white,
      ));
      add(CircleComponent(
        radius: 2,
        position: Vector2(8, 6),
        anchor: Anchor.center,
        paint: Paint()..color = Colors.black,
      ));
      add(CircleComponent(
        radius: 2,
        position: Vector2(22, 6),
        anchor: Anchor.center,
        paint: Paint()..color = Colors.black,
      ));
    }
    // ╔══════════════════════════════════════════════════════════════════╗
    // ║  🔴 ESPANSIONE 1: AGGIUNGIAMO IL PIPISTRELLO                   ║
    // ║  Guarda come il codice inizia a scricchiolare...                ║
    // ╚══════════════════════════════════════════════════════════════════╝
    if (type == 'bat' && gameVersion >= 2) {
      // Corpo pipistrello
      add(CircleComponent(
        radius: 8,
        position: Vector2(14, 14),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF6B2D8B),
      ));
      // Ala sinistra (triangolo approssimato con rettangolo ruotato)
      add(RectangleComponent(
        size: Vector2(14, 8),
        position: Vector2(-2, 10),
        paint: Paint()..color = const Color(0xFF9B59B6),
      ));
      // Ala destra
      add(RectangleComponent(
        size: Vector2(14, 8),
        position: Vector2(16, 10),
        paint: Paint()..color = const Color(0xFF9B59B6),
      ));
      // Occhi
      add(CircleComponent(
        radius: 2,
        position: Vector2(11, 12),
        anchor: Anchor.center,
        paint: Paint()..color = Colors.red,
      ));
      add(CircleComponent(
        radius: 2,
        position: Vector2(17, 12),
        anchor: Anchor.center,
        paint: Paint()..color = Colors.red,
      ));
    }

    _pickDirection();
  }

  // 🚩 ECCO IL PROBLEMA: per aggiungere UN nemico, abbiamo toccato:
  // - La classe Enemy (aggiunto tipo + if/else nel movement)
  // - La collisione (aggiunto if per danno diverso)
  // - Il rendering (aggiunto if per forma diversa)
  // - Lo spawning (aggiunto probabilità per tipo)
  // Quattro punti del codice modificati per UNA feature.
  // Immagina 10 tipi di nemici: 40 punti da modificare, tutti intrecciati.
  // → Nel libro (Cap 006, 029) ogni nemico è un Component indipendente.

  void _pickDirection() {
    final speed = (type == 'bat' ? 90.0 : 55.0) * speedMultiplier;
    final angle = _rng.nextDouble() * 2 * pi;
    _velocity = Vector2(cos(angle), sin(angle)) * speed;
    _changeInterval = 2 + _rng.nextDouble() * 2;
    _changeTimer = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    if (type == 'bat' && gameVersion >= 2) {
      // Pipistrello: alterna inseguimento e fuga
      _chaseTimer += dt;
      if (_chaseTimer > 3.0) {
        _chasing = !_chasing;
        _chaseTimer = 0;
      }
      final dir = game.player.position - position;
      if (dir.length > 0) {
        dir.normalize();
        if (!_chasing) dir.scale(-1);
        final speed = 90.0 * speedMultiplier;
        position += dir * speed * dt;
      }
    } else {
      // Slime: random walk
      _changeTimer += dt;
      if (_changeTimer >= _changeInterval) _pickDirection();
      position += _velocity * dt;
    }

    // Rimbalza sui bordi
    final gs = game.size;
    if (position.x < 14 || position.x > gs.x - 14) {
      _velocity.x *= -1;
      position.x = position.x.clamp(14, gs.x - 14);
    }
    if (position.y < 14 || position.y > gs.y - 14) {
      _velocity.y *= -1;
      position.y = position.y.clamp(14, gs.y - 14);
    }
  }
}

// ─── POZIONE ───

// ╔══════════════════════════════════════════════════════════════════╗
// ║  🔴🔴 ESPANSIONE 2: AGGIUNGIAMO L'INVENTARIO                   ║
// ║  Ok, qui il castello di carte crolla.                           ║
// ╚══════════════════════════════════════════════════════════════════╝

class Potion extends PositionComponent {
  final String type; // 'hp', 'speed', 'shield'

  Potion({required this.type})
      : super(size: Vector2(16, 22), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final color = switch (type) {
      'hp' => const Color(0xFFFF4444),
      'speed' => const Color(0xFF44AAFF),
      'shield' => const Color(0xFFFFDD44),
      _ => Colors.white,
    };

    // Fiasca
    add(RectangleComponent(
      size: Vector2(10, 14),
      position: Vector2(3, 8),
      paint: Paint()..color = color,
    ));
    // Tappo
    add(CircleComponent(
      radius: 4,
      position: Vector2(8, 6),
      anchor: Anchor.center,
      paint: Paint()..color = color.withValues(alpha: 0.7),
    ));

    // Pulsazione
    add(ScaleEffect.by(
      Vector2.all(1.15),
      EffectController(
        duration: 0.6,
        reverseDuration: 0.6,
        infinite: true,
      ),
    ));
  }
}

// 🚩 NOTA: Il punteggio è un numero. Nessun save tra le sessioni.
// Chiudi l'app e perdi tutto. Come salvi? Dove salvi?
// → Nel libro (Cap 037) vedremo il sistema Save/Load con serializzazione.

// 🚩 RESA DEI CONTI (Versione 3):
// Il file ha ora ~400 righe. Tutto è intrecciato con tutto.
// Aggiungere una SINGOLA feature (es: "la pozione blu non funziona
// se hai già la gialla attiva") richiede di leggere e capire
// l'INTERO file, perché non c'è separazione tra i sistemi.
//
// Il libro dedica capitoli separati a:
// - Inventario come sistema indipendente (Cap 034)
// - Status Effects con stack e durata (Cap 040)
// - UI dell'inventario con drag & drop (Cap 044)
// - Event Bus per comunicazione tra sistemi (Cap 041)
//
// Non perché ci piace complicare — perché è l'UNICO modo
// per mantenere un gioco che cresce oltre le 500 righe.
//
// Questo file è la prova. Hai visto come 3 feature (nemico +
// inventario + effetti) hanno trasformato 150 righe pulite in 400
// righe di spaghetti. Isometric Quest ha 30+ sistemi. Senza
// architettura, sarebbero 10.000 righe in un file solo.
//
// Ora sai perché servono 80 capitoli. Iniziamo. 💪

// ─── GAME OVER SCREEN ───

class GameOverScreen extends PositionComponent
    with TapCallbacks, HasGameReference<PrototypeBruttoGame> {
  final VoidCallback onRestart;

  GameOverScreen({required this.onRestart});

  @override
  Future<void> onLoad() async {
    size = game.size;
    position = Vector2.zero();

    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xBB000000),
    ));

    add(TextComponent(
      text: 'GAME OVER',
      anchor: Anchor.center,
      position: size / 2 - Vector2(0, 30),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    add(TextComponent(
      text: 'Score: $score',
      anchor: Anchor.center,
      position: size / 2 + Vector2(0, 20),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 28),
      ),
    ));

    add(TextComponent(
      text: 'Tap to restart',
      anchor: Anchor.center,
      position: size / 2 + Vector2(0, 60),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white70, fontSize: 18),
      ),
    ));
  }

  @override
  void onTapDown(TapDownEvent event) {
    onRestart();
  }
}
