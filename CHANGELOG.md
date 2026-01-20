# 1.1.1

## Neue Features

### Duelle automatisch blockieren
- In den Optionen des Addons gibt es nun eine Checkbox für das automatische ablehnen von duellen

## Bugfixes
### Death Message Parsing
- **Doppelte Todesmeldungen**: Es wurde ein Cooldown für das Senden von Todesmeldungen eingebaut um doppelte Popups und Einträge im Deathlog zu vermeiden

# 1.1.0

## Neue Features

### Death Cause Tracking
- **Last Attack Source**: Addon trackt nun die letzte Angriffsquelle bei Todesfällen
  - Nutzt `COMBAT_LOG_EVENT_UNFILTERED` Event für Echtzeit-Tracking
  - Erfasst SWING_DAMAGE, RANGE_DAMAGE, SPELL_DAMAGE und SPELL_PERIODIC_DAMAGE
  - Wird in Guild Message angehängt: "...gestorben. Gestorben an [Angreifer]"
  - Neue `cause` Eigenschaft im DeathLogData für jeden Tod

### Death Log Verbesserungen
- **Killed By Anzeige**: Death Log Tooltip zeigt nun die Todesursache
  - "Killed by: [Angreifer]" wird in roter Schrift angezeigt (wenn verfügbar)
  - Funktioniert sowohl für eigene Tode als auch für Tode anderer Gildenmitglieder
  - Parst die Todesursache aus Guild Chat Messages für andere Spieler

## Verbesserungen

### Death Announcement
- **Optimierte Text-Position**: Death Message Text leicht nach unten verschoben (Y: 100) für bessere Darstellung

### Level 60 Announcement
- **Sound-Update**: Quest Complete Jingle (Sound 619) statt heroischem Fanfare für angenehmere Akustik

## Bugfixes

### Death Message Parsing
- **Todesursache für andere Spieler**: Behebt Bug wo andere Gildenmitglieder die Todesursache nicht sehen konnten
  - Parser extrahiert nun "Gestorben an [source]" Suffix aus Guild Messages
  - Cause wird korrekt im DeathLogData gespeichert und angezeigt
  - Guild Chat Parsing funktioniert nun mit optionalem Attack Source Suffix

## Code-Qualität

- **Death.lua**: Combat Log Event Handler hinzugefügt (Zeilen 254-268)
  - Tracking von LastAttackSource Variable
  - Guild Message erweitert um Attack Source
  - Parser bereinigt Message vor Pattern Matching
- **Deathlog.lua**: Tooltip erweitert um "Killed by" Anzeige
  - Sanitized cause Display mit roter Textfarbe
- **Test Commands entfernt**: `/testdeath`, `/testlevel60` und `/test60` aus Production Build entfernt

## Technisch

- TOC Version: 1.1.0
- Neue Combat Log Event Registrierung für Attack Source Tracking
- Erweiterte Guild Message Format-Unterstützung

---

# 1.0.5

## Neue Features

### Level 60 Ankündigung
- **Heldenhaftes Level 60**: Neue epische Ankündigung wenn Spieler Level 60 erreichen
  - Großes visuelles Notification-Frame mit goldenem Text
  - Heroischer Quest-Complete Sound (888) für triumphalen Moment
  - Guild Message: "Name (TwitchHandle) hat heldenhaft Level 60 erreicht!"
  - Parsing von Level 60 Messages anderer Spieler aus Guild Chat
  - Duplikatsschutz für mehrfache Ankündigungen
- **Test Command**: `/testlevel60` oder `/test60` zum Testen der Level 60 Ankündigung
- **Neue Datei**: `interfaces/LevelSixtyAnnouncement.lua` für die Level 60 Ankündigung

## Verbesserungen

### Death Notification
- **Optimierte Größe**: Death Notification auf 500x280 vergrößert (gleiche Größe wie Level 60 Notification)
- **Bessere Lesbarkeit**: Schriftgröße auf 16 erhöht für bessere Sichtbarkeit
- **Konsistentes Design**: Gleiche Dimensionen und Positionierung wie Level 60 Notification

## Technisch

- LevelUp.lua erweitert mit Level 60 Handling und Guild Chat Parsing
- TOC Version: 1.0.5

---

# 1.0.2

## Neue Features
- Post-Icon an der Minimap versteckt (funktioniert ggf. nur beim Default UI)

---

# 1.0.0

## Neue Features

### Chat Filter System
- **Guild Member Icons**: SC Icon wird automatisch vor Gildenmitglieder-Namen in allen Chat-Channels angezeigt
  - Unterstützt: Guild, Say, Yell, Party, Raid, Whisper (incoming/outgoing)
  - Hilft Griefer zu identifizieren die versuchen Gildenmitglieder zu imitieren
  - Nutzt GuildCache für effiziente Member-Prüfung
  - Funktioniert mit deutschen und englischen Client-Sprachen

### Deathlog Verbesserungen
- **Kompakteres Design**:
  - Minimale Größe: 250x120 (vorher 350x175)
  - Reduzierte Paddings und Zeilenhöhen
  - Kleinere Icons und Header
- **Optimierte Spalten**: Name 40%, Klasse 40%, Level 20% (vorher 55/30/15)
- **Dual-System für Kompatibilität**:
  - Primär: Addon Messages via `CHAT_MSG_ADDON`
  - Fallback: Guild Chat Parsing
  - Verhindert Konflikte mit HardcoreUnlocked und Deathlog Addon
- **Intelligente Duplikatserkennung**: Prüft letzte 10 Einträge um Doppelungen zu vermeiden

## Bugfixes

- **Deathlog Compatibility**: Behebt Nicht-Aktualisierung wenn andere Deathlog-Addons (z.B. "Deathlog" von CurseForge) parallel laufen
- **Guild Chat Fallback**: Parst nun Guild Chat Messages als Backup wenn Addon Messages blockiert werden

## Code-Qualität

- **ChatFilter.lua**: Neue dedizierte Datei (75 Zeilen)
  - Hooks `ChatFrame.AddMessage` für alle Chat-Frames
  - Pattern-Matching für verschiedene Chat-Formate
  - Effiziente Gildenmitglieder-Prüfung
- **Death.lua**: Guild Chat Fallback Handler hinzugefügt
  - Regex-Pattern für deutsche Death Messages
  - Duplikatsprüfung gegen letzte 10 Einträge
  - Extraktion von Last Words aus Chat

## Technisch

- Neue Dateien: `ChatFilter.lua`
- TOC Update: ChatFilter in Features-Sektion
- Main.lua: ChatFilter-Initialisierung hinzugefügt