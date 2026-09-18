import 'package:fluent_lyrics/utils/furigana_helper.dart';
import 'package:fluent_lyrics/utils/qq_kana_helper.dart';
import 'package:flutter_test/flutter_test.dart';

String _render(String line, List<FuriganaAnnotation> annotations) {
  final buffer = StringBuffer();
  var index = 0;
  for (final annotation in annotations) {
    buffer.write(line.substring(index, annotation.start));
    buffer.write('[${annotation.reading}]');
    index = annotation.end;
  }
  buffer.write(line.substring(index));
  return buffer.toString();
}

const _idolKana =
    '1し1きょく1へん1きょく1む1てき1え1がお1あ1し1ひ1み(4689,100)つ(4789,178)1ぬ1かの1じょ1かん1ぺ(9572,265)き(9837,191)1うそ1'
    'きみ1てん1さ(12270,176)い(12446,224)1て(12670,200)き(12870,260)1さ(13938,161)ま(14099,396)2きょう1な(176'
    '20,195)に(17815,169)1た1す1ほん1あそ1い1い1な(23253,179)に(23432,157)1た1な(25218,170)い(25388,192)1しょ1な'
    'に1き1たん1たん1さん1さん1み1み1ひ1みつ1みつ1あ(34147,164)じ(34311,225)1す1あ(38534,203)い(38737,155)1て1こ(39379,'
    '193)た(39572,243)1だ(40575,216)れ(40791,160)1す1わ(44039,186)た(44225,184)し(44409,318)1わ1う(46208'
    ',172)そ(46380,276)1ほん1とう1し1え1こと1ば1ひ(51445,163)と(51608,185)1り1お1す1だ(54984,208)れ(55192,152)1め'
    '1う(56392,161)ば(56553,276)1き(57904,160)み(58064,140)1かん1ぺ(58763,236)き(58999,184)1きゅう1き(59716'
    ',108)ょ(59824,108)く(59933,170)1こん1りん1ざ(61644,205)い(61849,251)1あ(62100,196)ら(62296,301)わ(625'
    '97,203)1いち1ばん1ぼ(64285,264)し(64549,235)1う1か1え1がお1あ(68811,154)い(68965,178)1だれ1かれ1とりこ1ひとみ1こと1'
    'ば1う(75531,212)そ(75743,168)1かん1ぜん1こ1と(80133,209)く(80342,180)1べつ1わ(81596,198)れ(81794,177)1わ('
    '81971,207)れ(82178,155)1ほし1さ(84766,150)ま(84916,177)1ひ1た1やく1すべ1こ1か(88875,368)げ(89243,218)1しゃ'
    '1ら1くさ1ねた1しっ1と1ゆ(94749,107)る(94856,139)1かん1ぺき1きみ1ゆ(96854,148)る(97002,128)1じ1ぶん1ゆる1だ(98696,2'
    '74)れ(98970,166)1つよ1き(99764,148)み(99912,80)1い1がい1み(100429,96)と(100525,147)1だ(101279,189)れ(1'
    '01468,151)1しん1あ(102784,379)が(103163,181)1さ(104760,171)い(104931,212)1きょう1む1て(105963,213)き(1'
    '06176,168)1じ(107289,123)ゃ(107413,123)く(107536,168)1てん1み1あ1いち1ばん1ぼし1や(111256,180)ど(111436,3'
    '14)1よわ1み1し1み1ゆい1いつ1む1に1ほん1もの1と(125142,192)く(125334,164)1い1え1がお1わ1かく1ひ1みつ1あ(131298,177)い(13'
    '1475,143)1う(132447,227)そ(132674,196)1つ1わ(135499,213)た(135712,188)し(135900,198)1あい1なが1あせ1き1'
    'れい1かく1ま(143071,201)ぶ(143272,183)た(143455,384)1うた1おど1ま1わたし1うそ1あい1だ(151590,224)れ(151814,148)'
    '1あ(152551,151)い(152702,185)1だれ1あ(155992,179)い(156171,244)1わ(158463,396)た(158859,257)し(1591'
    '16,183)1う(159676,267)そ(159943,209)1ほん1とう1しん1ぜん1ぶ1て1い1わ(168012,177)た(168189,179)し(168368,28'
    '7)1よ(169373,236)く(169609,376)1ば1とう1しん1だ(171779,342)い(172121,179)1あ(174431,267)い(174698,316'
    ')2きょう1う(177432,306)そ(177738,190)1こと1ば1ほん1とう1ひ1ねが1き(184757,170)み(184927,133)1きみ1い1い1ぜっ1た(19'
    '1330,303)い(191633,238)1う(191871,289)そ(192160,194)1あ(192852,345)い(193197,263)';

const _idolLines = <(int, int, String)>[
  (0, 425, 'アイドル - YOASOBI (ヨアソビ)'),
  (426, 541, '词：Ayase'),
  (543, 703, '曲：Ayase'),
  (703, 741, '编曲：Ayase'),
  (742, 3245, '無敵の笑顔で荒らすメディア'),
  (3610, 6177, '知りたいその秘密ミステリアス'),
  (6185, 9092, '抜けてるとこさえ彼女のエリア'),
  (9260, 11793, '完璧で嘘つきな君は'),
  (11971, 14495, '天才的なアイドル様'),
  (17222, 18940, '今日何食べた?'),
  (18940, 20372, '好きな本は?'),
  (20372, 23253, '遊びに行くならどこに行くの?'),
  (23253, 24596, '何も食べてない'),
  (24776, 26116, 'それは内緒'),
  (26116, 28808, '何を聞かれてものらりくらり'),
  (28938, 30159, 'そう淡々と'),
  (30159, 31496, 'だけど燦々と'),
  (31679, 34536, '見えそうで見えない秘密は蜜の味'),
  (34719, 36063, 'あれもないないない'),
  (36063, 37400, 'これもないないない'),
  (37400, 38534, '好きなタイプは?'),
  (38534, 39164, '相手は?'),
  (39164, 40379, 'さあ答えて'),
  (40415, 44039, '「誰かを好きになることなんて'),
  (44039, 46208, '私分からなくてさ」'),
  (46208, 49099, '嘘か本当か知り得ない'),
  (49099, 52841, 'そんな言葉にまた一人堕ちる'),
  (52996, 54730, 'また好きにさせる'),
  (54984, 57757, '誰もが目を奪われていく'),
  (57904, 60992, '君は完璧で究極のアイドル'),
  (60992, 63549, '金輪際現れない'),
  (63715, 66468, '一番星の生まれ変わり'),
  (67494, 70087, 'その笑顔で愛してるで'),
  (70263, 72911, '誰も彼も虜にしていく'),
  (73085, 75531, 'その瞳がその言葉が'),
  (75531, 78027, '嘘でもそれは完全なアイ'),
  (78822, 81249, 'はいはいあの子は特別です'),
  (81596, 84139, '我々はハナからおまけです'),
  (84284, 87119, 'お星様の引き立て役Bです'),
  (87443, 90440, '全てがあの子のお陰なわけない'),
  (90440, 91025, '洒落臭い'),
  (91025, 93336, '妬み嫉妬なんてないわけがない'),
  (93336, 94275, 'これはネタじゃない'),
  (94275, 95407, 'からこそ許せない'),
  (95407, 97521, '完璧じゃない君じゃ許せない'),
  (97521, 98696, '自分を許せない'),
  (98696, 101172, '誰よりも強い君以外は認めない'),
  (101279, 104080, '誰もが信じ崇めてる'),
  (104080, 107289, 'まさに最強で無敵のアイドル'),
  (107289, 109823, '弱点なんて見当たらない'),
  (109823, 112701, '一番星を宿している'),
  (112892, 115957, '弱いとこなんて見せちゃダメダメ'),
  (115957, 118895, '知りたくないとこは見せずに'),
  (118895, 121755, '唯一無二じゃなくちゃイヤイヤ'),
  (121755, 124411, 'それこそ本物のアイ'),
  (125142, 127848, '得意の笑顔で沸かすメディア'),
  (128230, 131018, '隠しきるこの秘密だけは'),
  (131298, 134359, '愛してるって嘘で積むキャリア'),
  (134721, 137492, 'これこそ私なりの愛だ'),
  (138051, 140724, '流れる汗も綺麗なアクア'),
  (141159, 143839, 'ルビーを隠したこの瞼'),
  (144027, 146975, '歌い踊り舞う私はマリア'),
  (147452, 150194, 'そう嘘はとびきりの愛だ'),
  (151590, 154374, '誰かに愛されたことも'),
  (154548, 157956, '誰かのこと愛したこともない'),
  (157956, 161384, 'そんな私の嘘がいつか'),
  (161384, 165000, '本当になること信じてる'),
  (165184, 167840, 'いつかきっと全部手に入れる'),
  (168012, 171215, '私はそう欲張りなアイドル'),
  (171215, 173731, '等身大でみんなのこと'),
  (173803, 176482, 'ちゃんと愛したいから'),
  (176674, 178820, '今日も嘘をつくの'),
  (179020, 181003, 'この言葉がいつか'),
  (181003, 183157, '本当になる日を願って'),
  (183377, 184578, 'それでもまだ'),
  (184757, 188221, '君と君にだけは言えずにいたけど'),
  (189189, 190448, 'やっと言えた'),
  (190652, 192852, 'これは絶対嘘じゃない'),
  (192852, 194083, '愛してる'),
];

const _endrollKana =
    '1し1111き(1524,48)ょ(1572,48)く(1620,112)1111へん1き(2372,60)ょ(2432,60)く(2492,96)1111じょう1や1とう1て1ひ'
    '(15594,128)と(15722,224)1け(16298,128)つ(16426,232)1ま(16658,216)つ(16874,656)1ち1へん1お(19509,160'
    ')な(19669,280)1かず1かん1ち(21357,163)が(21520,288)1か(22232,352)さ(22584,168)1く1あ1ひろ1あつ1な(28868,19'
    '3)に(29061,263)1い1よ1あ1ま1き1づ1か1だ(36753,208)い(36961,385)1り1そう1お1つ1ゆ(40873,160)が(41033,240)1ぼ('
    '42210,184)く(42394,605)1たち1に1ど1ま(48506,224)じ(48730,448)1ぼ(51450,344)く(51794,192)1わら1あ(59342'
    ',199)と(59541,320)1い(60553,120)ま(60673,216)1さ(60889,128)ら(61017,498)1さ1た1お1なん1ぜん1か(66891,15'
    '2)い(67043,256)1か1こ(68195,200)と(68395,176)1ば1の(69432,160)ろ(69592,224)1か1と1ひ1に(82152,432)く(8'
    '2584,160)1ま(85290,256)ち(85546,144)1あ1ど1しゃ1ぶ1さん1せい1う1う1し1かい1はじ1む1い1み1すう1じ1ら1れつ1か(96298,232)'
    'げ(96530,200)1み1だ1ち1どり1あ(99330,176)し(99506,144)1ひ(99954,208)と(100162,184)1り1あ(100506,200)る('
    '100706,176)1ぼう1れ(102178,744)い(102922,774)1き1れい1は(109020,201)じ(109221,175)1よ(110332,144)ご(1'
    '10476,248)1き1た(120364,144)い(120508,264)1は(120772,208)ず(120980,280)1ぜん1ぶ1と1お(125159,144)も(1'
    '25303,240)1で1き1い1な1ご(129652,224)り(129876,128)1み(130836,184)ず(131020,377)1ひ1び1て1ば(133732,19'
    '2)な(133924,264)1と(149587,128)き(149715,200)1ぼ(149915,120)く(150035,208)1た(150379,232)し(15061'
    '1,120)1お(151234,248)な(151482,135)1み1ら(151994,207)い(152201,169)1み1わ(152914,301)ら(153215,136'
    ')1い(154335,448)た(154783,512)1き1と1ちゅう1た1あ2だ(166561,288)そ(166849,336)く(167185,161)1み1あ(17396'
    '4,160)と(174124,384)1い(175283,152)ま(175435,192)1さ(175627,112)ら(175739,608)1さ1た1お1なん1ぜん1か(18'
    '1627,160)い(181787,248)1か1こと1ば1のろ1か1か(187560,184)か(187744,288)1あ(194896,288)い(195184,480)1ひ'
    '(196104,424)と(196528,360)1む(198758,168)な(198926,312)1ま(199646,248)く(199894,376)1ぎ1あ(205549'
    ',344)い(205893,376)1ひ(206733,448)と(207181,368)1て1ばな';

const _endrollLines = <(int, int, String)>[
  (156, 764, 'ENDROLL - Raon'),
  (764, 1524, '词：5u5h1'),
  (1524, 2275, '曲：5u5h1'),
  (2275, 3145, '编曲：5u5h1'),
  (13211, 17530, '常夜灯が照らしたのは一つの結末'),
  (17705, 19509, '散らばるガラス片と'),
  (19509, 23848, '同じ数の勘違いを重ねてた'),
  (23848, 26260, 'どうにも組み合わさらない'),
  (26260, 28868, 'それを拾い集めて'),
  (28868, 33041, '何も言えぬまま夜明けを待ってた'),
  (33285, 36537, '気付いていたんだろう'),
  (36537, 40873, '過大な理想 押し付けあって'),
  (40873, 47479, '歪めあった僕達のシナリオは'),
  (47479, 50650, 'もう二度と交わらないと'),
  (50650, 54713, 'こんな僕をどうか笑ってくれよ'),
  (54959, 57549, 'もうどうしようもないんだね'),
  (57549, 60553, 'エンドロールのその後に'),
  (60553, 63763, '今更咲いたアネモネ'),
  (63763, 66275, '手折ることもできないんだ'),
  (66275, 69432, '何千回交わした言葉たちも'),
  (69432, 72136, '呪いに変わっていくなら'),
  (72136, 75776, 'それを解くのはきっと'),
  (75776, 78711, 'あなたしかいないよ'),
  (81624, 84282, '皮肉なくらいに'),
  (84282, 86911, 'きらめいた街明かり'),
  (86911, 90207, '土砂降りの酸性雨に打たれ'),
  (90207, 93031, '視界の端っこ'),
  (93279, 96298, '無意味な数字の羅列にさえ'),
  (96298, 98586, '影を見出してしまう'),
  (98586, 103696, '千鳥足で一人歩く まるで亡霊'),
  (104360, 110332, '綺麗なはずの始まりまで'),
  (110332, 114629, '汚れてしまうよ'),
  (116524, 118908, 'もうどうなったっていいだろう'),
  (118908, 121875, 'エピローグは期待外れ'),
  (121875, 125159, 'このまま全部溶かされ'),
  (125159, 127702, '思い出ごと消えたいんだ'),
  (127702, 130836, 'そう言ってあなたの名残ばかり'),
  (130836, 133524, '水をやるような日々だ'),
  (133524, 137139, '手放すなんてずっと'),
  (137139, 139939, 'できるはずもないよ'),
  (149187, 151234, 'あの時 僕ら確かに'),
  (151234, 153959, '同じ未来を見て笑えた'),
  (153959, 156351, 'この痛みは'),
  (156351, 159404, 'どうか消えないでくれ'),
  (159980, 161964, 'ガラガラのレイトショウの'),
  (161964, 163652, 'エンドロールの途中で'),
  (163652, 165660, '立ち上がったあなた'),
  (165721, 169569, 'くだらない蛇足は見たくもないと'),
  (169689, 172345, 'もうどうしようもないんだね'),
  (172345, 175283, 'エンドロールのその後に'),
  (175283, 178506, '今更咲いたアネモネ'),
  (178506, 180979, '手折ることもできないんだ'),
  (180979, 184152, '何千回交わした言葉たちが'),
  (184152, 186896, '呪いに変わったとしても'),
  (186896, 191927, 'それを抱えていくしかないんだ'),
  (192360, 197646, 'バイバイ さよなら愛した人よ'),
  (197646, 202415, 'こんな虚しい幕切れだ'),
  (202981, 208318, 'バイバイ さよなら愛した人よ'),
  (208318, 211854, '手放すなんてずっと'),
  (211854, 213982, 'できるはずもないよ'),
];

void main() {
  group('parseRuns', () {
    test('reads the kanji count in front of each reading', () {
      final runs = QqKanaHelper.parseRuns('1よね1づ1けん1し');
      expect(runs.map((r) => r.kanjiCount), [1, 1, 1, 1]);
      expect(runs.map((r) => r.reading), ['よね', 'づ', 'けん', 'し']);
    });

    test('a compound reading carries the number of kanji it covers', () {
      final runs = QqKanaHelper.parseRuns('1う1そ2きょう1なに');
      expect(runs[2].kanjiCount, 2);
      expect(runs[2].reading, 'きょう');
    });

    test('keeps the karaoke timings and drops them from the reading', () {
      final runs = QqKanaHelper.parseRuns('1ゆ(1547,224)め(1771,153)2な');
      expect(runs.first.reading, 'ゆめ');
      expect(runs.first.timesMs, [1547, 1771]);
      expect(runs.last.reading, 'な');
    });

    test('rejects a payload that is not a list of kana readings', () {
      expect(QqKanaHelper.parseRuns(''), isEmpty);
      expect(QqKanaHelper.parseRuns('1abc'), isEmpty);
      // A zero means a two digit count we do not understand, so the whole
      // payload is refused instead of silently splitting it.
      expect(QqKanaHelper.parseRuns('1よね10づ'), isEmpty);
    });

    test('reads consecutive digits as consecutive padding entries', () {
      final runs = QqKanaHelper.parseRuns('1よね111づ2けん');
      expect(runs.map((r) => r.kanjiCount), [1, 1, 2]);
      expect(runs.map((r) => r.reading), ['よね', 'づ', 'けん']);
    });
  });

  group('annotateLines', () {
    test('annotates one kanji per run when the counts line up', () {
      final lines = [
        const QqKanaLine('米津玄師'),
        const QqKanaLine('本当'),
      ];
      final annotations = QqKanaHelper.annotateLines(
        lines: lines,
        runs: QqKanaHelper.parseRuns('1よね1づ1けん1し1ほん1とう'),
      );

      expect(_render(lines[0].text, annotations[0]), '[よね][づ][けん][し]');
      expect(_render(lines[1].text, annotations[1]), '[ほん][とう]');
    });

    test('skips the kana of the lyrics, which the payload omits', () {
      final lines = [
        const QqKanaLine('無敵の笑顔'),
        const QqKanaLine('アイドル'),
      ];
      final annotations = QqKanaHelper.annotateLines(
        lines: lines,
        runs: QqKanaHelper.parseRuns('1む1てき1え1がお'),
      );

      expect(_render(lines[0].text, annotations[0]), '[む][てき]の[え][がお]');
      expect(annotations[1], isEmpty);
    });

    test('a compound run covers several kanji with one reading', () {
      final lines = [const QqKanaLine('今日何')];
      final annotations = QqKanaHelper.annotateLines(
        lines: lines,
        runs: QqKanaHelper.parseRuns('2きょう1なに'),
      );

      expect(_render(lines[0].text, annotations[0]), '[きょう][なに]');
    });

    test('starts the lyrics after payload entries the caller trimmed away', () {
      // The payload also covers the credit lines; only the lyrics are passed.
      final lines = [const QqKanaLine('無敵の笑顔')];
      final annotations = QqKanaHelper.annotateLines(
        lines: lines,
        runs: QqKanaHelper.parseRuns('1し1きょく1へん1きょく1む1てき1え1がお'),
      );

      expect(_render(lines[0].text, annotations[0]), '[む][てき]の[え][がお]');
    });

    test('uses the kana timings to pick between plausible offsets', () {
      final lines = [
        const QqKanaLine('米津玄師', startMs: 0, endMs: 1000),
        const QqKanaLine('本当', startMs: 1000, endMs: 2000),
      ];
      final annotations = QqKanaHelper.annotateLines(
        lines: lines,
        runs: QqKanaHelper.parseRuns('1よね1づ1けん1し1ほん(1500,200)1とう'),
      );

      expect(_render(lines[0].text, annotations[0]), '[よね][づ][けん][し]');
      expect(_render(lines[1].text, annotations[1]), '[ほん][とう]');
    });

    test('does not annotate when the payload cannot cover the lyrics', () {
      final lines = [const QqKanaLine('米津玄師')];
      final annotations = QqKanaHelper.annotateLines(
        lines: lines,
        runs: QqKanaHelper.parseRuns('1よね1づ'),
      );

      expect(annotations.single, isEmpty);
    });
  });

  group('runs without a reading', () {
    test('are dropped instead of blocking the alignment', () {
      // ENDROLL ships `1し1111きょく`: 詞(し) then three padding entries
      // (the `：5u5h1` of the credit line) then 曲(きょく).
      final runs = QqKanaHelper.parseRuns('1し1111きょく');
      expect(runs.map((r) => r.reading), ['し', 'きょく']);

      final lines = [const QqKanaLine('詞：5u5h1 曲：5u5h1')];
      final annotations = QqKanaHelper.annotateLines(
        lines: lines,
        runs: runs,
      );
      expect(
        _render(lines[0].text, annotations[0]),
        '[し]：5u5h1 [きょく]：5u5h1',
      );
    });
  });

  group('the real アイドル payload', () {
    final runs = QqKanaHelper.parseRuns(_idolKana);
    final lines = [
      for (final (start, end, text) in _idolLines)
        QqKanaLine(text, startMs: start, endMs: end),
    ];

    test('parses every run with its kanji count', () {
      expect(runs.length, 214);
      expect(runs.fold<int>(0, (sum, r) => sum + r.kanjiCount), 216);
      expect(runs[23].kanjiCount, 2);
      expect(runs[23].reading, 'きょう');
    });

    test('annotates the lyrics per kanji, after the credit lines', () {
      final annotations = QqKanaHelper.annotateLines(
        lines: lines,
        runs: runs,
      );

      // The credit lines are covered by the payload's head, so the lyrics
      // start at offset 4 and every line lines up.
      expect(_render(lines[4].text, annotations[4]), '[む][てき]の[え][がお]で[あ]らすメディア');
      expect(
        _render(lines[9].text, annotations[9]),
        '[きょう][なに][た]べた?',
      );
      expect(
        _render(lines[24].text, annotations[24]),
        '[わたし][わ]からなくてさ」',
      );
    });
  });

  group('the real ENDROLL payload', () {
    // Lyrics the runtime sees: the credit lines are trimmed away, while the
    // payload still starts at them.
    final runs = QqKanaHelper.parseRuns(_endrollKana);
    final lines = [
      for (final (start, end, text) in _endrollLines)
        QqKanaLine(text, startMs: start, endMs: end),
    ];
    final displayed = lines.sublist(4);
    final annotations = QqKanaHelper.annotateLines(
      lines: displayed,
      runs: runs,
    );

    test('also aligns when the caller keeps the credit lines', () {
      final untrimmed = QqKanaHelper.annotateLines(lines: lines, runs: runs);
      expect(_render(lines[1].text, untrimmed[1]), '[し]：5u5h1');
      expect(_render(lines[3].text, untrimmed[3]), '[へん][きょく]：5u5h1');
      expect(
        _render(lines[4].text, untrimmed[4]),
        '[じょう][や][とう]が[て]らしたのは[ひと]つの[けつ][まつ]',
      );
    });

    test('parses the single digit counts and skips the padding', () {
      expect(runs.length, 151);
      expect(runs.fold<int>(0, (sum, r) => sum + r.kanjiCount), 152);
      expect(runs.take(4).map((r) => r.reading), [
        'し',
        'きょく',
        'へん',
        'きょく',
      ]);
      expect(runs[125].kanjiCount, 2);
      expect(runs[125].reading, 'だそく');
    });

    test('annotates the lyrics from the payload offset the credits end at', () {
      expect(
        _render(displayed[0].text, annotations[0]),
        '[じょう][や][とう]が[て]らしたのは[ひと]つの[けつ][まつ]',
      );
      expect(
        _render(displayed[25].text, annotations[25]),
        '[ち][どり][あし]で[ひと][り][ある]く まるで[ぼう][れい]',
      );
      expect(
        _render(displayed[43].text, annotations[43]),
        'くだらない[だそく]は[み]たくもないと',
      );
      expect(
        _render(displayed.last.text, annotations.last),
        'できるはずもないよ',
      );
    });
  });
}
