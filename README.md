# 🎮 Il Prototipo Brutto

**Un dungeon crawler in un solo file**

## Cos'è?

Un mini gioco top-down completo, scritto **volutamente** con bad practices in un singolo file Dart. Serve a dimostrare *perché* servono 80 capitoli per fare un gioco bene.

Il file contiene **3 versioni progressive**:

| Versione | Cosa aggiunge | Cosa succede al codice |
|----------|--------------|----------------------|
| **1** | Gioco base (player, slime, pozioni) | Funziona! ~150 righe pulite |
| **2** | +1 tipo di nemico (pipistrello) | Il codice inizia a scricchiolare |
| **3** | +inventario con 3 tipi di pozione | Il castello di carte crolla |

## Come eseguire

```bash
cd prototype_brutto
flutter pub get
flutter run
```

## Come switchare tra le 3 versioni

In cima a `lib/main.dart` trovi:

```dart
const int gameVersion = 1; // Cambia a 2 o 3 per le espansioni
```

Cambia il valore e riavvia il gioco.

---

## Autore

**Neo1777**

## Licenza

MIT
