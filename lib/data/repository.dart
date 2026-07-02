import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';
import 'seed_data.dart';

/// Leitner box → delay before a card is due again.
/// Box 0 = brand new, box 4 = mastered (reviewed rarely).
const _leitnerDelaysMs = <int>[
  0, //           box 0: due immediately
  1 * 86400000, // box 1: 1 day
  3 * 86400000, // box 2: 3 days
  7 * 86400000, // box 3: 1 week
  21 * 86400000, // box 4: 3 weeks
];

/// Single data-access layer over the local SQLite database. Every read is
/// indexed; the app never talks to anything but this class.
class AppRepository {
  AppRepository._(this._db);
  final Database _db;

  static AppRepository? _instance;
  static AppRepository get instance =>
      _instance ?? (throw StateError('AppRepository.open() not awaited'));

  static Future<AppRepository> open() async {
    if (_instance != null) return _instance!;
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, 'nihongo.db'),
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _create,
      onUpgrade: _upgrade,
    );
    return _instance = AppRepository._(db);
  }

  /// v2: kanji set expanded to the full JLPT N5 list (103). Re-seed kanji only;
  /// kana and their progress are untouched.
  static Future<void> _upgrade(Database db, int from, int to) async {
    if (from < 2) {
      await db.delete('progress',
          where:
              'character_id IN (SELECT id FROM characters WHERE type = ?)',
          whereArgs: ['kanji']);
      await db.delete('characters', where: 'type = ?', whereArgs: ['kanji']);
      final batch = db.batch();
      for (final row in seedRows().where((r) => r['type'] == 'kanji')) {
        batch.insert('characters', row);
      }
      await batch.commit(noResult: true);
    }
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE characters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        symbol TEXT NOT NULL,
        reading TEXT NOT NULL,
        meaning TEXT,
        row_label TEXT NOT NULL,
        order_index INTEGER NOT NULL
      )''');
    await db.execute(
        'CREATE INDEX idx_char_type ON characters(type, order_index)');

    await db.execute('''
      CREATE TABLE progress (
        character_id INTEGER PRIMARY KEY REFERENCES characters(id),
        box INTEGER NOT NULL DEFAULT 0,
        correct INTEGER NOT NULL DEFAULT 0,
        incorrect INTEGER NOT NULL DEFAULT 0,
        last_reviewed INTEGER,
        due_at INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute('CREATE INDEX idx_progress_due ON progress(due_at)');

    // Seed once at creation. Batched — one round-trip.
    final batch = db.batch();
    for (final row in seedRows()) {
      batch.insert('characters', row);
    }
    await batch.commit(noResult: true);
  }

  // --- Characters ---------------------------------------------------------

  Future<List<Character>> charactersOfType(String type) async {
    final rows = await _db.query('characters',
        where: 'type = ?', whereArgs: [type], orderBy: 'order_index');
    return rows.map(Character.fromMap).toList();
  }

  Future<Character> character(int id) async {
    final rows =
        await _db.query('characters', where: 'id = ?', whereArgs: [id]);
    return Character.fromMap(rows.first);
  }

  // --- Progress -----------------------------------------------------------

  Future<Progress> progress(int characterId) async {
    final rows = await _db.query('progress',
        where: 'character_id = ?', whereArgs: [characterId]);
    return rows.isEmpty ? const Progress() : Progress.fromMap(rows.first);
  }

  /// Progress for every character of a type, keyed by character id.
  Future<Map<int, Progress>> progressForType(String type) async {
    final rows = await _db.rawQuery('''
      SELECT p.* FROM progress p
      JOIN characters c ON c.id = p.character_id
      WHERE c.type = ?''', [type]);
    return {for (final r in rows) r['character_id'] as int: Progress.fromMap(r)};
  }

  /// Fraction of a type's characters drawn correctly at least once, 0..1.
  Future<double> masteryOfType(String type) async {
    final total = Sqflite.firstIntValue(await _db.rawQuery(
        'SELECT COUNT(*) FROM characters WHERE type = ?', [type]))!;
    if (total == 0) return 0;
    final done = Sqflite.firstIntValue(await _db.rawQuery('''
      SELECT COUNT(*) FROM progress p JOIN characters c ON c.id = p.character_id
      WHERE c.type = ? AND p.box >= 1''', [type]))!;
    return done / total;
  }

  /// Record a review result and reschedule via Leitner.
  /// [correct] promotes one box (up to 4); a miss drops to box 0.
  Future<void> review(int characterId,
      {required bool correct, required int now}) async {
    final cur = await progress(characterId);
    final box =
        correct ? (cur.box + 1).clamp(0, 4) : 0;
    await _db.insert(
      'progress',
      {
        'character_id': characterId,
        'box': box,
        'correct': cur.correct + (correct ? 1 : 0),
        'incorrect': cur.incorrect + (correct ? 0 : 1),
        'last_reviewed': now,
        'due_at': now + _leitnerDelaysMs[box],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
