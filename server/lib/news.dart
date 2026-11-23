import 'dart:math';

/// Deterministic fake newsroom. Every story, source and person is fictional.
///
/// The base archive is generated once from a seed. On top of it, every
/// successful page-1 /feed request "publishes" 1–3 fresh stories from a
/// seeded sequence, so a pull-to-refresh visibly brings new content, and two
/// duplicate requests visibly get different answers.
class Newsroom {
  Newsroom({int seed = 42, this.pageSize = 12}) : _rng = Random(seed) {
    final now = DateTime.now().toUtc();
    for (var i = 0; i < 48; i++) {
      final category = _categories[i % _categories.length];
      _archive.add(_story(
        id: 'b$i',
        category: category,
        // Spread the archive over the last ~20 hours, newest first.
        publishedAt: now.subtract(Duration(minutes: 9 + i * 25 + _rng.nextInt(15))),
      ));
    }
  }

  final Random _rng;
  final int pageSize;
  final List<Map<String, Object>> _archive = [];
  final List<Map<String, Object>> _fresh = [];
  int _freshCount = 0;

  /// Publishes 1–3 fresh stories. Called once per page-1 /feed request.
  /// Returns how many were published.
  int publish() {
    final n = 1 + _rng.nextInt(3);
    final now = DateTime.now().toUtc();
    for (var k = 0; k < n; k++) {
      final i = _freshCount++;
      _fresh.insert(
        0,
        _story(
          id: 'f$i',
          category: _categories[(i * 7 + 3) % _categories.length],
          publishedAt: now.subtract(Duration(seconds: k * 20)),
        ),
      );
    }
    return n;
  }

  /// One page of the feed. "top" means every category.
  Map<String, Object> feed(String category, int page) {
    final all = [..._fresh, ..._archive]
        .where((s) => category == 'top' || s['category'] == category)
        .toList();
    final start = (page - 1) * pageSize;
    final items = start >= all.length
        ? <Map<String, Object>>[]
        : all.sublist(start, min(start + pageSize, all.length));
    return {
      'category': category,
      'page': page,
      'hasMore': start + pageSize < all.length,
      'stories': items,
    };
  }

  // ── Story generation ──────────────────────────────────────────────────────

  Map<String, Object> _story({
    required String id,
    required String category,
    required DateTime publishedAt,
  }) {
    final pool = _headlines[category]!;
    final h = pool[_rng.nextInt(pool.length)];
    final place = _pick(_places);
    final org = _pick(_orgs[category]!);
    final person = _pick(_people);
    final n = 3 + _rng.nextInt(9);
    String fill(String s) => s
        .replaceAll('{place}', place)
        .replaceAll('{org}', org)
        .replaceAll('{person}', person)
        .replaceAll('{n}', '$n');

    // 3-5 paragraphs: the opening one, then distinct follow-ups (no repeats).
    final paragraphs = 3 + _rng.nextInt(3);
    final followUps = [..._paragraphs]..shuffle(_rng);
    final body = [
      fill(h.$2),
      for (final p in followUps.take(paragraphs - 1)) fill(p),
    ];
    final words = body.join(' ').split(' ').length;
    return {
      'id': id,
      'title': fill(h.$1),
      'summary': fill(h.$2),
      'body': body,
      'category': category,
      'source': _pick(_sources),
      'author': _pick(_people),
      'publishedAt': publishedAt.toIso8601String(),
      // A comfortable 220 words a minute, never less than 2 minutes.
      'readMinutes': max(2, (words / 220).ceil() + 1),
      'imageUrl': '/images/$id.jpg',
    };
  }

  T _pick<T>(List<T> list) => list[_rng.nextInt(list.length)];
}

const _categories = ['tech', 'markets', 'health', 'science', 'culture'];

const _sources = [
  'The Meridian Post',
  'Northwind Daily',
  'Lumen Review',
  'Harbor & Main',
  'The Quiet Ledger',
  'Atlas Weekly',
];

const _people = [
  'Mara Ellison',
  'Tobias Venn',
  'Ines Okafor',
  'Ruth Calloway',
  'Dev Anand Rao',
  'Saoirse Linde',
  'Emil Haraldsen',
  'Noor Qadri',
  'Felix Montague',
  'Aiko Brandt',
];

const _places = [
  'Port Selwyn',
  'Valemont',
  'Kestrel Bay',
  'Ashford Vale',
  'Lindqvist',
  'New Harrow',
  'Corran Isles',
];

const _orgs = {
  'tech': ['Halcyon Labs', 'Brightwire', 'Quillstone', 'Orbis Systems'],
  'markets': ['Calder & Finch', 'Northgate Capital', 'the Valemont Exchange', 'Ironleaf Bank'],
  'health': ['St. Avery Hospital', 'the Lumen Institute', 'Greywell Clinic', 'Fairmont Health'],
  'science': ['the Kestrel Observatory', 'Arden University', 'the Polar Survey', 'Tidewater Lab'],
  'culture': ['the Hollis Gallery', 'Northlight Theatre', 'the Marrow Festival', 'Ember Records'],
};

/// (headline, opening paragraph) per category.
const _headlines = {
  'tech': [
    ('{org} unveils a battery that charges in {n} minutes',
        'Engineers at {org} say their new cell design trades a little capacity for a dramatic drop in charging time, and early tests in {place} back that up.'),
    ('Inside the quiet race to build smaller, smarter phones',
        'After years of ever-larger screens, a handful of designers at {org} are betting that the next big thing is a phone you can use with one hand again.'),
    ('{org} rewrites its app in a weekend, and nobody noticed',
        'The rewrite was meant to be invisible. According to {person}, who led the effort, that was exactly the point.'),
    ('Why {place} wants its own public cloud',
        'City officials in {place} argue that owning the servers behind public services is cheaper over {n} years than renting them.'),
  ],
  'markets': [
    ('Shares in {org} climb {n}% after an unexpectedly calm quarter',
        'Investors rewarded {org} for doing something rare this season: meeting every one of its own forecasts.'),
    ('The small-town bank that outgrew {place}',
        '{org} began as a two-branch lender in {place}. Today it is one of the most closely watched names on the exchange.'),
    ('Coffee prices hit a {n}-year high as harvests slip',
        'Traders say the rise has less to do with demand than with a string of late frosts across the growing regions.'),
    ('{person} on why patience beats prediction',
        'The veteran fund manager has a simple rule: if she cannot explain a trade to a teenager, she does not make it.'),
  ],
  'health': [
    ('A {n}-minute walk after meals may matter more than you think',
        'Researchers at {org} followed volunteers for a year and found that short, regular walks did more than occasional long ones.'),
    ('{place} trials a nurse-led clinic that never closes',
        'The pilot at {org} puts experienced nurses, not doctors, at the front door, and waiting times have fallen sharply.'),
    ('What a good night’s sleep actually looks like',
        'Sleep scientists at {org} say the number of hours is only half the story. Timing and consistency matter just as much.'),
    ('The surprising comeback of the house call',
        'For a growing number of patients in {place}, the doctor is coming to them again, this time with a tablet and a portable lab.'),
  ],
  'science': [
    ('{org} spots a comet that will pass by in {n} years',
        'Astronomers at {org} caught the faint smudge almost by accident while calibrating a new camera.'),
    ('The seabed off {place} is greener than anyone expected',
        'A survey by {org} found meadows of seagrass stretching for kilometres, quietly storing carbon in the dark.'),
    ('How a {n}-gram robot learned to fly through a forest',
        'Researchers at {org} borrowed tricks from insects to keep their tiny flier steady between branches.'),
    ('A glacier in retreat reveals a forgotten valley',
        'Field teams from {org} are mapping land that has not seen daylight for thousands of years.'),
  ],
  'culture': [
    ('{org} reopens with a show built entirely from letters',
        'Curators spent {n} years collecting handwritten letters from {place}. The result is quieter, and more moving, than its title suggests.'),
    ('The novelist who writes only on trains',
        '{person} has written four books between the same two stations. The fifth, she says, will be the last.'),
    ('Why everyone in {place} is learning to sing together',
        'Weekly community choirs have spread from one church hall to {n} venues in a single year.'),
    ('A film shot in one take, and why it nearly failed',
        'The director spent months rehearsing with {org} for a single continuous shot. On the night, the rain arrived early.'),
  ],
};

const _paragraphs = [
  '“We expected some interest, but not this much,” said {person}, who has been following the project since its first prototype. “People clearly wanted something simpler.”',
  'Not everyone is convinced. Critics point out that similar efforts in {place} stalled after the first year, once the initial funding ran out and attention moved elsewhere.',
  'The next phase will run for {n} months. If the results hold, the team plans to publish everything, including the parts that did not work.',
  'For now, the changes are small and easy to miss. That, supporters argue, is how lasting change usually looks from up close.',
  'Local residents have been cautiously supportive. Many say they will judge it not by the headlines but by whether daily life actually gets easier.',
  'The approach borrows from an idea first tried decades ago, which was abandoned at the time because the tools to measure it simply did not exist.',
  'Funding comes from a mix of public grants and private donors, an arrangement that {org} says gives it room to take a longer view.',
  'Asked what comes next, {person} paused. “Honestly? More of the same, just done a little better each time.”',
];
