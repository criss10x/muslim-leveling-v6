// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_sync.dart';

// Auto-generated from V3 BelajarScreen.kt — do not edit manually.
// 19 modules, +3 modul akidah tambahan (keajaiban angka & bukti lain).

// ─── Data classes ───

class LearningModule {
  final String id, categoryId, title, icon;
  final int estimatedMinutes, xpReward;
  const LearningModule({required this.id, required this.categoryId, required this.title,
      required this.icon, required this.estimatedMinutes, required this.xpReward});
}

class LearningCategory {
  final String id, label, icon;
  final List<LearningModule> modules;
  const LearningCategory({required this.id, required this.label, required this.icon, required this.modules});
}

// ArticleBlock sealed class hierarchy
abstract class ArticleBlock {
  const ArticleBlock();
}
class Heading extends ArticleBlock { final String text; const Heading(this.text); }
class Subheading extends ArticleBlock { final String text; const Subheading(this.text); }
class Paragraph extends ArticleBlock { final String text; const Paragraph(this.text); }
class Highlight extends ArticleBlock { final String text; const Highlight(this.text); }
class EducatorNote extends ArticleBlock { final String text; const EducatorNote(this.text); }
class Cta extends ArticleBlock { final String text; const Cta(this.text); }
class DividerBlock extends ArticleBlock { const DividerBlock(); }

class QuizQuestion {
  final String question, explanation;
  final List<String> options;
  final int correctIndex;
  const QuizQuestion({required this.question, required this.options,
      required this.correctIndex, required this.explanation});
}

class ModuleProgress {
  final String moduleId;
  final bool completed;
  final int quizScore;
  final bool xpClaimed;
  const ModuleProgress({required this.moduleId, this.completed = false,
      this.quizScore = 0, this.xpClaimed = false});
  ModuleProgress copyWith({bool? completed, int? quizScore, bool? xpClaimed}) =>
      ModuleProgress(moduleId: moduleId, completed: completed ?? this.completed,
          quizScore: quizScore ?? this.quizScore, xpClaimed: xpClaimed ?? this.xpClaimed);
  factory ModuleProgress.fromMap(Map<String, dynamic> m) => ModuleProgress(
      moduleId: m['moduleId'] ?? '', completed: m['completed'] ?? false,
      quizScore: m['quizScore'] ?? 0, xpClaimed: m['xpClaimed'] ?? false);
  Map<String, dynamic> toMap() =>
      {'moduleId': moduleId, 'completed': completed, 'quizScore': quizScore, 'xpClaimed': xpClaimed};
}

class LearningState {
  final List<ModuleProgress> progress;
  const LearningState({this.progress = const []});
  LearningState copyWith({List<ModuleProgress>? progress}) =>
      LearningState(progress: progress ?? this.progress);
  factory LearningState.fromMap(Map<String, dynamic> m) => LearningState(
      progress: (m['progress'] as List?)?.map((e) => ModuleProgress.fromMap(e as Map<String, dynamic>)).toList() ?? []);
  Map<String, dynamic> toMap() => {'progress': progress.map((e) => e.toMap()).toList()};
}

// ─── Learning content registry ───

class LearningContent {
  static const categories = <LearningCategory>[
    LearningCategory(
      id: 'akidah',
      label: 'Akidah',
      icon: '🕋',
      modules: [
        LearningModule(
          id: 'akidah_1.1',
          categoryId: 'akidah',
          title: 'Kenapa Harus Percaya Ada Tuhan?',
          icon: '🌌',
          estimatedMinutes: 4,
          xpReward: 200,
        ),
        LearningModule(
          id: 'akidah_1.2',
          categoryId: 'akidah',
          title: 'Kenapa Allah Itu Esa (Tauhid)?',
          icon: '☝️',
          estimatedMinutes: 5,
          xpReward: 200,
        ),
        LearningModule(
          id: 'akidah_1.3',
          categoryId: 'akidah',
          title: 'Al-Quran: Firman Tuhan, Bukan Karangan Manusia',
          icon: '📖',
          estimatedMinutes: 6,
          xpReward: 200,
        ),
        LearningModule(
          id: 'akidah_1.4',
          categoryId: 'akidah',
          title: 'Siapa Itu Nabi Muhammad ﷺ?',
          icon: '🫶',
          estimatedMinutes: 4,
          xpReward: 200,
        ),
        LearningModule(
          id: 'akidah_1.5',
          categoryId: 'akidah',
          title: 'Apa Itu Iman dan Rukun Iman?',
          icon: '💎',
          estimatedMinutes: 5,
          xpReward: 200,
        ),
        LearningModule(
          id: 'akidah_1.6',
          categoryId: 'akidah',
          title: 'Keajaiban Angka dalam Al-Quran (Bagian 1)',
          icon: '🔢',
          estimatedMinutes: 7,
          xpReward: 200,
        ),
        LearningModule(
          id: 'akidah_1.7',
          categoryId: 'akidah',
          title: 'Keajaiban Angka dalam Al-Quran (Bagian 2)',
          icon: '🧮',
          estimatedMinutes: 7,
          xpReward: 200,
        ),
        LearningModule(
          id: 'akidah_1.8',
          categoryId: 'akidah',
          title: 'Masih Banyak Bukti Lain: Al-Quran Benar Firman Allah',
          icon: '🔬',
          estimatedMinutes: 8,
          xpReward: 250,
        ),
      ],
    ),
    LearningCategory(
      id: 'rukun_islam',
      label: 'Rukun Islam',
      icon: '🕌',
      modules: [
        LearningModule(
          id: 'rukun_2.1',
          categoryId: 'rukun_islam',
          title: '5 Rukun Islam: Fondasi Hidup Seorang Muslim',
          icon: '⭐',
          estimatedMinutes: 5,
          xpReward: 200,
        ),
        LearningModule(
          id: 'rukun_2.2',
          categoryId: 'rukun_islam',
          title: 'Syahadat: Gerbang Pertama',
          icon: '🚪',
          estimatedMinutes: 4,
          xpReward: 200,
        ),
        LearningModule(
          id: 'rukun_2.3',
          categoryId: 'rukun_islam',
          title: 'Kenapa Harus Puasa Ramadan?',
          icon: '🌙',
          estimatedMinutes: 5,
          xpReward: 200,
        ),
        LearningModule(
          id: 'rukun_2.4',
          categoryId: 'rukun_islam',
          title: 'Zakat: Kenapa Harus Berbagi?',
          icon: '💰',
          estimatedMinutes: 4,
          xpReward: 200,
        ),
        LearningModule(
          id: 'rukun_2.5',
          categoryId: 'rukun_islam',
          title: 'Haji: Perjalanan Sekali Seumur Hidup',
          icon: '🕋',
          estimatedMinutes: 4,
          xpReward: 200,
        ),
      ],
    ),
    LearningCategory(
      id: 'praktik_ibadah',
      label: 'Praktik Ibadah',
      icon: '🤲',
      modules: [
        LearningModule(
          id: 'praktik_3.1',
          categoryId: 'praktik_ibadah',
          title: 'Wudhu: Bersih-Bersih Sebelum Menghadap Allah',
          icon: '💧',
          estimatedMinutes: 5,
          xpReward: 200,
        ),
        LearningModule(
          id: 'praktik_3.2',
          categoryId: 'praktik_ibadah',
          title: 'Syarat Sah & Rukun Sholat',
          icon: '📋',
          estimatedMinutes: 4,
          xpReward: 200,
        ),
        LearningModule(
          id: 'praktik_3.3',
          categoryId: 'praktik_ibadah',
          title: 'Tata Cara Sholat Step-by-Step',
          icon: '🧎',
          estimatedMinutes: 8,
          xpReward: 200,
        ),
        LearningModule(
          id: 'praktik_3.4',
          categoryId: 'praktik_ibadah',
          title: 'Bacaan-Bacaan Penting dalam Sholat',
          icon: '📝',
          estimatedMinutes: 5,
          xpReward: 200,
        ),
        LearningModule(
          id: 'praktik_3.5',
          categoryId: 'praktik_ibadah',
          title: 'Sholat 5 Waktu: Kapan dan Berapa Rakaat?',
          icon: '⏰',
          estimatedMinutes: 3,
          xpReward: 200,
        ),
        LearningModule(
          id: 'praktik_3.6',
          categoryId: 'praktik_ibadah',
          title: 'Hal-Hal yang Sering Bikin Bingung Pemula',
          icon: '❓',
          estimatedMinutes: 5,
          xpReward: 200,
        ),
      ],
    ),
  ];

  static List<LearningModule> getAllModulesOrdered() =>
      categories.expand((c) => c.modules).toList();

  static bool isModuleUnlocked(String moduleId, List<ModuleProgress> progress) {
    for (final cat in categories) {
      final idx = cat.modules.indexWhere((m) => m.id == moduleId);
      if (idx >= 0) {
        if (idx == 0) return true;
        final prev = cat.modules[idx - 1];
        return progress.any((p) => p.moduleId == prev.id && p.completed);
      }
    }
    return false;
  }

  static List<ArticleBlock> getArticle(String moduleId) {
    switch (moduleId) {
      case 'akidah_1.1': return _akidah1_1Article;
      case 'akidah_1.2': return _akidah1_2Article;
      case 'akidah_1.3': return _akidah1_3Article;
      case 'akidah_1.4': return _akidah1_4Article;
      case 'akidah_1.5': return _akidah1_5Article;
      case 'akidah_1.6': return _akidah1_6Article;
      case 'akidah_1.7': return _akidah1_7Article;
      case 'akidah_1.8': return _akidah1_8Article;
      case 'rukun_2.1': return _rukun2_1Article;
      case 'rukun_2.2': return _rukun2_2Article;
      case 'rukun_2.3': return _rukun2_3Article;
      case 'rukun_2.4': return _rukun2_4Article;
      case 'rukun_2.5': return _rukun2_5Article;
      case 'praktik_3.1': return _praktik3_1Article;
      case 'praktik_3.2': return _praktik3_2Article;
      case 'praktik_3.3': return _praktik3_3Article;
      case 'praktik_3.4': return _praktik3_4Article;
      case 'praktik_3.5': return _praktik3_5Article;
      case 'praktik_3.6': return _praktik3_6Article;
      default: return const [];
    }
  }

  static List<QuizQuestion> getQuiz(String moduleId) {
    switch (moduleId) {
      case 'akidah_1.1': return _akidah1_1Quiz;
      case 'akidah_1.2': return _akidah1_2Quiz;
      case 'akidah_1.3': return _akidah1_3Quiz;
      case 'akidah_1.4': return _akidah1_4Quiz;
      case 'akidah_1.5': return _akidah1_5Quiz;
      case 'akidah_1.6': return _akidah1_6Quiz;
      case 'akidah_1.7': return _akidah1_7Quiz;
      case 'akidah_1.8': return _akidah1_8Quiz;
      case 'rukun_2.1': return _rukun2_1Quiz;
      case 'rukun_2.2': return _rukun2_2Quiz;
      case 'rukun_2.3': return _rukun2_3Quiz;
      case 'rukun_2.4': return _rukun2_4Quiz;
      case 'rukun_2.5': return _rukun2_5Quiz;
      case 'praktik_3.1': return _praktik3_1Quiz;
      case 'praktik_3.2': return _praktik3_2Quiz;
      case 'praktik_3.3': return _praktik3_3Quiz;
      case 'praktik_3.4': return _praktik3_4Quiz;
      case 'praktik_3.5': return _praktik3_5Quiz;
      case 'praktik_3.6': return _praktik3_6Quiz;
      default: return const [];
    }
  }
}

// ─── Article content ───

const _akidah1_1Article = <ArticleBlock>[
  Heading('Kenapa Harus Percaya Ada Tuhan?'),
  Paragraph('Oke, sebelum ngomongin sholat, puasa, atau ibadah lainnya — kita perlu jawab pertanyaan paling dasar dulu: "Emangnya Tuhan itu ada?"'),
  Paragraph('Ini pertanyaan yang wajar banget. Justru bagus kalau kamu mau mikirin ini, karena artinya kamu serius mau cari kebenaran. Yuk kita bahas pakai logika sederhana.'),
  DividerBlock(),
  Subheading('🔍 Argumen 1: Desain Alam Semesta'),
  Paragraph('Coba lihat sekeliling kamu. HP yang kamu pegang sekarang — ada layar, prosesor, kamera, baterai. Secanggih itu. Tapi kamu tahu kan pasti ADA yang merancang? Gak mungkin komponen-komponen itu tiba-tiba nongol sendiri dari kosong.'),
  Paragraph('Sekarang bayangin: alam semesta ini JAUH lebih kompleks dari HP. Ada triliunan galaksi, masing-masing punya miliaran bintang. Gravitasi, kecepatan cahaya, siklus air, fotosintesis — semuanya bekerja dengan presisi gila. Kalau HP aja butuh perancang, masa alam semesta yang jauh lebih canggih ini kebetulan ada sendiri?'),
  Highlight('HP aja butuh yang merancang. Alam semesta? Jauh lebih kompleks.'),
  DividerBlock(),
  Subheading('⛓️ Argumen 2: Sebab-Akibat'),
  Paragraph('Ini hukum paling basic di dunia: segala sesuatu pasti punya penyebab. Meja ada karena ada yang bikin. Pohon tumbuh karena ada biji. Kamu ada karena ada orang tua.'),
  Paragraph('Kalau kita telusuri terus ke belakang — siapa yang bikin X, siapa yang bikin Y — pasti harus berhenti di satu titik: sesuatu yang GAK butuh penyebab lain. Sesuatu yang udah ada dari awal. Itulah yang kita sebut Tuhan.'),
  Paragraph('Bayangin kayak rantai: kalau setiap mata rantai bergantung pada rantai sebelumnya, siapa yang nge-link pertama? Pasti ada sesuatu yang bukan rantai, tapi jadi sumber dari semua rantai itu.'),
  DividerBlock(),
  Subheading('🎯 Argumen 3: Keteraturan Gak Mungkin Kebetulan'),
  Paragraph('Coba lempar koin 100 kali. Berapa kali kamu bisa dapat muka semua? Hampir mustahil. Sekarang bayangin: alam semesta ini punya HUKUM yang bekerja konsisten selama miliaran tahun. Gravitasi gak pernah libur. Atom gak pernah ngawur. Siklus siang-malam gak pernah telat.'),
  Paragraph('Keteraturan se-ekstrem ini tanpa Perancang? Itu kayak bilang novel yang udah jadi muncul dari ledakan di percetakan. Logikanya gak nyambung.'),
  Highlight('Keteraturan alam = bukti kuat ada Perancang di balik semuanya.'),
  DividerBlock(),
  Subheading('💡 Jadi...?'),
  Paragraph('Percaya pada Tuhan bukan soal "harus percaya buta". Justru logika dan akal sehat kita ngasih tanda-tanda yang kuat: ada Perancang di balik semua ini.'),
  Paragraph('Dan kalau memang ada yang merancang alam semesta se-kompleks ini, pasti dong Dia punya tujuan? Pasti dong Dia ngasih petunjuk? Nah, itu yang bakal kita bahas di modul-modul selanjutnya.'),
  EducatorNote('"Sesungguhnya dalam penciptaan langit dan bumi, dan pergantian malam dan siang terdapat tanda-tanda bagi orang yang berakal." (QS. Ali Imran: 190)'),
  Cta('Kamu udah selesai baca! Sekarang coba jawab kuisnya buat klaim XP. 🎯'),
];

const _akidah1_2Article = <ArticleBlock>[
  Heading('Kenapa Allah Itu Esa (Tauhid)?'),
  Paragraph('Oke, di modul sebelumnya kita udah bahas kalau ada Perancang di balik alam semesta. Pertanyaan selanjutnya: "Emangnya cuma satu? Bisa dong lebih dari satu?"'),
  Paragraph('Pertanyaan ini penting banget, karena jawabannya ngaruh ke cara kita ngelihat seluruh alam semesta. Yuk kita bahas pakai logika yang sama — santai, gak ribet.'),
  DividerBlock(),
  Subheading('🚗 Analogi: Dua Sopir, Satu Kemudi'),
  Paragraph('Bayangin kamu naik mobil. Tiba-tiba ada DUA orang yang megang kemudi. Yang satu mau belok kiri, yang satu mau belok kanan. Apa yang terjadi? Kecelakaan. Kacau. Gak ada yang sampai tujuan.'),
  Paragraph('Sekarang bayangin alam semesta ini. Ada jutaan hukum fisika yang bekerja bersamaan dengan super presisi — gravitasi, elektromagnetik, gaya nuklir kuat dan lemah. Semuanya saling melengkapi, gak konflik satu sama lain.'),
  Paragraph('Kalau ada DUA "Tuhan" dengan kehendak berbeda, pasti ada tabrakan di suatu titik. Satu mau atur gravitasi naik, satu mau turun. Satu mau bikin air mengalir ke bawah, satu mau ke atas. Hasilnya? Kekacauan.'),
  Highlight('Tapi kenyataannya: alam semesta ini rapi banget. Konsisten miliaran tahun. Itu cuma mungkin kalau ADA SATU sumber kehendak.'),
  DividerBlock(),
  Subheading('🔬 Bukti dari Keteraturan Kosmos'),
  Paragraph('Para ilmuwan udah mengamati alam semesta selama ratusan tahun. Dan yang mereka temuin: hukum-hukum alam itu UNIVERSAL. Gravitasi di Bumi sama dengan gravitasi di galaksi lain. Kecepatan cahaya konstan di mana pun.'),
  Paragraph('Kalau ada lebih dari satu "pengatur", mustahil keteraturan ini bisa terjaga konsisten. Bayangin: satu perusahaan aja kalau ada dua CEO yang visinya beda, pasti karyawan bingung. Apalagi alam semesta.'),
  Paragraph('Jadi logikanya: kalau alam semesta ini teratur dan konsisten, sumbernya pasti SATU. Satu Perancang. Satu Pengatur. Dalam Islam, itu disebut Allah — yang Esa, gak berbilang.'),
  DividerBlock(),
  Subheading('📜 Tauhid di Awal Sejarah'),
  Paragraph('Menariknya, konsep "Tuhan itu Esa" bukan cuma ajaran Islam. Di awal sejarahnya, hampir semua agama besar ngajarin Tauhid — bahwa Tuhan itu satu.'),
  Paragraph('Nabi Ibrahim ajarin Tauhid. Nabi Musa ajarin Tauhid. Nabi Isa ajarin Tauhid. Tapi seiring waktu, ajaran itu berubah karena campur tangan manusia. Islam datang sebagai penyempurnaan — mengembalikan ajaran Tauhid murni yang udah ada sejak awal.'),
  Highlight('Tauhid itu ajaran paling tua dalam sejarah manusia. Islam bukan "agama baru" — Islam adalah Tauhid yang asli.'),
  DividerBlock(),
  Subheading('📖 Ayat Al-Qur\'an: Surat Al-Ikhlas'),
  Paragraph('Surat Al-Ikhlas (QS. 112) adalah inti dari konsep Tauhid. Cuma 4 ayat, tapi isinya ngejelasin konsep ke-Esa-an Allah secara sempurna:'),
  EducatorNote('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\n\nقُلْ هُوَ اللَّهُ أَحَدٌ ١\nQul huwallahu ahad. (1)\nKatakanlah: Dia-lah Allah, Yang Maha Esa.\n\nاللَّهُ الصَّمَدُ ٢\nAllahus-samad. (2)\nAllah tempat meminta segala sesuatu.\n\nلَمْ يَلِدْ وَلَمْ يُولَدْ ٣\nLam yalid wa lam yuulad. (3)\nDia tidak beranak dan tidak pula diperanakkan.\n\nوَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ ٤\nWa lam yakun lahu kufuwan ahad. (4)\nDan tidak ada sesuatu pun yang setara dengan Dia.'),
  Paragraph('"Al-Ahad" artinya Yang Maha Esa — bener-bener satu, gak ada duanya, gak ada yang nyamain. "As-Samad" artinya tempat bergantung segala sesuatu — Dia gak butuh siapa-siapa, tapi semua yang ada butuh Dia.'),
  Paragraph('"Tidak beranak dan tidak diperanakkan" artinya Dia gak lahir dari siapa pun dan gak melahirkan siapa pun. Dia ada tanpa sebab — karena Dia SEBAB dari segalanya.'),
  DividerBlock(),
  Subheading('💡 Kesimpulan'),
  Paragraph('Tauhid itu sederhana: Allah itu SATU. Esa. Gak ada duanya. Dan itu bukan cuma soal iman — tapi juga logika. Alam semesta yang teratur ini cuma mungkin kalau sumbernya satu.'),
  Paragraph('Di modul berikutnya, kita bakal bahas: kalau Allah udah ada dan Esa, terus apa hubungannya sama kita? Dia ngurus kita gak sih? Stay tuned.'),
  Cta('Selesai baca! Saatnya kuis. Kamu pasti bisa. 🎯'),
];

const _akidah1_3Article = <ArticleBlock>[
  Heading('Al-Quran: Firman Tuhan, Bukan Karangan Manusia'),
  Paragraph('Kita udah bahas kalau Tuhan itu ada dan Esa. Pertanyaan berikutnya yang wajar banget: "Oke, kalau Tuhan ada — dia ngomong sama kita gak? Ada buktinya?"'),
  Paragraph('Kalau kamu Muslim, kamu pasti dengar "Al-Quran itu firman Allah." Tapi kenapa bisa yakin? Apa bedanya sama buku biasa? Yuk kita lihat beberapa hal yang menarik — kamu nilai sendiri.'),
  DividerBlock(),
  Subheading('1️⃣ Nabi Muhammad ﷺ Gak Bisa Baca-Tulis'),
  Paragraph('Ini fakta sejarah yang diterima luas oleh para sejarawan, baik Muslim maupun non-Muslim: Muhammad ﷺ itu ummi — gak bisa baca, gak bisa tulis. Tumbuh di jazirah Arab abad ke-7, di mana tingkat literasi sangat rendah.'),
  Paragraph('Sekarang bayangin: orang yang gak pernah baca buku, gak pernah sekolah, gak pernah belajar sastra atau sains — tiba-tiba menghasilkan teks sepanjang 30 juz (6.000+ ayat) dengan bahasa Arab paling tinggi tingkat sastranya, isi yang konsisten, dan pembahasan yang mencakup hukum, sejarah, sains, filsafat, dan spiritualitas.'),
  Highlight('Secara logika: kalau kamu gak pernah belajar coding, bisakah kamu tiba-tiba bikin app sekompleks Gojek? Sama halnya dengan Al-Quran.'),
  DividerBlock(),
  Subheading('2️⃣ Keajaiban Bahasa (I\'jaz)'),
  Paragraph('Al-Quran itu bukan cuma soal isinya — bahasanya pun di luar kemampuan manusia biasa. Zaman Nabi ﷺ, bangsa Arab terkenal sebagai bangsa sastrawan. Puisi dan pidato itu olahraga nasional mereka.'),
  Paragraph('Tapi ketika Al-Quran dibacakan, para penyair terbaik Arab pada saat itu — yang udah bertahun-tahun bikin puisi — gak bisa menandinginya. Bahkan mereka mengakui: ini bukan karya manusia.'),
  Paragraph('Al-Quran sendiri menantang terbuka: "Coba bikin 1 surah semisal ini kalau kamu sanggup." (QS. Al-Baqarah: 23). Tantangan itu udah ada selama 1.400 tahun. Belum ada yang berhasil.'),
  DividerBlock(),
  Subheading('3️⃣ Diwahyukan 23 Tahun, Tanpa Kontradiksi'),
  Paragraph('Bayangin kamu nulis buku — tapi gak sekaligus. Kamu nulisnya sedikit-sedikit selama 23 TAHUN. Di rumah, di perjalanan, di saat perang, di saat damai, di saat senang, di saat susah.'),
  Paragraph('Teks yang dihasilkan harus konsisten. Gak boleh ada yang saling bertentangan. Gak boleh lupa apa yang udah ditulis sebelumnya. Dan harus relevan dengan kejadian yang sedang terjadi saat itu.'),
  Paragraph('Al-Quran diwahyukan selama 23 tahun, di kondisi yang sangat berbeda-beda — dari Makkah (minoritas tertindas) sampai Madinah (memimpin negara). Tapi isinya konsisten. Gak ada kontradiksi internal. Cobain nulis jurnal 23 tahun tanpa pernah kontradiksi diri sendiri — susah banget kan?'),
  Highlight('23 tahun. Ribuan ayat. Berbagai kondisi. Nol kontradiksi. Coba lakuin itu pakai buku catatanmu.'),
  DividerBlock(),
  Subheading('4️⃣ Satu-Satunya Kitab Suci yang Teksnya Terjaga 100%'),
  Paragraph('Ini fakta yang jarang orang sadari: hampir semua kitab suci di dunia pernah mengalami perubahan teks seiring waktu. Manuskrip lama ditemukan dengan variasi. Ada penambahan, pengurangan, atau perbedaan antar versi.'),
  Paragraph('Al-Quran? Dari awal diturunkan sampai sekarang — 1.400+ tahun — teksnya IDENTIK. Gak ada perbedaan satu huruf pun. Kenapa? Karena Al-Quran dijaga dengan dua cara: ditulis DAN dihafal.'),
  Paragraph('Saat ini ada JUTAAN orang di seluruh dunia yang hafal seluruh 30 juz Al-Quran dari luar. Kalau semua mushaf di dunia hilang sekalipun, Al-Quran bisa ditulis ulang 100% persis sama dari hafalan mereka.'),
  Paragraph('Gak ada kitab suci lain yang punya sistem preservasi se-ekstrem ini. Ini bukan soal iman — ini fakta historis yang bisa diverifikasi.'),
  DividerBlock(),
  Subheading('5️⃣ Informasi yang "Gak Mungkin Diketahui" di Abad ke-7'),
  Paragraph('Al-Quran berisi beberapa hal yang menarik — sesuatu yang baru bisa diverifikasi oleh sains modern, tapi udah disebutkan 14 abad lalu. Contoh:'),
  Paragraph('• Perkembangan janin secara bertahap (QS. Al-Mu\'minun: 12-14) — menggambarkan tahapan embrio dengan detail yang baru bisa diamati lewat mikroskop modern.'),
  Paragraph('• Alam semesta yang mengembang (QS. Adz-Dzariyat: 47) — "Dan langit itu Kami bangun dengan kekuatan dan sesungguhnya Kami benar-benar meluaskannya." Fakta ini baru ditemukan astronom Edwin Hubble tahun 1929.'),
  Paragraph('• Siklus air (QS. Az-Zumar: 21) — menggambarkan proses penguapan, pembentukan awan, dan turunnya hujan secara ilmiah, jauh sebelum meteorologi modern.'),
  EducatorNote('Catatan penting: ini bukan klaim "Al-Quran = buku sains." Al-Quran adalah kitab petunjuk. Tapi ayat-ayat ini menarik untuk direnungkan — bagaimana seseorang di abad ke-7 bisa tahu hal-hal ini tanpa alat modern? Worth thinking about.'),
  DividerBlock(),
  Subheading('6️⃣ Tantangan Terbuka yang Belum Terjawab'),
  Paragraph('Al-Quran punya satu tantangan yang gak pernah berubah selama 1.400 tahun: "Buatlah satu surah semisal Al-Quran." (QS. Yunus: 38, Al-Baqarah: 23-24, Hud: 13)'),
  Paragraph('Tantangan ini bukan cuma soal bikin puisi bagus. Kriterianya: harus dalam bahasa Arab yang setara, isinya harus konsisten, harus punya hukum dan petunjuk, dan harus bisa meyakinkan jutaan orang selama berabad-abad.'),
  Paragraph('Selama 14 abad, banyak yang mencoba. Hasilnya? Gak ada yang bertahan. Para pakar sastra Arab sendiri mengakui: gaya bahasa Al-Quran itu unik — bukan puisi, bukan prosa, bukan pidato. Kategorinya sendiri.'),
  DividerBlock(),
  Subheading('💭 Refleksi'),
  Paragraph('Kamu gak harus langsung percaya semua ini. Gak ada yang maksa. Justru bagus kalau kamu mau renungkan pelan-pelan, tanya-tanya, cari tahu sendiri.'),
  Paragraph('Yang menarik: semua poin di atas — ummi, i\'jaz, 23 tahun konsistensi, preservasi, informasi ilmiah, tantangan terbuka — ini bukan satu argumen lemah. Ini banyak argumen yang saling menguatkan.'),
  Paragraph('Dan kalau memang Al-Quran beneran dari Tuhan — maka isinya layak banget dibaca pelan-pelan. Mungkin itu langkah berikutnya.'),
  Cta('Kamu udah selesai baca! Sekarang coba jawab kuisnya. 🎯'),
];

const _akidah1_4Article = <ArticleBlock>[
  Heading('Siapa Itu Nabi Muhammad ﷺ?'),
  Paragraph('Di modul sebelumnya kita bahas Al-Quran. Sekarang pertanyaan alamiah: siapa orang yang nrima wahyu itu? Kenapa jutaan orang percaya dia utusan Tuhan?'),
  Paragraph('Kita gak bakal cerita panjang lebar soal sejarah hidupnya — itu buku tersendiri. Tapi ada beberapa hal tentang Muhammad ﷺ yang menarik banget dan worth kamu tahu.'),
  DividerBlock(),
  Subheading('🤝 Al-Amin — "Yang Terpercaya"'),
  Paragraph('Sebelum jadi nabi di usia 40 tahun, Muhammad ﷺ udah tinggal di Makkah selama 40 tahun. Dan julukannya? Al-Amin — artinya "yang terpercaya." Bukan dikasih sama Muslim, tapi sama seluruh masyarakat Makkah, termasuk yang gak seiman.'),
  Paragraph('Orang-orang nitip barang berharga sama dia. Mau nyari solusi sengketa? Datang ke Muhammad. Musuh-musuhnya aja — yang kemudian mau ngebunuh dia — sebelum kenal Islam, mereka TETEP percaya dia orang jujur. Bahkan Abu Sufyan, salah satu musuh terbesarnya, ketika ditanya Romawi: "Pernahkah dia berbohong?" Jawab: "Tidak."'),
  Highlight('Bayangin: orang yang mau ngebunuh kamu aja ngakuin kamu gak pernah bohong. Seberapa kuat kredibilitas seseorang kalau musuhnya aja ngakuin kejujurannya?'),
  DividerBlock(),
  Subheading('📖 Kenapa Dipercaya Utusan Terakhir?'),
  Paragraph('Beberapa alasan kenapa umat Islam percaya Muhammad ﷺ itu utusan terakhir:'),
  Paragraph('• Al-Quran sendiri yang mengklaim — dan Al-Quran punya bukti keasliannya (yang udah kita bahas di modul sebelumnya).'),
  Paragraph('• Konsistensi karakter — dari muda sampai wafat, gak pernah ada catatan dia berbohong, meskipun itu bisa nguntungin dia secara politik.'),
  Paragraph('• Nubuatan di kitab-kitab sebelumnya — Taurat dan Injil menyebutkan akan datang nabi setelah Musa dan Isa. Banyak ciri-cirinya cocok sama Muhammad ﷺ.'),
  Paragraph('• Kehidupannya terdokumentasi super detail — Hadits (catatan perkataan dan perbuatannya) itu jutaan, diriwayatkan dengan rantai periwayatan yang bisa ditelusuri. Gak ada tokoh sejarah lain yang hidupnya tercatat se-detail ini.'),
  DividerBlock(),
  Subheading('⚖️ Nabi vs Tokoh Agama Lain'),
  Paragraph('Yang bikin nabi beda dari tokoh agama lain: nabi mengklaim langsung dapat pesan dari Tuhan. Tokoh agama biasanya mengaku punya ilham atau inspirasi, tapi nabi bilang: "Tuhan ngomong langsung ke saya, dan saya harus sampaikan ke kalian."'),
  Paragraph('Muhammad ﷺ juga beda dari nabi-nabi sebelumnya: dia nabi terakhir. Gak ada nabi setelah dia. Dan risalahnya bukan buat satu kaum aja — tapi buat seluruh manusia, sampai kiamat.'),
  Paragraph('Yang menarik: meskipun jadi pemimpin negara dan panglima perang, hidupnya tetep sederhana. Kasurnya dari tikar, makannya sering cuma kurma dan air. Gak kayak raja atau diktator yang hidup mewah. Kekuasaannya gak dipake buat diri sendiri.'),
  Highlight('Karakter Muhammad ﷺ: jujur sebelum jadi nabi, jujur sesudah jadi nabi. Gak pernah berubah meskipun punya kekuasaan besar.'),
  DividerBlock(),
  Subheading('💡 Penutup'),
  Paragraph('Muhammad ﷺ bukan tokoh mitos. Dia manusia nyata dengan sejarah yang super detail. Dan karakternya adalah salah satu bukti terkuat: orang se-jujur itu gak mungkin ngarang soal Tuhan.'),
  Paragraph('Di modul terakhir kategori Akidah, kita bakal rangkum semua yang udah kita pelajari jadi satu kerangka yang utuh: apa sih artinya "beriman"?'),
  Cta('Selesai baca! Kuisnya menanti. 🎯'),
];

const _akidah1_5Article = <ArticleBlock>[
  Heading('Apa Itu Iman dan Rukun Iman?'),
  Paragraph('Keren! Kamu udah sampai di modul terakhir kategori Akidah. Di 4 modul sebelumnya, kita udah bahas: Tuhan itu ada, Allah itu Esa, Al-Quran firman Tuhan, dan Muhammad ﷺ utusan-Nya.'),
  Paragraph('Sekarang kita rangkum semuanya jadi satu kerangka utuh: Apa sih artinya "beriman"? Dan apa aja yang wajib dipercaya seorang Muslim?'),
  DividerBlock(),
  Subheading('✨ Apa Itu Iman?'),
  Paragraph('Iman itu bukan cuma ngomong "aku percaya." Iman itu keyakinan di hati yang diucapkan lisan dan dibuktikan lewat perbuatan. Tiga komponen: hati, lisan, dan amal. Kalau cuma ngomong tapi gak yakin di hati? Belum iman. Kalau yakin di hati tapi gak pernah ngelakuin? Belum sempurna.'),
  Paragraph('Dalam Islam, ada 6 hal yang wajib dipercaya. Namanya Rukun Iman. "Rukun" artinya tiang penyangga — kalau salah satu copot, bangunan iman goyah.'),
  DividerBlock(),
  Subheading('1️⃣ Percaya kepada Allah'),
  Paragraph('Ini fondasi dari semuanya. Percaya Allah itu ada, Esa, punya sifat-sifat sempurna, dan Dia satu-satunya yang layak disembah. Tanpa ini, yang lain gak ada artinya. Udah kita bahas panjang lebar di modul 1.1 dan 1.2.'),
  Highlight('Percaya Allah = percaya ada Perancang, dan Dia layak jadi pusat hidupmu.'),
  Subheading('2️⃣ Percaya kepada Malaikat'),
  Paragraph('Malaikat itu makhluk dari cahaya yang diciptakan Allah. Mereka gak punya nafsu, gak pernah durhaka, dan selalu patuh. Kenapa penting percaya? Karena mereka punya tugas penting: nyampein wahyu, mencatat amal, mendoain orang baik, dan banyak lagi. Mereka bukti kalau alam ini lebih luas dari yang keliatan mata.'),
  Subheading('3️⃣ Percaya kepada Kitab-kitab'),
  Paragraph('Allah pernah ngasih petunjuk ke manusia lewat beberapa kitab: Taurat (ke Nabi Musa), Zabur (ke Nabi Daud), Injil (ke Nabi Isa), dan Al-Quran (ke Nabi Muhammad ﷺ). Percaya kitab-kitab = percaya Allah itu konsisten ngasih petunjuk dari dulu. Tapi yang terakhir dan terjaga keasliannya adalah Al-Quran.'),
  Subheading('4️⃣ Percaya kepada Rasul-rasul'),
  Paragraph('Allah gak ninggalin manusia sendirian. Dia ngasih contoh nyata lewat para rasul — manusia biasa yang dipilih buat nyampein pesan-Nya. Dari Nabi Adam sampai Nabi Muhammad ﷺ, semuanya manusia, bukan Tuhan. Percaya rasul = percaya Allah peduli dan ngasih panutan yang bisa diteladani.'),
  Subheading('5️⃣ Percaya kepada Hari Akhir'),
  Paragraph('Hidup di dunia ini gak selamanya. Akan ada hari di mana semuanya berakhir, dan semua perbuatan akan dihitung. Percaya Hari Akhir = percaya bahwa apa yang kamu lakuin sekarang ada konsekuensinya. Ini bikin hidup lebih bermakna: gak sekadar hidup buat senang-senang, tapi ada tujuan jangka panjang.'),
  Subheading('6️⃣ Percaya kepada Qada dan Qadar'),
  Paragraph('Qada dan Qadar itu takdir dari Allah — semua yang terjadi udah dalam pengetahuan dan kehendak-Nya. Tapi ini BUKAN berarti kamu pasif. Justru karena Allah udah tahu segalanya, kamu tetep HARUS berusaha. Hasilnya? Itu urusan Allah. Yang penting kamu udah ngelakuin bagianmu.'),
  Highlight('Qadar itu kayak GPS: rute udah ditentukan, tapi kamu tetep harus nyetir mobilnya.'),
  DividerBlock(),
  Subheading('💡 Rangkuman Kategori Akidah'),
  Paragraph('Lima modul ini adalah fondasi kepercayaan seorang Muslim: Tuhan ada → Allah Esa → Al-Quran firman-Nya → Muhammad ﷺ utusan-Nya → dan ada 6 pilar iman yang jadi penyangga.'),
  Paragraph('Kalau kamu udah paham ini, kamu udah punya dasar yang kuat. Sekarang waktunya naik level: dari "percaya" ke "ngelakuin."'),
  Cta('Kategori Akidah selesai! 🎉 Sekarang lanjut ke tab "Rukun Islam" buat belajar 5 pilar yang jadi aksi nyata seorang Muslim. Kamu udah di jalur yang bener! 🚀'),
];

const _akidah1_6Article = <ArticleBlock>[
  Heading('Keajaiban Angka dalam Al-Quran (Bagian 1)'),
  Paragraph('Al-Quran bukan sekadar kitab petunjuk. Di dalamnya, ada pola-pola angka yang menarik banget — sesuatu yang sulit dijelaskan sebagai kebetulan biasa. Mari kita lihat beberapa di antaranya.'),
  Paragraph('Peringatan: Bagian ini bukan untuk "membuktikan" Al-Quran pakai angka — karena iman seseorang gak bisa diukur dari hitung-hitungan. Tapi bagian ini menarik untuk direnungkan: gimana mungkin seorang ummi di abad ke-7 menghasilkan pola angka serapi ini?'),
  DividerBlock(),
  Subheading('🔢 Keseimbangan Kata dalam Al-Quran'),
  Paragraph('Salah satu temuan paling terkenal dari penelitian berbasis komputer terhadap Al-Quran adalah fakta bahwa kata-kata yang berpasangan muncul dalam jumlah yang SAMA. Bukan perkiraan — persis sama.'),
  Paragraph('Beberapa contoh:'),
  Paragraph('• Kata "ad-dunya" (dunia) disebut 115 kali. Kata "al-akhirah" (akhirat) juga 115 kali.'),
  Paragraph('• Kata "al-malaikat" (malaikat) disebut 88 kali. Kata "asy-syayathin" (setan) juga 88 kali.'),
  Paragraph('• Kata "al-hayah" (kehidupan) disebut 145 kali. Kata "al-maut" (kematian) juga 145 kali.'),
  Paragraph('• Kata "al-jannah" (surga) disebut 77 kali. Kata "an-nar" (neraka) juga 77 kali.'),
  Paragraph('• Kata "al-khair" (kebaikan) disebut 46 kali. Kata "asy-syarr" (keburukan) juga 46 kali.'),
  Paragraph('• Kata "al-har" (panas) disebut 4 kali. Kata "al-bard" (dingin) juga 4 kali.'),
  Paragraph('• Kata "iman" (kepercayaan) disebut 25 kali. Kata "kufr" (kekafiran) disebut 25 kali.'),
  Paragraph('• Kata "shadaqah" (sedekah) disebut 73 kali. Kata "ridha" (kerelaan) disebut 73 kali.'),
  Paragraph('Ini hanya beberapa contoh. Ada PULUHAN pasangan kata lain yang jumlahnya sama persis. Coba bayangin: seseorang nulis buku setebal 30 juz dalam 23 tahun tanpa komputer, di berbagai situasi, dan pasangan kata-kata ini muncul dengan jumlah identik. Apakah itu kebetulan?'),
  Highlight('Keseimbangan kata yang konsisten ini sulit dijelaskan hanya sebagai kebetulan — apalagi dari orang yang gak bisa baca-tulis.'),
  DividerBlock(),
  Subheading('📊 Kata "Yawm" (Hari)'),
  Paragraph('Kata "yawm" (hari) dalam bentuk tunggal disebut 365 kali dalam Al-Quran — tepat sama dengan jumlah hari dalam setahun.'),
  Paragraph('Sementara kata "yawm" dalam bentuk jamak ("ayyam" = hari-hari) disebut 30 kali — sama dengan jumlah hari dalam sebulan.'),
  Paragraph('Menariknya, kata "syahr" (bulan) disebut 12 kali — jumlah bulan dalam setahun.'),
  Paragraph('Kebetulan? Atau memang sengaja dirancang?'),
  DividerBlock(),
  Subheading('📱 Zaman Modern, Tapi Sudah Disebutkan'),
  Paragraph('Kata "al-bahr" (laut) disebut 32 kali dalam Al-Quran. Kata "al-barr" (daratan) disebut 13 kali.'),
  Paragraph('Kalau kita hitung persentasenya: total 32 + 13 = 45. Laut = 32/45 = 71,1%. Darat = 13/45 = 28,9%.'),
  Paragraph('Ternyata, persentase air di permukaan bumi adalah ±71%, dan daratan ±29%. Cocok banget.'),
  Paragraph('Ini baru diketahui manusia setelah teknologi satelit modern. Tapi Al-Quran udah "nyebut" proporsinya sejak 14 abad lalu.'),
  Highlight('Laut 71%, darat 29% — sama persis dengan proporsi di Al-Quran. Tapi ini baru diketahui setelah satelit modern.'),
  DividerBlock(),
  Subheading('🧠 Tapi Ingat...'),
  Paragraph('Ada dua cara orang merespons temuan ini:'),
  Paragraph('1. "Ini bukti Al-Quran dari Allah!" → Mungkin, karena mustahil manusia abad ke-7 bisa bikin pola serumit ini.'),
  Paragraph('2. "Ini cari-cari pola aja, bisa aja kebetulan." → Juga mungkin — karena manusia emang suka nemuin pola (pattern-seeking).'),
  Paragraph('Yang menarik: kedua respons itu sama-sama valid. Tapi coba pikir: jumlah pola dalam Al-Quran itu SANGAT BANYAK dan KONSISTEN. Makin banyak polanya, makin kecil kemungkinan itu cuma kebetulan.'),
  Paragraph('Di bagian 2, kita bakal lihat lebih dalam — termasuk keajaiban angka 19, hubungan antar surah, dan hal-hal lain yang bikin kamu mikir ulang.'),
  Cta('Selesai baca bagian 1! Lanjut ke bagian 2, atau jawab kuis dulu. 🎯'),
];

const _akidah1_7Article = <ArticleBlock>[
  Heading('Keajaiban Angka dalam Al-Quran (Bagian 2)'),
  Paragraph('Di bagian 1 kita udah lihat pasangan kata yang seimbang dan proporsi yang akurat. Sekarang kita masuk ke yang lebih dalam — pola angka 19, struktur surah, dan hubungan antar ayat.'),
  Paragraph('Disclaimer: Ini bukan "membuktikan" bahwa Al-Quran itu benar. Tapi pola-pola ini layak direnungkan — karena semakin dalam kamu lihat, semakin terasa ada "tangan" di baliknya.'),
  DividerBlock(),
  Subheading('19 — Angka yang Istimewa'),
  Paragraph('Angka 19 punya tempat khusus dalam Al-Quran. Allah berfirman dalam QS. Al-Muddassir: 30 — "Di atasnya ada 19 (malaikat penjaga)." Ayat ini kemudian dijelaskan sebagai ujian bagi orang-orang kafir dan penguat iman bagi orang beriman.'),
  Paragraph('Beberapa fakta menarik soal angka 19 dalam Al-Quran:'),
  Paragraph('• Basmalah (Bismillahirrahmanirrahim) punya 19 huruf dalam bahasa Arab aslinya.'),
  Paragraph('• Al-Quran terdiri dari 114 surah. 114 = 19 × 6.'),
  Paragraph('• Jumlah total ayat dalam Al-Quran (termasuk Basmalah di setiap awal surah) adalah 6.346 ayat. 6.346 = 19 × 334.'),
  Paragraph('• Wahyu pertama (QS. Al-Alaq: 1-5) terdiri dari 19 kata.'),
  Paragraph('• Surah Al-Alaq sendiri punya 19 ayat.'),
  Paragraph('• Surah pertama yang diturunkan setelah Al-Alaq adalah QS. Al-Qalam. Surat ini punya 38 ayat. 38 = 19 × 2.'),
  Highlight('19 bukan angka biasa. Basmalah 19 huruf, surah Al-Quran 114 (19×6), total ayat 6.346 (19×334). Polanya konsisten.'),
  DividerBlock(),
  Subheading('🔗 Hubungan Awal dan Akhir Surah'),
  Paragraph('Salah satu temuan menarik: surah pertama (Al-Fatihah, 7 ayat) dan surah terakhir (An-Nas, 6 ayat) — kalau dijumlah ayatnya = 13. 13 adalah jumlah total surah yang disebut dalam Al-Quran (seperti Al-Baqarah, Ibrahim, Maryam, dll).'),
  Paragraph('Contoh lain:'),
  Paragraph('• Surah Al-Ikhlas (112) — inti tauhid. Nomor surahnya 112. 1 + 1 + 2 = 4. Jumlah ayatnya 4. 4 = 4.'),
  Paragraph('• Surah An-Nas (114) — surah terakhir. Nomor 114. 1 + 1 + 4 = 6. Jumlah ayatnya 6. 6 = 6.'),
  Paragraph('• Surah Al-Fatihah (1) — surah pertama. Nomor 1. Jumlah ayatnya 7. 7 bukan 1 — karena Al-Fatihah bukan sembarang surah, dia adalah induk Al-Quran (Ummul Kitab).'),
  Paragraph('Apakah ini disengaja? Atau kebetulan? Setiap orang boleh menyimpulkan sendiri.'),
  DividerBlock(),
  Subheading('📐 Pola Matematika Sederhana Lainnya'),
  Paragraph('Para peneliti Al-Quran juga menemukan pola-pola seperti:'),
  Paragraph('• Kata "shalawat" (sholat) disebut 5 kali = jumlah sholat wajib sehari semalam.'),
  Paragraph('• Kata "zakat" disebut 32 kali, dan kata "zakat" dalam bentuk kata kerja disebut 27 kali — total 59. Ini sama dengan jumlah ayat tentang zakat di Al-Quran.'),
  Paragraph('• Kata "Ramadan" disebut 1 kali — pas puasa Ramadan hanya 1 bulan dalam setahun.'),
  Paragraph('• Kata "sahr" (bulan) disebut 12 kali — jumlah bulan dalam setahun.'),
  Paragraph('• Kata "yaum" (hari) dalam bentuk tunggal 365 kali — setara hari dalam setahun. Ini udah kita bahas di bagian 1.'),
  DividerBlock(),
  Subheading('🧩 Kombinasi Angka yang Menarik'),
  Paragraph('Coba perhatikan kombinasi angka ini:'),
  Paragraph('• Jumlah surah Al-Quran: 114. Jumlah ayat: 6.236 (tanpa Basmalah). Kalau kita tulis 1146236, angka ini habis dibagi 19.'),
  Paragraph('• Atau 114 + 6236 = 6350. 6350 juga habis dibagi 19 (19 × 334,21... tunggu, 19 × 334 = 6346. Kalau pakai Basmalah termasuk, total ayat = 6346, dan 6346 = 19 × 334).'),
  Paragraph('Pola-pola seperti ini terus muncul — sampai ribuan kombinasi udah ditemukan oleh para peneliti Al-Quran dari berbagai negara.'),
  Highlight('Ribuan kombinasi matematis ditemukan dalam Al-Quran. Semakin banyak polanya, semakin kecil kemungkinan itu kebetulan.'),
  DividerBlock(),
  Subheading('💭 Refleksi'),
  Paragraph('Ada dua kemungkinan:'),
  Paragraph('1. Pola-pola ini memang sengaja dirancang — ini mendukung klaim bahwa Al-Quran berasal dari Pencipta yang Maha Tahu.'),
  Paragraph('2. Manusia terlalu pandai mencari pola (apophenia) — kita nemuin pola di mana-mana, termasuk di tempat yang mungkin gak ada polanya.'),
  Paragraph('Tapi ada satu hal yang susah dijelaskan oleh teori "kebetulan": konsistensi polanya. Bukan satu atau dua pola — tapi puluhan, bahkan ratusan. Semakin banyak pola yang konsisten, semakin kecil kemungkinan itu semua cuma kebetulan.'),
  Paragraph('Di modul terakhir kategori Akidah, kita akan lihat bukti-bukti LAIN di luar angka yang memperkuat keyakinan bahwa Al-Quran itu benar-benar firman Allah.'),
  Cta('Selesai juga bagian 2! Lanjut ke bagian akhir, atau jawab kuis dulu. 🎯'),
];

const _akidah1_8Article = <ArticleBlock>[
  Heading('Masih Banyak Bukti Lain: Al-Quran Benar Firman Allah'),
  Paragraph('Selama 7 modul sebelumnya di kategori Akidah, kita udah bahas: Tuhan itu ada, Allah itu Esa, Al-Quran bukan karangan manusia (dari sisi bahasa, sejarah, preservasi, dan angka). Sekarang kita bahas bukti-bukti LAIN yang makin nguatin: bahwa Al-Quran itu benar-benar dari Allah.'),
  DividerBlock(),
  Subheading('🔮 Nubuatan (Ramalan) yang Tepat'),
  Paragraph('Salah satu ciri kitab dari Tuhan adalah: berita tentang masa depan yang terbukti benar. Al-Quran punya beberapa contoh yang menarik:'),
  Paragraph('1. Kekalahan Romawi — QS. Ar-Rum: 1-4'),
  Paragraph('Ayat ini turun di saat Kekaisaran Romawi (Byzantium) kalah telak dari Persia. Secara logika, Romawi udah habis. Tapi Al-Quran bilang: "Romawi akan menang lagi dalam beberapa tahun." Pada saat itu, ini terdengar mustahil. Tapi benar terjadi — Romawi balik menang sekitar 7-9 tahun kemudian.'),
  Paragraph('Sejarawan bilang: Muhammad ﷺ gak mungkin tahu outcome perang ini. Gak ada kabel internet, gak ada koran. Informasi dari medan perang di Suriah-Yordania ke Makkah butuh berminggu-minggu. Tapi Al-Quran berani ngasih prediksi spesifik — dan terbukti.'),
  Highlight('QS. Ar-Rum: Romawi bakal menang lagi setelah dikalahkan. Semua orang ngira ini gila. Tapi itu terjadi.'),
  Paragraph('2. Perlindungan Al-Quran — QS. Al-Hijr: 9'),
  Paragraph('"Sesungguhnya Kami-lah yang menurunkan Al-Quran, dan pasti Kami (pula) yang menjaganya."'),
  Paragraph('Ayat ini turun 14 abad lalu — klaim berani bahwa kitab ini BAKAL TERJAGA. Sementara kitab suci lain udah banyak berubah, Al-Quran sampai sekarang masih asli. Klaim ini terbukti — dan terus dibuktikan setiap hari oleh jutaan penghafal Al-Quran di seluruh dunia.'),
  DividerBlock(),
  Subheading('🌍 Al-Quran dan Sains Modern'),
  Paragraph('Beberapa ayat Al-Quran baru bisa dipahami sepenuhnya setelah sains modern menemukannya. Ini bukan berarti Al-Quran = buku sains — tapi menunjukkan bahwa sumber Al-Quran bukan manusia abad ke-7.'),
  Paragraph('1. Segala sesuatu diciptakan berpasangan'),
  Paragraph('QS. Adz-Dzariyat: 49 — "Dan segala sesuatu Kami ciptakan berpasang-pasangan, supaya kamu mengingat (kebesaran Allah)."'),
  Paragraph('Ayat ini turun 14 abad lalu. Zaman dulu orang pikir pasangan cuma laki-perempuan. Tapi sekarang sains tahu: atom punya proton-elektron, muatan positif-negatif, partikel-antipartikel, gen berpasangan di DNA, bahkan galaksi punya pasangan. "Segala sesuatu" berpasangan — ini baru terbukti di era fisika kuantum.'),
  Paragraph('2. Gunung sebagai pasak'),
  Paragraph('QS. An-Naba': 6-7 — "Bukankah Kami telah menjadikan bumi sebagai hamparan, dan gunung-gunung sebagai pasak?"'),
  Paragraph('Dulu orang kira gunung cuma tonjolan di permukaan bumi. Sekarang geologi modern tahu: gunung punya "akar" yang menjulur jauh ke dalam bumi — kayak pasak yang nge-stabilin lempeng tektonik. Kata "pasak" (autad) dalam bahasa Arab memang berarti pasak yang nancep dalem.'),
  Paragraph('3. Perkembangan janin'),
  Paragraph('QS. Al-Mu'minun: 12-14 — menggambarkan tahapan embrio dari nutfah (setetes), alaqah (segumpal darah), mudghah (segumpal daging), sampai tulang dan daging.'),
  Paragraph('Deskripsi ini baru bisa diverifikasi setelah mikroskop ditemukan. Kata "alaqah" artinya sesuatu yang bergantung — cocok dengan deskripsi embrio yang nempel di dinding rahim.'),
  Paragraph('4. Jejak sidik jari'),
  Paragraph('QS. Al-Qiyamah: 4 — "Bukan demikian, Kami mampu menyusun kembali jari-jemarinya dengan sempurna."'),
  Paragraph('Kenapa Al-Quran nyebut jari spesifik? Karena sidik jari setiap manusia UNIK — bahkan kembar identik pun beda. Fakta ini baru ditemukan sains di abad ke-19. Al-Quran udah nyebut di abad ke-7.'),
  Highlight('Ayat-ayat ini bukan bukti "Al-Quran = buku IPA." Tapi ini menarik: gimana seorang di abad ke-7 bisa tahu hal-hal yang baru terverifikasi 12 abad kemudian?'),
  DividerBlock(),
  Subheading('📜 Konsistensi Internal yang Mencengangkan'),
  Paragraph('Al-Quran diturunkan sedikit demi sedikit selama 23 tahun di dua kota berbeda (Makkah dan Madinah), dalam situasi yang sangat kontras — saat lemah dan saat berkuasa, saat damai dan saat perang, saat miskin dan saat kaya.'),
  Paragraph('Logikanya: kalau ini karangan manusia, PASTI ada kontradiksi. Manusia berubah pikiran seiring waktu. Tapi Al-Quran? Nol kontradiksi. Allah sendiri nantang dalam QS. An-Nisa': 82 — "Kalau Al-Quran ini dari selain Allah, pasti mereka menemukan banyak pertentangan di dalamnya."'),
  Paragraph('Para orientalis dan kritikus Al-Quran selama 14 abad udah berusaha nemuin kontradiksi. Hasilnya? Yang mereka temuin biasanya karena: (1) salah paham konteks, (2) ayat untuk situasi berbeda, atau (3) gak paham bahasa Arab. Setelah dijelaskan, "kontradiksi" itu hilang.'),
  DividerBlock(),
  Subheading('🧠 Dampak pada Manusia'),
  Paragraph('Ini mungkin bukti yang paling subjektif — tapi juga paling nyata: jutaan orang di seluruh dunia, dari berbagai ras dan budaya, membaca Al-Quran dan HATI mereka tersentuh.'),
  Paragraph('• Ada yang tadinya ateis, baca Al-Quran, jadi percaya Tuhan.'),
  Paragraph('• Ada yang tadinya benci Islam, pelajari Al-Quran, jadi Muslim.'),
  Paragraph('• Ada yang tadinya hidup hampa, denger ayat Al-Quran, nemu ketenangan.'),
  Paragraph('Bukan cuma orang awam — profesor, ilmuwan, dokter, pengacara — orang-orang pintar yang terbiasa berpikir kritis, banyak yang masuk Islam setelah mempelajari Al-Quran.'),
  Paragraph('Kalau Al-Quran cuma karangan manusia abad ke-7, kenapa masih relevan hari ini? Kenapa masih bisa mengubah hati orang-orang di era AI dan robot?'),
  Highlight('Al-Quran bukan cuma teks kuno. Ini kitab yang hidup — dan terus mengubah hati manusia sampai sekarang.'),
  DividerBlock(),
  Subheading('💡 Kesimpulan Akhir: Apa yang Membuat Al-Quran Istimewa?'),
  Paragraph('Kalau kita rangkum, ada 7+ bukti yang saling menguatkan:'),
  Paragraph('1. Nabi ﷺ ummi — gak bisa baca-tulis, mustahil ngarang teks serumit ini.'),
  Paragraph('2. Keajaiban bahasa (I'jaz) — para sastrawan Arab gagal menandingi.'),
  Paragraph('3. Diwahyukan 23 tahun — tanpa kontradiksi.'),
  Paragraph('4. Preservasi sempurna — 1.400 tahun, nol perubahan.'),
  Paragraph('5. Informasi yang melampaui zamannya — sains, sejarah, angka.'),
  Paragraph('6. Pola matematis yang konsisten — ribuan kombinasi angka.'),
  Paragraph('7. Nubuatan yang terbukti — Romawi, penjagaan Al-Quran.'),
  Paragraph('8. Dampak pada manusia — masih mengubah hati sampai hari ini.'),
  Paragraph('Masing-masing bukti ini mungkin bisa "dijawab" sendiri-sendiri. Tapi ketika DELAPAN bukti ini digabung — dan semuanya mengarah ke arah yang sama — sulit untuk bilang ini semua cuma kebetulan.'),
  Paragraph('Pada akhirnya, keputusan ada di tangan kamu. Al-Quran udah ngasih semua bukti. Allah udah ngasih akal buat mikir. Sisanya? Kamu yang mutusin.'),
  EducatorNote('"Kitab (Al-Quran) ini tidak ada keraguan padanya; petunjuk bagi mereka yang bertakwa." (QS. Al-Baqarah: 2)'),
  Cta('🎉 SELAMAT! Kamu udah menyelesaikan SEMUA modul kategori Akidah! Jawab kuis terakhir ini, klaim XP bonus, dan lanjut ke Rukun Islam. Luar biasa! 🚀'),
];

const _rukun2_1Article = <ArticleBlock>[
  Heading('5 Rukun Islam: Fondasi Hidup Seorang Muslim'),
  Paragraph('Oke, sekarang kamu udah paham soal dasar kepercayaan (Akidah). Sekarang pertanyaannya: kalau udah percaya, terus ngapain? Jawabannya ada di Rukun Islam.'),
  Paragraph('Rukun Islam itu 5 hal yang jadi FONDASI hidup seorang Muslim. "Rukun" artinya tiang penopang — kalau satu copot, bangunan goyah. Kelimanya saling ngisi, gak bisa pilih-pilih.'),
  DividerBlock(),
  Subheading('1️⃣ Syahadat — "Aku Bersaksi"'),
  Paragraph('Ini gerbang masuk Islam. Dua kalimat syahadat: bersaksi bahwa gak ada Tuhan selain Allah, dan Muhammad ﷺ utusan Allah. Bukan cuma diucapkan — tapi diyakini di hati. Ini komitmen seumur hidup, bukan sekadar kata-kata.'),
  Highlight('Syahadat itu kayak "terms & conditions" — tapi yang beneran kamu baca dan setujuin, bukan langsung klik "accept."'),
  Subheading('2️⃣ Sholat — 5 Waktu Sehari'),
  Paragraph('Sholat itu cara ngobrol langsung sama Allah, 5 kali sehari. Subuh, Dzuhur, Ashar, Maghrib, Isya. Bukan ritual kosong — ada gerakan, bacaan, dan makna di tiap langkah. Ini "appointment" tetap kamu sama Tuhan. Gak bisa di-delegate, gak bisa di-skip.'),
  Subheading('3️⃣ Zakat — Berbagi dari Harta'),
  Paragraph('Kalau udah punya harta yang cukup (nisab), wajib ngasih 2.5% ke yang membutuhkan. Bukan pajak — ini pembersihan harta. Konsepnya: harta yang kamu punya gak 100% milikmu, ada hak orang lain di situ. Zakat bikin harta berkah.'),
  Subheading('4️⃣ Puasa (Ramadan) — Tahan Lapar, Tahan Diri'),
  Paragraph('Setiap Ramadan, umat Islam puasa dari terbit sampai terbenam matahari. Gak cuma tahan makan dan minum — tapi juga tahan emosi, gossip, dan hal-hal negatif. Tujuannya: melatih disiplin, empati sama yang kurang mampu, dan deketin diri sama Allah. Satu bulan penuh, setiap tahun.'),
  Subheading('5️⃣ Haji — Sekali Seumur Hidup'),
  Paragraph('Kalau mampu (secara fisik dan finansial), wajib ke Makkah sekali seumur hidup. Ini ibadah terbesar — jutaan orang dari seluruh dunia berkumpul di satu tempat, pakai baju yang sama, ibadah yang sama. Gak ada bedanya kaya-miskin, bos-karyawan. Semuanya sama di depan Allah.'),
  DividerBlock(),
  Subheading('💡 Kenapa 5, Bukan 3 atau 7?'),
  Paragraph('Lima rukun ini udah ditetapkan langsung oleh Nabi Muhammad ﷺ. Masing-masing ngisi aspek kehidupan yang berbeda: Syahadat = hati, Sholat = waktu, Zakat = harta, Puasa = nafsu, Haji = fisik. Lengkap. Gak kurang, gak lebih.'),
  Paragraph('Di modul-modul berikutnya, kita bakal bahas satu per satu secara detail — mulai dari Syahadat di modul selanjutnya. Stay tuned!'),
  Cta('Kamu udah paham overview-nya! Sekarang jawab kuis buat klaim XP. 🎯'),
];

const _rukun2_2Article = <ArticleBlock>[
  Heading('Syahadat: Gerbang Pertama'),
  Paragraph('"Laa ilaaha illallah, Muhammadur Rasulullah." Kamu pasti pernah dengar kalimat ini. Tapi apa artinya sebenernya? Dan kenapa ini jadi rukun pertama?'),
  Paragraph('Syahadat itu bukan mantra. Bukan jimat. Ini deklarasi — pernyataan resmi dari hati bahwa kamu memilih jalan hidup tertentu. Yuk kita bedah satu per satu.'),
  DividerBlock(),
  Subheading('📜 Kalimat Pertama: Laa Ilaaha Illallah'),
  Paragraph('"Tidak ada Tuhan (yang layak disembah) selain Allah." Ini inti dari Tauhid yang udah kita bahas di modul 1.2. Bukan cuma bilang "Tuhan itu ada" — tapi juga "Dia aja yang layak aku sembah dan taati."'),
  Paragraph('Implikasinya: kamu gak boleh menyembah selain Allah. Gak boleh takut sama selain Allah lebih dari takut sama-Nya. Gak boleh bergantung sama selain Allah lebih dari bergantung sama-Nya. Ini soal prioritas hidup.'),
  Highlight('Laa ilaaha illallah = "Yang nomor satu dalam hidupku adalah Allah. Bukan duit, bukan jabatan, bukan orang lain."'),
  Subheading('📜 Kalimat Kedua: Muhammadur Rasulullah'),
  Paragraph('"Muhammad ﷺ adalah utusan Allah." Ini artinya kamu percaya Muhammad ﷺ beneran diutus oleh Allah buat jadi contoh hidup. Dan kalau percaya, konsekuensinya: ikutin ajarannya.'),
  Paragraph('Bayangin: kamu punya mentor yang udah terbukti jujur, cerdas, dan peduli. Kamu percaya dia. Maka kamu ikutin saran dia. Logis kan? Sama halnya dengan Muhammad ﷺ — kalau beneran percaya dia utusan Tuhan, maka ikutin ajarannya.'),
  DividerBlock(),
  Subheading('⚡ Konsekuensi Logis'),
  Paragraph('Syahadat itu bukan cuma ucapan — tapi komitmen. Begitu kamu ngucapin dan yakinin, ada konsekuensi logis:'),
  Paragraph('• Kamu berkomitmen menyembah Allah aja — sholat, berdoa, bersyukur, semuanya ke Allah.'),
  Paragraph('• Kamu berkomitmen ngikutin ajaran Nabi ﷺ — cara hidup yang udah dia contohin.'),
  Paragraph('• Kamu berkomitmen ninggalin yang dilarang — bukan karena takut hukuman, tapi karena kamu percaya Allah lebih tahu apa yang terbaik buat kamu.'),
  Paragraph('Ini kayak kontrak seumur hidup — tapi kontrak yang bikin hidupmu lebih terarah dan bermakna.'),
  Highlight('Syahadat itu bukan "slesai" begitu diucapkan. Itu titik awal. Perjalanan baru aja dimulai.'),
  DividerBlock(),
  Subheading('💡 Kenapa Ini Rukun Pertama?'),
  Paragraph('Karena tanpa syahadat, 4 rukun yang lain gak punya dasar. Sholat tanpa percaya Allah? Cuma gerakan kosong. Zakat tanpa komitmen? Cuma buang duit. Puasa tanpa tauhid? Cuma diet. Haji tanpa iman? Cuma jalan-jalan.'),
  Paragraph('Syahadat itu fondasinya. Yang bikin semua ibadah punya makna. Dan yang bikin kamu jadi Muslim.'),
  Cta('Selesai baca! Kuis waktunya tiba. 🎯'),
];

const _rukun2_3Article = <ArticleBlock>[
  Heading('Kenapa Harus Puasa Ramadan?'),
  Paragraph('Setiap tahun, umat Islam di seluruh dunia berhenti makan dan minum dari subuh sampai maghrib selama satu bulan penuh. Kedengerannya berat? Emang. Tapi ada alasan kuat di baliknya.'),
  DividerBlock(),
  Subheading('🧘 Manfaat Spiritual: Latihan Self-Control'),
  Paragraph('Inti puasa itu bukan "tahan lapar." Intinya: latihan ngendaliin diri. Kamu pengen makan? Tahan. Kamu pengen marah? Tahan. Kamu pengen gossip? Tahan.'),
  Paragraph('Bayangin: kalau kamu bisa ngendaliin keinginan yang PALING dasar (makan dan minum), maka kamu juga bisa ngendaliin keinginan yang lebih kompleks — emosi, nafsu, ambisi. Puasa itu gym-nya jiwa.'),
  Highlight('Puasa itu bukan soal "gak makan." Tapi soal: "siapa yang pegang kendali — nafsu atau kamu?"'),
  Subheading('🤝 Empati sama yang Kurang Mampu'),
  Paragraph('Kamu pernah ngerasain lapar beneran? Bukan "luput sarapan" — tapi beneran gak makan seharian. Puasa bikin kamu ngerasain apa yang dirasain orang yang gak mampu makan setiap hari. Dari situ muncul empati — dan dorongan buat berbagi.'),
  Subheading('🏥 Manfaat Kesehatan (Secara Umum)'),
  Paragraph('Banyak penelitian menunjukkan bahwa puasa intermiten (yang polanya mirip puasa Ramadan) punya dampak positif secara umum pada tubuh. Tapi ini bukan klaim medis — setiap orang beda kondisinya. Yang jelas: puasa Ramadan dirancang oleh Allah, dan Allah lebih tahu apa yang terbaik buat hamba-Nya.'),
  DividerBlock(),
  Subheading('📋 Siapa yang Wajib Puasa?'),
  Paragraph('Semua Muslim yang udah baligh dan sehat wajib puasa. Tapi ada keringanan untuk yang gak mampu:'),
  Paragraph('• Sakit — boleh gak puasa, tapi wajib qadha (ganti) kalau udah sembuh.'),
  Paragraph('• Musafir (perjalanan jauh) — boleh gak puasa, wajib qadha juga.'),
  Paragraph('• Hamil/menyusui — boleh gak puasa kalau khawatir kebayi, qadha atau fidyah.'),
  Paragraph('• Lansia/gak mampu permanen — gak wajib puasa, cukup bayar fidyah (makan orang miskin per hari).'),
  Highlight('Islam itu fleksibel. Ada aturan, tapi ada keringanan. Gak ada yang dipaksain di luar batas kemampuan.'),
  DividerBlock(),
  Subheading('💡 Kesimpulan'),
  Paragraph('Puasa Ramadan itu bukan hukuman — tapi pelatihan. Melatih disiplin, empati, dan ketergantungan pada Allah. Satu bulan penuh yang bikin 11 bulan sisanya lebih bermakna.'),
  Cta('Selesai baca! Saatnya kuis. 🎯'),
];

const _rukun2_4Article = <ArticleBlock>[
  Heading('Zakat: Kenapa Harus Berbagi?'),
  Paragraph('Kamu udah dengar soal zakat di modul overview Rukun Islam. Sekarang kita bedah lebih dalam: kenapa sih harus berbagi dari harta yang udah susah payah kamu cari?'),
  DividerBlock(),
  Subheading('🧹 Zakat = Pembersih Harta'),
  Paragraph('Kata "zakat" sendiri artinya "bersih" dan "tumbuh." Konsepnya: harta yang kamu punya itu gak 100% milikmu. Ada hak orang lain di situ — yang butuh, yang kurang mampu. Dengan ngasih zakat, kamu "bersihin" hartamu dari hak mereka.'),
  Paragraph('Bayangin: kamu punya gelas air yang terus dituang. Kalau gak pernah dibagiin, gelasnya meluap dan tumpah. Zakat itu bikin aliran tetap lancar — kamu terima, kamu bagikan, dan hartamu jadi lebih berkah.'),
  Highlight('Zakat bukan "buang duit." Zakat investasi di akhirat dan pembersihan harta di dunia.'),
  Subheading('📊 Beda Zakat, Infaq, dan Sedekah'),
  Paragraph('Ketiganya sama-sama berbagi, tapi beda aturannya:'),
  Paragraph('• Zakat — WAJIB. Ada nisab (batas minimal harta) dan haul (dimiliki setahun). Besarnya 2.5% dari harta. Ada 8 golongan yang berhak menerima (asnaf).'),
  Paragraph('• Infaq — SUNNAH. Berbagi dari harta tanpa batasan persentase. Bisa kapan saja, berapa saja, ke siapa saja.'),
  Paragraph('• Sedekah — SUNNAH. Lebih luas dari infaq — bukan cuma uang. Senyum aja udah sedekah. Nolong orang, ngasih ilmu, bahkan buang duri dari jalan itu sedekah.'),
  Subheading('🌍 Dampak Sosial: Kurangi Kesenjangan'),
  Paragraph('Zakat itu sistem distribusi kekayaan yang unik. Yang punya lebih → ngasih 2.5% → yang butuh terbantu. Kalau semua orang yang mampu bayar zakat, kesenjangan sosial bisa berkurang signifikan.'),
  Paragraph('Ini bukan sosialisme ala Barat — ini sistem dari Allah. Dan bedanya: zakat itu MOTIVASINYA cinta, bukan paksaan. Kamu ngasih karena percaya itu hak mereka, dan karena kamu sayang sama hartamu sendiri (maunya yang bersih dan berkah).'),
  Highlight('Zakat: satu sistem yang bersihin hartamu SEKALIGUS bantu sesama. Win-win.'),
  DividerBlock(),
  Subheading('💡 Penutup'),
  Paragraph('Zakat itu bukan beban — itu hak orang lain yang dititipin di hartamu. Dan ketika kamu ngasih, yang kamu "bersihin" bukan cuma hartamu — tapi juga hatimu.'),
  Cta('Kamu udah paham soal zakat! Kuis waktunya. 🎯'),
];

const _rukun2_5Article = <ArticleBlock>[
  Heading('Haji: Perjalanan Sekali Seumur Hidup'),
  Paragraph('Ini rukun terakhir. Dan mungkin yang paling "wow" — karena kamu harus beneran pergi ke satu tempat di belahan dunia lain, bersama jutaan orang dari seluruh planet.'),
  DividerBlock(),
  Subheading('🕋 Apa Itu Haji?'),
  Paragraph('Haji itu ibadah ziarah ke Makkah, Arab Saudi. Wajib sekali seumur hidup buat Muslim yang MAMPU (secara fisik dan finansial). Kalau belum mampu? Gak wajib. Simple.'),
  Paragraph('Haji dilakukan setiap tanggal 8-12 Dzulhijjah (bulan ke-12 kalender Islam). Ada rangkaian ibadah: tawaf (keliling Ka\'bah), sa\'i (jalan bolak-balik), wukuf di Arafah (puncak haji), melempar jumrah, dan lain-lain.'),
  Subheading('👕 Ihram: Semua Sama Rata'),
  Paragraph('Yang bikin haji beda dari ibadah lain: semua orang pakai baju yang SAMA. Putih, tanpa jahitan, gak ada merek, gak ada logo. Namanya ihram.'),
  Paragraph('Bayangin: Presiden, buruh, dokter, tukang ojek, pengusaha — semuanya pakai baju yang sama. Gak ada yang bisa pamer kekayaan. Gak ada yang bisa pamer jabatan. Di depan Allah, SEMUA SAMA.'),
  Highlight('Ihram itu pengingat: di mata Allah, yang membedakan kamu bukan harta atau jabatan — tapi ketakwaanmu.'),
  Subheading('⚖️ Makna Simbolis Haji'),
  Paragraph('Haji itu bukan sekadar perjalanan fisik. Tiap ritual punya makna:'),
  Paragraph('• Tawaf (keliling Ka\'bah 7x) — hidupmu harus berpusat pada Allah, seperti bumi yang mengelilingi matahari.'),
  Paragraph('• Wukuf di Arafah — pengingat Hari Kiamat, saat semua manusia berkumpul di padang mahsyar.'),
  Paragraph('• Melempar jumrah — simbol nolak godaan setan, dari yang kecil sampai yang besar.'),
  Paragraph('• Sa\'i (lari bolak-balik Safa-Marwa) — mengenang perjuangan Siti Hajar mencari air untuk bayinya, Ismail. Simbol ketekunan dan tawakkal.'),
  Subheading('💰 Syarat Wajib Haji'),
  Paragraph('Haji cuma wajib kalau kamu MAMPU. Artinya:'),
  Paragraph('• Fisik sehat — kuat jalan, berdiri, tahan cuaca panas. Kalau sakit parah, gak wajib.'),
  Paragraph('• Finansial cukup — punya biaya pergi DAN keluarga di rumah tetap tercukupi. Gak boleh haji tapi utang menumpuk.'),
  Paragraph('• Aman perjalanannya — jalur ke Makkah aman.'),
  Highlight('Haji itu wajib kalau mampu. Kalau belum mampu, gak dosa. Allah gak membebankan di luar batas kemampuan.'),
  DividerBlock(),
  Subheading('💡 Penutup Kategori Rukun Islam'),
  Paragraph('Kelima rukun ini — Syahadat, Sholat, Puasa, Zakat, Haji — adalah FONDASI hidup seorang Muslim. Masing-masing ngisi aspek berbeda: hati, waktu, nafsu, harta, dan fisik.'),
  Paragraph('Kalau kamu udah paham Akidah dan Rukun Islam, kamu udah punya kerangka yang kuat. Sekarang waktunya masuk ke bagian praktisnya.'),
  Cta('Kategori Rukun Islam selesai! 🎉 Lanjut ke tab "Praktik Ibadah" buat belajar cara sholat dari nol. Kamu makin keren! 🚀'),
];

const _praktik3_1Article = <ArticleBlock>[
  Heading('Wudhu: Bersih-Bersih Sebelum Menghadap Allah'),
  Paragraph('Sebelum sholat, kamu harus bersih dulu — bukan cuma fisik, tapi juga "spiritual" (disebut suci dari hadas kecil). Caranya? Wudhu. Ini step-by-step-nya.'),
  DividerBlock(),
  Subheading('🛐 Niat di Hati'),
  Paragraph('Niat itu di dalam hati, gak perlu diucapkan keras-keras. Cukup dalam hati: "Aku niat berwudhu untuk menghilangkan hadas kecil karena Allah." Tapi kalau mau baca, boleh:'),
  EducatorNote('نَوَيْتُ الْوُضُوءَ لِرَفْعِ الْحَدَثِ اْلاَصْغَرِ فَرْضًا لِلَّهِ تَعَالَى\nNawaitul wudhu-a lirof\'il hadatsil ashghori fardhon lillahi ta\'ala.\nAku niat berwudhu untuk menghilangkan hadas kecil, fardhu karena Allah Ta\'ala.'),
  Subheading('🪜 Langkah-Langkah Wudhu (Urut!)'),
  Paragraph('Urutan ini harus berurutan sesuai sunnah. Kalau loncat-loncat, wudhunya kurang sempurna:'),
  Paragraph('① BASUH KEDUA TELAPAK TANGAN — sampai pergelangan, 3 kali. Bersihin kotoran yang nempel.'),
  Paragraph('② KUMUR-KUMUR (MADHMADHAH) — ambil air, masukin ke mulut, kumur 3 kali. Bersihin mulut dari sisa makanan.'),
  Paragraph('③ MASUKKAN AIR KE HIDUNG (ISTINSYAQ) — hirup air ke hidung, keluarkan, 3 kali. Gak enak emang, tapi bagian dari wudhu.'),
  Paragraph('④ BASUH WAJAH — dari batas tumbuhnya rambut sampai dagu, dari telinga ke telinga, 3 kali.'),
  Paragraph('⑤ BASUH TANGAN SAMPAI SIKU — mulai dari ujung jari sampai siku (termasuk siku), 3 kali. Tangan kanan dulu, baru kiri.'),
  Paragraph('⑥ USAP KEPALA — pakai tangan basah, usap dari depan ke belakang, balik lagi ke depan. 1 kali aja.'),
  Paragraph('⑦ USAP TELINGA — jari telunjuk masukin ke lubang telinga, ibu jari usap belakang telinga. 1 kali.'),
  Paragraph('⑧ BASUH KAKI SAMPAI MATA KAKI — dari ujung jari sampai mata kaki (termasuk mata kaki), 3 kali. Kanan dulu, baru kiri.'),
  Highlight('Tips: sambil nginget urutannya, bayangin kamu lagi "nyiram" dari atas ke bawah. Tangan → muka → tangan → kepala → kaki.'),
  DividerBlock(),
  Subheading('❌ Hal yang Membatal Wudhu'),
  Paragraph('Wudhu bisa batal kalau:'),
  Paragraph('• Keluar sesuatu dari qubul/dubur (kencing, buang air, kentut)'),
  Paragraph('• Tidur nyenyak (bukan sekadar ngantuk)'),
  Paragraph('• Hilang akal (pingsan, mabuk)'),
  Paragraph('• Menyentuh kemaluan tanpa alas (ada pendapat yang beda, tapi ini yang lebih hati-hati)'),
  Subheading('💡 Tips Pemula'),
  Paragraph('• Wudhu bisa tahan lama selama gak batal. Jadi kalau udah wudhu dan belum batal, sholatnya boleh pakai wudhu yang sama.'),
  Paragraph('• Latihan di rumah dulu. Gak harus perfect di hari pertama. Yang penting niat dan usaha.'),
  Paragraph('• Kalau gak ada air (perjalanan, sakit), boleh tayamum (pakai debu). Tapi itu materi lanjutan.'),
  Cta('Wudhu selesai! Sekarang kamu siap sholat. Jawab kuisnya dulu ya. 🎯'),
];

const _praktik3_2Article = <ArticleBlock>[
  Heading('Syarat Sah & Rukun Sholat'),
  Paragraph('Sebelum masuk ke tata cara sholat, kamu perlu tahu dua hal yang sering bikin bingung pemula: syarat sah dan rukun. Kedengarannya mirip, tapi beda.'),
  DividerBlock(),
  Subheading('📋 Syarat Sah Sholat'),
  Paragraph('Syarat sah itu hal-hal yang harus DIPENUHI SEBELUM sholat. Kalau gak terpenuhi, sholatnya gak sah — mau gerakannya sempurna sekalipun. Ada 5:'),
  Paragraph('① Suci dari hadas besar — kalau junub (habis hubungan suami-istri, mimpi basah, haid), harus mandi besar (mandi junub) dulu. Wudhu aja gak cukup.'),
  Paragraph('② Suci dari hadas kecil — ini yang diurus sama wudhu (yang udah kita bahas di modul sebelumnya).'),
  Paragraph('③ Menutup aurat — laki-laki: pusar sampai lutut. Perempuan: seluruh tubuh kecuali muka dan telapak tangan. Pakai baju yang gak transparan dan gak ketat.'),
  Paragraph('④ Menghadap kiblat — arah Ka\'bah di Makkah. Dari Indonesia, arahnya barat agak serong ke utara (barat laut). Kalau gak tahu arahnya, pakai fitur Kiblat di tab Jadwal app ini.'),
  Paragraph('⑤ Masuk waktu sholat — setiap sholat punya waktu spesifik. Sholat Subuh sebelum terbit matahari, Dzuhur setelah matahari condong ke barat, dan seterusnya. Sholat di luar waktu = gak sah.'),
  Highlight('Syarat sah = hal-hal DI LUAR sholat yang harus dipenuhi dulu. Lupa satu? Sholatnya batal dari awal.'),
  DividerBlock(),
  Subheading('🧱 Rukun Sholat'),
  Paragraph('Rukun itu hal-hal yang harus dilakukan DI DALAM sholat. Kalau ada yang ketinggalan, sholatnya gak sah. Ada 13 rukun (sebagian ulama bilang 14):'),
  Paragraph('① Niat di dalam hati — saat mau takbiratul ihram.'),
  Paragraph('② Takbiratul ihram — ucap "Allahu Akbar" sambil angkat tangan. Ini tanda sholat dimulai.'),
  Paragraph('③ Berdiri tegak (bagi yang mampu) — saat takbiratul ihram dan saat baca Al-Fatihah.'),
  Paragraph('④ Membaca Al-Fatihah — wajib di setiap rakaat, baik imam maupun sendirian.'),
  Paragraph('⑤ Ruku — tunduk, tangan pegang lutut, punggung lurus.'),
  Paragraph('⑥ I\'tidal — bangun dari ruku, berdiri tegak.'),
  Paragraph('⑦ Sujud (2 kali per rakaat) — dahi, hidung, kedua telapak tangan, kedua lutut, dan ujung jari kaki menyentuh lantai.'),
  Paragraph('⑧ Duduk antara dua sujud — duduk sebentar setelah sujud pertama, sebelum sujud kedua.'),
  Paragraph('⑨ Tasyahud akhir — duduk di rakaat terakhir, baca tasyahud.'),
  Paragraph('⑩ Membaca sholawat — untuk Nabi Muhammad ﷺ di tasyahud akhir.'),
  Paragraph('⑪ Duduk untuk tasyahud akhir dan tasyahud awal — posisi duduk iftirasy (kaki kiri diduduki, kanan tegak).'),
  Paragraph('⑫ Membaca dua kalimat syahadat — di tasyahud akhir.'),
  Paragraph('⑬ Salam — ucap "Assalamu\'alaikum warahmatullah" ke kanan dan ke kiri. Ini tanda sholat selesai.'),
  Paragraph('⑭ Tertib — mengerjakan semua rukun secara berurutan.'),
  Highlight('Syarat sah = SEBELUM sholat. Rukun = DI DALAM sholat. Bedanya: syarat sah bikin sholat BOLEH dimulai. Rukun bikin sholat JADI sah.'),
  DividerBlock(),
  Subheading('💡 Kenapa Perlu Tahu Ini?'),
  Paragraph('Karena banyak pemula yang bingung: "Sholatku sah gak ya?" Kalau syarat sah terpenuhi dan rukunnya lengkap, sholatmu sah. Simple. Gak perlu overthinking.'),
  Cta('Udah paham syarat dan rukunnya? Sekarang jawab kuis, lalu lanjut ke tata cara sholat step-by-step! 🎯'),
];

const _praktik3_3Article = <ArticleBlock>[
  Heading('Tata Cara Sholat Step-by-Step'),
  Paragraph('Ini dia yang kamu tunggu-tunggu. Kita bakal bahas sholat 2 rakaat — yang paling dasar. Setelah paham 2 rakaat, tinggal tambah rakaat aja untuk sholat 3 (Maghrib) atau 4 (Dzuhur, Ashar, Isya).'),
  Paragraph('Tiap gerakan ada deskripsi posisinya. Kalau bingung, tanya teman atau lihat video tutorial. Praktik langsung itu guru terbaik.'),
  DividerBlock(),
  Subheading('🕋 RAKAAT 1'),
  Paragraph(''),
  Subheading('① Berdiri Tegak, Hadap Kiblat'),
  Paragraph('Posisi: berdiri tegak, kedua kaki sejajar, pandangan ke tempat sujud. Hadap kiblat.'),
  Subheading('② Takbiratul Ihram'),
  Paragraph('Angkat kedua tangan sejajar telinga, lalu ucapkan:'),
  EducatorNote('اللَّهُ أَكْبَرُ\nAllahu Akbar.\nAllah Maha Besar.'),
  Paragraph('Setelah takbir, turunkan tangan. Tangan kanan pegang pergelangan tangan kiri di depan dada.'),
  Subheading('③ Baca Doa Iftitah'),
  Paragraph('Setelah takbiratul ihram, baca doa iftitah:'),
  EducatorNote('اللَّهُ أَكْبَرُ كَبِيرًا وَالْحَمْدُ لِلَّهِ كَثِيرًا وَسُبْحَانَ اللَّهِ بُكْرَةً وَأَصِيلًا\nAllahu akbaru kabiro wal hamdulillahi katsiro wa subhanallahi bukratan wa asila.\nAllah Maha Besar dengan segala kebesaran, segala puji bagi Allah dengan pujian yang banyak, Maha Suci Allah pada pagi dan petang hari.'),
  Subheading('④ Baca Surat Al-Fatihah'),
  Paragraph('Wajib di setiap rakaat. Bacakan dengan tartil (pelan-pelan, jelas):'),
  EducatorNote('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nBismillahirrahmanirrahim.\nDengan nama Allah Yang Maha Pengasih lagi Maha Penyayang.\n\nالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ\nAlhamdulillahi rabbil \'alamin.\nSegala puji bagi Allah, Tuhan seluruh alam.\n\nالرَّحْمَٰنِ الرَّحِيمِ\nAr rahmanir rahim.\nYang Maha Pengasih lagi Maha Penyayang.\n\nمَالِكِ يَوْمِ الدِّينِ\nMaliki yawmid din.\nPemilik hari pembalasan.\n\nإِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ\nIyya na\'budu wa iyya nasta\'in.\nHanya kepada Engkaulah kami menyembah dan hanya kepada Engkaulah kami mohon pertolongan.\n\nاهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ\nIhdinash shiratal mustaqim.\nTunjukilah kami jalan yang lurus.\n\nصِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ\nShiratal ladzina an\'amta \'alaihim ghairil maghdubi \'alaihim walad dallin.\n(Yaitu) jalan orang-orang yang telah Engkau beri nikmat, bukan (jalan) mereka yang dimurkai dan bukan (jalan) mereka yang sesat.'),
  Subheading('⑤ Baca Surah Pendek (Al-Ikhlas)'),
  Paragraph('Setelah Al-Fatihah, baca surah pendek. Disarankan Al-Ikhlas untuk pemula:'),
  EducatorNote('قُلْ هُوَ اللَّهُ أَحَدٌ ١ اللَّهُ الصَّمَدُ ٢ لَمْ يَلِدْ وَلَمْ يُولَدْ ٣ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ ٤\nQul huwallahu ahad. Allahus-samad. Lam yalid wa lam yuulad. Wa lam yakun lahu kufuwan ahad.\nKatakanlah: Dia-lah Allah, Yang Maha Esa. Allah tempat meminta. Dia tidak beranak dan tidak diperanakkan. Dan tidak ada sesuatu pun yang setara dengan Dia.'),
  Subheading('⑥ Ruku'),
  Paragraph('Angkat tangan sambil ucap "Allahu Akbar", lalu bungkuk. Posisi: tangan pegang lutut, punggung lurus, pandangan ke kaki. Baca:'),
  EducatorNote('سُبْحَانَ رَبِّيَ الْعَظِيمِ وَبِحَمْدِهِ\nSubhana rabbiyal \'adzimi wa bihamdih.\nMaha Suci Tuhanku Yang Maha Agung dan dengan memuji-Nya.'),
  Subheading('⑦ I\'tidal'),
  Paragraph('Bangun dari ruku, berdiri tegak. Angkat tangan sambil ucap "Sami\'allahu liman hamidah" (Allah mendengar orang yang memuji-Nya). Lalu baca:'),
  EducatorNote('رَبَّنَا لَكَ الْحَمْدُ مِلْءَ السَّمَاوَاتِ وَمِلْءَ الْأَرْضِ وَمِلْءَ مَا شِئْتَ مِنْ شَيْءٍ بَعْدُ\nRobbana lakal hamdu mil\'as samawati wa mil\'ul ardhi wa mil\'a ma syi\'ta min sya\'in ba\'du.\nYa Tuhan kami, bagi-Mu segala pujian, sepenuh langit dan sepenuh bumi, dan sepenuh apa yang Engkau kehendaki setelah itu.'),
  Subheading('⑧ Sujud Pertama'),
  Paragraph('Ucap "Allahu Akbar" sambil turun ke sujud. Posisi: dahi dan hidung menyentuh lantai, kedua telapak tangan di samping telinga, kedua lutut di lantai, ujung jari kaki menekuk. Baca 3 kali:'),
  EducatorNote('سُبْحَانَ رَبِّيَ الْأَعْلَى وَبِحَمْدِهِ\nSubhana rabbiyal a\'la wa bihamdih.\nMaha Suci Tuhanku Yang Maha Tinggi dan dengan memuji-Nya.'),
  Subheading('⑨ Duduk Antara Dua Sujud'),
  Paragraph('Bangun dari sujud pertama, duduk sebentar. Posisi: kaki kiri diduduki, kaki kanan tegak (iftirasy). Baca:'),
  EducatorNote('اللَّهُمَّ اغْفِرْ لِي وَارْحَمْنِي وَاجْبُرْنِي وَارْفَعْنِي وَاعْفُ عَنِّي وَارْزُقْنِي\nAllahummaghfirli warhamni wajburni warfa\'ni wa\'fu \'anni warzuqni.\nYa Allah, ampunilah aku, rahmatilah aku, cukupkanlah aku, angkatlah derajatku, maafkanlah aku, dan berilah aku rezeki.'),
  Subheading('⑩ Sujud Kedua'),
  Paragraph('Turun sujud lagi (posisi sama seperti sujud pertama). Baca "Subhana rabbiyal a\'la wa bihamdih" 3 kali.'),
  Highlight('Satu rakaat = berdiri → takbir → Fatihah → surah pendek → ruku → i\'tidal → sujud 1 → duduk → sujud 2. Ulangi untuk rakaat berikutnya.'),
  DividerBlock(),
  Subheading('🕋 RAKAAT 2'),
  Paragraph('Bangun dari sujud kedua, berdiri tegak. Ulangi dari langkah ④ (Al-Fatihah) sampai ⑩ (sujud kedua). Tapi di rakaat 2, SETELAH sujud kedua, LANGSUNG duduk (jangan berdiri dulu).'),
  Subheading('⑪ Tasyahud Awal (Duduk di Rakaat 2)'),
  Paragraph('Duduk iftirasy. Baca tasyahud awal:'),
  EducatorNote('التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ\n\nAt-tahiyyatu lillahi wash-shalawatu wat-thayyibat. As-salamu \'alaika ayyuhan-nabiyyu wa rahmatullahi wa barakatuh. As-salamu \'alaina wa \'ala \'ibadillahish-shalihin. Asyhadu an la ilaha illallah wa asyhadu anna Muhammadan \'abduhu wa rasuluh.\n\nSegala penghormatan, sholawat, dan kebaikan adalah milik Allah. Semoga keselamatan, rahmat, dan berkah Allah tercurah kepadamu wahai Nabi. Semoga keselamatan tercurah kepada kami dan hamba-hamba Allah yang shaleh. Aku bersaksi bahwa tiada Tuhan selain Allah dan aku bersaksi bahwa Muhammad adalah hamba dan utusan-Nya.'),
  Paragraph('Setelah tasyahud awal, berdiri lagi untuk rakaat 3 dan 4 (kalau sholat 4 rakaat). Untuk sholat 2 rakaat, langsung lanjut ke tasyahud akhir.'),
  Subheading('⑫ Tasyahud Akhir'),
  Paragraph('Duduk iftirasy. Baca tasyahud akhir (sama seperti tasyahud awal, tapi DITAMBAH bacaan sholawat dan dua kalimat syahadat):'),
  EducatorNote('(Baca tasyahud awal seperti di atas, lalu lanjut:)\n\nاللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ\nAllahumma shalli \'ala Muhammad wa \'ala ali Muhammad kama shallaita \'ala Ibrahim wa \'ala ali Ibrahim innaka hamidun majid.\nYa Allah, berilah sholawat kepada Muhammad dan keluarga Muhammad sebagaimana Engkau telah memberikan sholawat kepada Ibrahim dan keluarga Ibrahim, sesungguhnya Engkau Maha Terpuji lagi Maha Mulia.\n\nاللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ\nAllahumma barik \'ala Muhammad wa \'ala ali Muhammad kama barakta \'ala Ibrahim wa \'ala ali Ibrahim innaka hamidun majid.\nYa Allah, berilah berkah kepada Muhammad dan keluarga Muhammad sebagaimana Engkau telah memberikan berkah kepada Ibrahim dan keluarga Ibrahim, sesungguhnya Engkau Maha Terpuji lagi Maha Mulia.'),
  Subheading('⑬ Salam'),
  Paragraph('Putar kepala ke kanan, ucapkan:'),
  EducatorNote('السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ\nAssalamu\'alaikum warahmatullah.\nSemoga keselamatan dan rahmat Allah tercurah kepadamu.'),
  Paragraph('Lalu putar kepala ke kiri, ucapkan hal yang sama. Salam ke kanan = untuk malaikat dan orang di kanan. Salam ke kiri = untuk orang di kiri. Ini tanda sholat SELESAI.'),
  DividerBlock(),
  Subheading('📐 Penyesuaian Rakaat'),
  Paragraph('• Sholat 2 rakaat: selesai di tasyahud akhir + salam. (Subuh, Jumat, Idul Fitri/Adha)'),
  Paragraph('• Sholat 3 rakaat: setelah tasyahud awal, berdiri lagi untuk rakaat 3 (cuma baca Al-Fatihah, tanpa surah pendek). Lalu duduk tasyahud akhir + salam. (Maghrib)'),
  Paragraph('• Sholat 4 rakaat: setelah tasyahud awal, berdiri untuk rakaat 3 dan 4 (cuma baca Al-Fatihah). Lalu duduk tasyahud akhir + salam. (Dzuhur, Ashar, Isya)'),
  Highlight('Ingat: di rakaat 3 dan 4, CUMA baca Al-Fatihah. Gak usah tambah surah pendek.'),
  DividerBlock(),
  Subheading('💡 Tips Pemula'),
  Paragraph('• Mulai dari sholat Subuh (2 rakaat) aja dulu. Kalau udah lancar, baru tambah ke Maghrib (3 rakaat), lalu Dzuhur/Ashar/Isya (4 rakaat).'),
  Paragraph('• Gak harus hafal semua bacaan di hari pertama. Mulai dari Al-Fatihah dulu, yang lain nambah pelan-pelan.'),
  Paragraph('• Sholat itu percakapan sama Allah. Gak perlu perfect — yang penting niat dan usaha. Allah tahu kamu lagi belajar.'),
  Cta('Kamu udah baca panduan lengkap sholat! 🎉 Sekarang coba praktikkan, dan jawab kuisnya. Gak harus perfect — yang penting mulai. 🚀'),
];

const _praktik3_4Article = <ArticleBlock>[
  Heading('Bacaan-Bacaan Penting dalam Sholat'),
  Paragraph('Modul ini cheat-sheet. Semua bacaan sholat dikumpulin di satu tempat biar gampang dicari ulang. Bookmark halaman ini — kamu bakal sering balik ke sini.'),
  DividerBlock(),
  Subheading('🛐 Takbiratul Ihram'),
  Paragraph('Kapan: awal sholat, sambil angkat tangan.'),
  EducatorNote('اللَّهُ أَكْبَرُ\nAllahu Akbar.\nAllah Maha Besar.'),
  Subheading('📖 Doa Iftitah'),
  Paragraph('Kapan: setelah takbiratul ihram, sebelum Al-Fatihah.'),
  EducatorNote('اللَّهُ أَكْبَرُ كَبِيرًا وَالْحَمْدُ لِلَّهِ كَثِيرًا وَسُبْحَانَ اللَّهِ بُكْرَةً وَأَصِيلًا\nAllahu akbaru kabiro wal hamdulillahi katsiro wa subhanallahi bukratan wa asila.\nAllah Maha Besar dengan segala kebesaran, segala puji bagi Allah dengan pujian yang banyak, Maha Suci Allah pada pagi dan petang hari.'),
  Subheading('📖 Al-Fatihah (WAJIB setiap rakaat)'),
  EducatorNote('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nBismillahirrahmanirrahim.\n\nالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۞ الرَّحْمَٰنِ الرَّحِيمِ ۞ مَالِكِ يَوْمِ الدِّينِ ۞ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۞ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ ۞ صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ\n\nAlhamdulillahi rabbil \'alamin. Ar rahmanir rahim. Maliki yawmid din. Iyya na\'budu wa iyya nasta\'in. Ihdinash shiratal mustaqim. Shiratal ladzina an\'amta \'alaihim ghairil maghdubi \'alaihim walad dallin.\n\nSegala puji bagi Allah Tuhan seluruh alam. Yang Maha Pengasih lagi Maha Penyayang. Pemilik hari pembalasan. Hanya kepada Engkaulah kami menyembah dan hanya kepada Engkaulah kami mohon pertolongan. Tunjukilah kami jalan yang lurus, (yaitu) jalan orang-orang yang telah Engkau beri nikmat, bukan (jalan) mereka yang dimurkai dan bukan (jalan) mereka yang sesat.'),
  Subheading('📖 Surah Pendek (contoh: Al-Ikhlas)'),
  Paragraph('Kapan: setelah Al-Fatihah di rakaat 1 dan 2.'),
  EducatorNote('قُلْ هُوَ اللَّهُ أَحَدٌ ۞ اللَّهُ الصَّمَدُ ۞ لَمْ يَلِدْ وَلَمْ يُولَدْ ۞ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ\nQul huwallahu ahad. Allahus-samad. Lam yalid wa lam yuulad. Wa lam yakun lahu kufuwan ahad.\n\nKatakanlah: Dia-lah Allah, Yang Maha Esa. Allah tempat meminta. Dia tidak beranak dan tidak diperanakkan. Dan tidak ada sesuatu pun yang setara dengan Dia.'),
  Subheading('🤲 Ruku'),
  Paragraph('Kapan: setelah surah pendek, sambil bungkuk.'),
  EducatorNote('سُبْحَانَ رَبِّيَ الْعَظِيمِ وَبِحَمْدِهِ\nSubhana rabbiyal \'adzimi wa bihamdih.\nMaha Suci Tuhanku Yang Maha Agung dan dengan memuji-Nya.'),
  Subheading('🧍 I\'tidal'),
  Paragraph('Kapan: bangun dari ruku, berdiri tegak.'),
  EducatorNote('سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ\nSami\'allahu liman hamidah.\nAllah mendengar orang yang memuji-Nya.\n\nرَبَّنَا لَكَ الْحَمْدُ مِلْءَ السَّمَاوَاتِ وَمِلْءَ الْأَرْضِ وَمِلْءَ مَا شِئْتَ مِنْ شَيْءٍ بَعْدُ\nRobbana lakal hamdu mil\'as samawati wa mil\'ul ardhi wa mil\'a ma syi\'ta min sya\'in ba\'du.\nYa Tuhan kami, bagi-Mu segala pujian, sepenuh langit dan sepenuh bumi, dan sepenuh apa yang Engkau kehendaki setelah itu.'),
  Subheading('🙇 Sujud'),
  Paragraph('Kapan: posisi sujud pertama dan kedua, baca 3 kali.'),
  EducatorNote('سُبْحَانَ رَبِّيَ الْأَعْلَى وَبِحَمْدِهِ\nSubhana rabbiyal a\'la wa bihamdih.\nMaha Suci Tuhanku Yang Maha Tinggi dan dengan memuji-Nya.'),
  Subheading('🧘 Duduk Antara Dua Sujud'),
  Paragraph('Kapan: setelah sujud pertama, sebelum sujud kedua.'),
  EducatorNote('اللَّهُمَّ اغْفِرْ لِي وَارْحَمْنِي وَاجْبُرْنِي وَارْفَعْنِي وَاعْفُ عَنِّي وَارْزُقْنِي\nAllahummaghfirli warhamni wajburni warfa\'ni wa\'fu \'anni warzuqni.\nYa Allah, ampunilah aku, rahmatilah aku, cukupkanlah aku, angkatlah derajatku, maafkanlah aku, dan berilah aku rezeki.'),
  Subheading('🪑 Tasyahud Awal'),
  Paragraph('Kapan: duduk di akhir rakaat ke-2 (sholat 3/4 rakaat).'),
  EducatorNote('التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ\n\nAt-tahiyyatu lillahi wash-shalawatu wat-thayyibat. As-salamu \'alaika ayyuhan-nabiyyu wa rahmatullahi wa barakatuh. As-salamu \'alaina wa \'ala \'ibadillahish-shalihin. Asyhadu an la ilaha illallah wa asyhadu anna Muhammadan \'abduhu wa rasuluh.\n\nSegala penghormatan, sholawat, dan kebaikan adalah milik Allah. Semoga keselamatan, rahmat, dan berkah Allah tercurah kepadamu wahai Nabi. Semoga keselamatan tercurah kepada kami dan hamba-hamba Allah yang shaleh. Aku bersaksi bahwa tiada Tuhan selain Allah dan aku bersaksi bahwa Muhammad adalah hamba dan utusan-Nya.'),
  Subheading('🪑 Tasyahud Akhir'),
  Paragraph('Kapan: duduk rakaat terakhir, sebelum salam. = Tasyahud awal + sholawat.'),
  EducatorNote('(Baca tasyahud awal di atas, lalu lanjut:)\n\nاللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ\nAllahumma shalli \'ala Muhammad wa \'ala ali Muhammad kama shallaita \'ala Ibrahim wa \'ala ali Ibrahim innaka hamidun majid.\n\nاللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ\nAllahumma barik \'ala Muhammad wa \'ala ali Muhammad kama barakta \'ala Ibrahim wa \'ala ali Ibrahim innaka hamidun majid.\n\nYa Allah, berilah sholawat dan berkah kepada Muhammad dan keluarga Muhammad sebagaimana Engkau telah memberikan sholawat dan berkah kepada Ibrahim dan keluarga Ibrahim, sesungguhnya Engkau Maha Terpuji lagi Maha Mulia.'),
  Subheading('👋 Salam'),
  Paragraph('Kapan: akhir sholat, putar ke kanan lalu ke kiri.'),
  EducatorNote('السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ\nAssalamu\'alaikum warahmatullah.\nSemoga keselamatan dan rahmat Allah tercurah kepadamu.'),
  Cta('Cheat-sheet selesai! Simpan modul ini buat referensi. Jawab kuisnya ya. 🎯'),
];

const _praktik3_5Article = <ArticleBlock>[
  Heading('Sholat 5 Waktu: Kapan dan Berapa Rakaat?'),
  Paragraph('Kamu udah tahu cara sholat. Sekarang pertanyaannya: kapan aja sih sholatnya, dan berapa rakaat tiap waktu?'),
  DividerBlock(),
  Subheading('⏰ 5 Waktu Sholat Wajib'),
  Paragraph('① SUBUH — 2 rakaat\nWaktu: dari terbit fajar (sekitar jam 4:30-an) sampai terbit matahari. Ini sholat paling awal — bangunnya emang berat, tapi pahalanya gede banget.'),
  Paragraph('② DZUHUR — 4 rakaat\nWaktu: setelah matahari condong ke barat (sekitar jam 12:00-an) sampai masuk waktu Ashar. Sholat siang hari, biasanya pas istirahat kerja/kuliah.'),
  Paragraph('③ ASHAR — 4 rakaat\nWaktu: ketika bayangan benda sama panjangnya dengan benda itu sendiri (sekitar jam 15:00-an) sampai terbenam matahari. Nabi ﷺ bilang ini waktu yang sangat dianjurkan.'),
  Paragraph('④ MAGHRIB — 3 rakaat\nWaktu: setelah matahari terbenam (sekitar jam 18:00-an) sampai hilang mega merah di langit. Satu-satunya sholat wajib 3 rakaat.'),
  Paragraph('⑤ ISYA — 4 rakaat\nWaktu: setelah mega merah hilang (sekitar jam 19:15-an) sampai tengah malam (atau terbit fajar menurut sebagian ulama). Sholat terakhir di hari itu.'),
  Highlight('Subuh = 2, Dzuhur = 4, Ashar = 4, Maghrib = 3, Isya = 4. Total: 17 rakaat sehari. Cuma 17 — gak banyak kok kalau dibagi sepanjang hari.'),
  Subheading('🤔 Kenapa Rakaatnya Beda-Beda?'),
  Paragraph('Jumlah rakaat ditentukan langsung oleh Nabi Muhammad ﷺ berdasarkan wahyu. Subuh cuma 2 karena waktunya pendek (fajar ke terbit matahari). Maghrib 3 sebagai "transisi" antara siang dan malam. Dzuhur, Ashar, Isya masing-masing 4 karena waktunya lebih panjang.'),
  Paragraph('Gak ada alasan "kenapa" yang bisa dijelasin secara logika 100% — ini udah ketetapan dari Allah lewat Nabi-Nya. Yang jelas: setiap jumlah rakaat punya hikmah.'),
  Subheading('📱 Mau Mulai Tracking?'),
  Paragraph('Kalau kamu udah siap mulai sholat 5 waktu, buka tab Home di app ini. Di sana kamu bisa tracking sholat harian, lihat waktu sholat buat kotamu, dan kumpulin XP setiap kali sholat!'),
  Cta('Sekarang kamu tahu jadwalnya! Jawab kuis dulu, lalu mulai sholat dari yang paling gampang (Subuh). 🎯'),
];

const _praktik3_6Article = <ArticleBlock>[
  Heading('Hal-Hal yang Sering Bikin Bingung Pemula'),
  Paragraph('Ini modul terakhir! Kita bakal jawab pertanyaan-pertanyaan yang paling sering ditanya pemula. Kalau kamu punya pertanyaan yang gak ada di sini, tanya ke orang yang lebih paham atau ustadz terdekat.'),
  DividerBlock(),
  Subheading('❓ "Gimana kalau lupa udah rakaat keberapa?"'),
  Paragraph('Ini normal banget, apalagi pas awal-awal. Solusinya: ambil yang lebih sedikit. Kalau bingung antara rakaat 2 atau 3, anggap aja kamu di rakaat 2. Tambah 1 rakaat, lalu duduk tasyahud akhir + salam. Setelah salam, sujud sahwi (2 sujud tambahan) sebagai kompensasi kelupaan.'),
  Highlight('Lupa itu manusiawi. Gak usah panik. Ambil yang lebih sedikit, tambah sujud sahwi. Sholatmu tetap sah.'),
  Subheading('❓ "Gimana kalau gak hafal bacaan panjang?"'),
  Paragraph('Gak masalah! Yang WAJIB itu Al-Fatihah di setiap rakaat. Surah pendek setelahnya? Boleh baca surah APA SAJA yang kamu hafal. Al-Ikhlas, An-Nas, Al-Falaq, Al-Kautsar, bahkan ayat kursi — bebas.'),
  Paragraph('Kalau gak hafal surah pendek sama sekali? Fokus hafalin Al-Fatihah dulu. Itu yang paling wajib. Surah pendek bisa ditambah pelan-pelan. Nabi ﷺ sendiri bilang: "Bacalah apa yang mudah bagimu."'),
  Subheading('❓ "Sholat jamak dan qashar itu apa?"'),
  Paragraph('Ini keringanan khusus untuk orang yang sedang dalam perjalanan (musafir):'),
  Paragraph('• JAMAK — menggabungkan dua sholat di satu waktu. Jamak taqdim: Dzuhur + Ashar di waktu Dzuhur. Jamak takhir: Maghrib + Isya di waktu Isya. Bisa juga jamak di Arafah (Dzuhur + Ashar) dan di Muzdalifah (Maghrib + Isya).'),
  Paragraph('• QASHAR — meringkas sholat 4 rakaat jadi 2 rakaat. Boleh untuk Dzuhur, Ashar, dan Isya. Syaratnya: musafir (perjalanan jauh, biasanya > 80 km).'),
  Paragraph('Jamak dan qashar boleh digabung. Jadi Dzuhur + Ashar bisa dijamak dan diqashar jadi 2 rakaat + 2 rakaat di satu waktu. Ini keringanan dari Allah — Islam itu gak memberatkan.'),
  Subheading('❓ "Boleh sholat pakai bahasa Indonesia?"'),
  Paragraph('Ini pertanyaan yang sering banget muncul. Jawabannya:'),
  Paragraph('Bacaan rukun sholat (Al-Fatihah, takbir, ruku, sujud, tasyahud, salam) HARUS dalam bahasa Arab. Kenapa? Karena Al-Quran diturunkan dalam bahasa Arab, dan sholat itu ibadah yang udah distandarkan oleh Nabi ﷺ. Mengubah bacaan rukun = mengubah ibadah yang udah ditetapkan.'),
  Paragraph('TAPI — doa tambahan di luar rukun (misalnya doa setelah tasyahud akhir, sebelum salam) boleh pakai bahasa apa aja, termasuk Indonesia. Jadi kamu bisa berdoa pakai bahasa sendiri setelah selesai bacaan wajib.'),
  Highlight('Bacaan rukun = Arab (wajib). Doa tambahan = bebas bahasa apa aja. Ini biar sholatmu tetap terstandar tapi tetap bisa curhat sama Allah pakai bahasamu sendiri.'),
  Subheading('❓ "Sholatku belum perfect, sah gak?"'),
  Paragraph('Kalau syarat sah terpenuhi dan rukunnya ada — sah. Gak harus perfect. Nabi ﷺ sendiri ngajarin orang yang baru masuk Islam pelan-pelan. Allah tahu kamu lagi belajar.'),
  Paragraph('Yang penting: JANGAN BERHENTI. Sholat yang gak perfect itu lebih baik dari gak sholat sama sekali. Lama-lama bakal makin lancar. Semua orang juga mulai dari nol.'),
  DividerBlock(),
  Subheading('🎉 Selamat! Kamu Udah Selesai Semua Kategori!'),
  Paragraph('Dari "Kenapa harus percaya Tuhan?" sampai "Hal yang bikin bingung pemula" — kamu udah lewatin 19 modul pembelajaran!'),
  Paragraph('Sekarang kamu punya dasar yang kuat: Akidah (kepercayaan), Rukun Islam (fondasi), dan Praktik Ibadah (cara ngelakuin). Tinggal PRAKTIKKAN. Pelan-pelan, konsisten, dan jangan pernah berhenti belajar.'),
  Cta('Alhamdulillah, semua modul selesai! 🎉 Sekarang buka tab Home dan mulai tracking sholatmu. Kamu udah di jalur yang bener! 🚀'),
];

// ─── Quiz content ───

const _akidah1_1Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Kenapa HP yang canggih dijadiin contoh di artikel ini?',
    options: [
      'Karena HP itu benda paling penting dalam hidup manusia modern',
      'Buat nunjukin teknologi manusia udah nyaingin kompleksitas alam',
      'Karena barang rakitan aja butuh perancang, apalagi alam semesta',
      'Biar pembaca kebayang betapa canggihnya teknologi zaman sekarang',
    ],
    correctIndex: 2,
    explanation: 'Logikanya simpel: kalau HP yang "cuma" elektronik aja ada perancangnya, alam semesta yang jauh lebih kompleks pasti juga dong.',
  ),
  QuizQuestion(
    question: 'Apa itu "argumen sebab-akibat"?',
    options: [
      'Semua hal punya penyebab, sampai berhenti di satu penyebab pertama',
      'Semua kejadian di alam ini saling terhubung tanpa ada titik awalnya',
      'Setiap akibat pasti menghasilkan sebab baru yang lebih besar lagi',
      'Alam semesta muncul dari rangkaian kebetulan yang berulang-ulang',
    ],
    correctIndex: 0,
    explanation: 'Rantai sebab-akibat harus berhenti di satu titik: sesuatu yang gak butuh penyebab lain. Itulah Tuhan.',
  ),
  QuizQuestion(
    question: 'Kenapa keteraturan alam dijadiin bukti ada Tuhan?',
    options: [
      'Karena keindahan alam bikin manusia merasa tenang dan bersyukur',
      'Karena semua kitab suci di dunia sepakat menyebutkan hal itu',
      'Karena manusia dari dulu terbiasa percaya pada kekuatan alam',
      'Karena konsistensi hukum alam miliaran tahun mustahil kebetulan',
    ],
    correctIndex: 3,
    explanation: 'Hukum alam bekerja konsisten selama miliaran tahun — itu gak mungkin kebetulan. Pasti ada yang ngerancang.',
  ),
  QuizQuestion(
    question: 'Menurut artikel, percaya pada Tuhan itu...',
    options: [
      'Urusan perasaan pribadi yang gak ada hubungannya sama logika',
      'Justru didukung oleh logika dan akal sehat manusia',
      'Warisan budaya yang diturunkan dari orang tua ke anak-anaknya',
      'Pilihan gaya hidup yang nilainya sama dengan pilihan lainnya',
    ],
    correctIndex: 1,
    explanation: 'Percaya pada Tuhan bukan soal buta. Justru logika kita sendiri yang ngasih tanda-tanda kuat kalau ada Perancang.',
  ),
  QuizQuestion(
    question: 'Setelah percaya ada Tuhan, langkah selanjutnya menurut artikel adalah...',
    options: [
      'Cari tahu tujuan Dia menciptakan kita dan petunjuk yang Dia kasih',
      'Cukup meyakini dalam hati tanpa perlu mengubah cara hidup kita',
      'Membandingkan dulu semua agama bertahun-tahun sebelum memilih',
      'Langsung menjalankan semua ibadah walaupun belum paham maknanya',
    ],
    correctIndex: 0,
    explanation: 'Kalau memang ada Perancang alam semesta, pasti Dia punya tujuan dan petunjuk. Nah itu yang bakal kita pelajari bareng!',
  ),
];

const _akidah1_2Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Kenapa analogi "dua sopir, satu kemudi" dipake di artikel ini?',
    options: [
      'Buat ngingetin pentingnya kerja sama dalam mengatur sesuatu',
      'Buat nunjukin dua kehendak beda di satu sistem pasti bikin kacau',
      'Buat ngejelasin alam semesta butuh banyak pengatur sekaligus',
      'Buat nunjukin manusia gak sanggup memahami kehendak Tuhan',
    ],
    correctIndex: 1,
    explanation: 'Logikanya: kalau ada dua pihak dengan kehendak beda megang kendali yang sama, hasilnya konflik. Makanya alam semesta yang rapi = bukti satu sumber kehendak.',
  ),
  QuizQuestion(
    question: 'Apa bukti dari keteraturan kosmos kalau Allah itu Esa?',
    options: [
      'Bumi berada di posisi yang pas sehingga manusia bisa hidup nyaman',
      'Jumlah galaksi yang triliunan menunjukkan kekuasaan tanpa batas',
      'Alam semesta terus mengembang ke segala arah sejak awal terbentuk',
      'Hukum fisika berlaku universal dan konsisten selama miliaran tahun',
    ],
    correctIndex: 3,
    explanation: 'Hukum alam yang konsisten di mana pun dan kapan pun = mustahil kalau ada lebih dari satu "pengatur" dengan kehendak berbeda.',
  ),
  QuizQuestion(
    question: 'Menurut artikel, konsep Tauhid di agama-agama besar itu...',
    options: [
      'Udah ada sejak awal sejarah, tapi berubah seiring waktu',
      'Baru dikenal manusia setelah Islam datang di abad ke-7 Masehi',
      'Berkembang perlahan dari kepercayaan banyak dewa jadi satu Tuhan',
      'Hanya diajarkan oleh Nabi Muhammad ﷺ kepada bangsa Arab saja',
    ],
    correctIndex: 0,
    explanation: 'Di awal sejarahnya, Nabi Ibrahim, Musa, dan Isa semuanya ngajarin Tauhid. Islam datang sebagai penyempurnaan dan pengembalian ke ajaran asli.',
  ),
  QuizQuestion(
    question: 'Apa arti "As-Samad" dalam Surat Al-Ikhlas?',
    options: [
      'Yang Maha Esa dan tidak ada sesuatu pun yang menyerupai-Nya',
      'Yang Maha Kuasa atas segala sesuatu di langit dan di bumi',
      'Tempat bergantung segala sesuatu, sedangkan Dia gak butuh apa pun',
      'Yang Maha Pengasih kepada seluruh makhluk ciptaan-Nya',
    ],
    correctIndex: 2,
    explanation: 'As-Samad artinya tempat bergantung. Allah gak butuh siapa-siapa, tapi semua yang ada butuh Dia.',
  ),
  QuizQuestion(
    question: '"Lam yalid wa lam yuulad" artinya...',
    options: [
      'Dia yang menciptakan seluruh manusia dari generasi ke generasi',
      'Dia tidak beranak dan tidak pula diperanakkan',
      'Dia tempat meminta pertolongan bagi seluruh makhluk-Nya',
      'Dia tidak serupa dengan apa pun yang ada di alam semesta',
    ],
    correctIndex: 1,
    explanation: 'Allah gak lahir dari siapa pun dan gak melahirkan siapa pun. Dia ada tanpa sebab — karena Dia SEBAB dari segalanya.',
  ),
];

const _akidah1_3Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Kenapa fakta bahwa Nabi Muhammad ﷺ itu ummi (gak bisa baca-tulis) jadi penting?',
    options: [
      'Karena itu menunjukkan pendidikan gak penting buat jadi orang besar',
      'Karena orang ummi di zaman itu lebih dihormati masyarakat Arab',
      'Karena itu membuktikan dia menghafal isi kitab-kitab terdahulu',
      'Karena mustahil orang gak bisa baca-tulis ngarang teks serumit Al-Quran',
    ],
    correctIndex: 3,
    explanation: 'Secara logika, orang yang gak pernah belajar sastra atau sains gak mungkin menghasilkan teks 30 juz dengan bahasa Arab paling tinggi tingkatnya. Ini jadi argumen kuat kalau Al-Quran bukan karangan manusia.',
  ),
  QuizQuestion(
    question: 'Apa itu i\'jaz Al-Quran?',
    options: [
      'Keajaiban bahasa Al-Quran yang gak bisa ditandingi siapa pun',
      'Ilmu tentang cara membaca Al-Quran dengan tajwid yang benar',
      'Urutan penyusunan surah-surah Al-Quran di dalam mushaf',
      'Metode penghafalan Al-Quran yang diajarkan para sahabat',
    ],
    correctIndex: 0,
    explanation: 'I\'jaz artinya membuat takjub. Bahasa Al-Quran itu unik — bukan puisi, bukan prosa, bukan pidato. Para penyair terbaik Arab pun gagal menandinginya.',
  ),
  QuizQuestion(
    question: 'Al-Quran diwahyukan selama berapa tahun, dan kenapa itu mengagumkan?',
    options: [
      '40 tahun, sesuai umur Nabi ﷺ ketika pertama menerima wahyu',
      '10 tahun, dan selesai sebelum Nabi ﷺ hijrah ke kota Madinah',
      '23 tahun di berbagai kondisi, tapi tetap konsisten tanpa kontradiksi',
      '63 tahun, diwahyukan sepanjang hidup Nabi ﷺ sampai beliau wafat',
    ],
    correctIndex: 2,
    explanation: '23 tahun di kondisi sangat berbeda (minoritas tertindas → pemimpin negara), tapi isinya konsisten tanpa kontradiksi internal. Cobain nulis jurnal 23 tahun tanpa pernah kontradiksi diri — susah banget.',
  ),
  QuizQuestion(
    question: 'Apa yang bikin Al-Quran beda dari kitab suci lain soal preservasi?',
    options: [
      'Ditulis langsung oleh Nabi ﷺ sendiri supaya tidak ada kesalahan',
      'Dijaga lewat tulisan DAN hafalan jutaan orang selama 1.400 tahun',
      'Disimpan dalam satu mushaf induk yang dijaga ketat di Makkah',
      'Diterjemahkan ke semua bahasa sejak zaman para sahabat Nabi',
    ],
    correctIndex: 1,
    explanation: 'Al-Quran dijaga dua cara: ditulis dan dihafal. Jutaan hafiz hafal 30 juz dari luar. Kalau semua mushaf hilang pun, Al-Quran bisa ditulis ulang 100% identik.',
  ),
  QuizQuestion(
    question: 'Sikap yang tepat setelah baca modul ini menurut artikel adalah...',
    options: [
      'Langsung meyakini seluruh isinya tanpa perlu bertanya-tanya lagi',
      'Menganggap semua argumennya benar karena ditulis di app Islami',
      'Renungkan pelan-pelan, tanya-tanya, dan cari tahu sendiri',
      'Menunggu bukti ilmiah baru sebelum mau memikirkannya lebih jauh',
    ],
    correctIndex: 2,
    explanation: 'Artikel bilang: kamu gak harus langsung percaya. Justru bagus kalau mau renungkan pelan-pelan, tanya-tanya, dan cari tahu sendiri. Kebenaran itu layak ditelusuri.',
  ),
];

const _akidah1_4Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Apa julukan Muhammad ﷺ sebelum jadi nabi, dan siapa yang ngasih?',
    options: [
      'Al-Amin (yang terpercaya), dari seluruh masyarakat Makkah',
      'Al-Fatih (sang penakluk), dari para panglima perang Quraisy',
      'Ash-Shiddiq (yang membenarkan), dari keluarga Bani Hasyim',
      'Al-Karim (yang mulia), dari para pedagang di pasar Makkah',
    ],
    correctIndex: 0,
    explanation: 'Al-Amin artinya \'yang terpercaya.\' Julukan ini dikasih oleh seluruh masyarakat Makkah — termasuk yang gak seiman — karena selama 40 tahun hidup di sana, dia gak pernah ketahuan bohong.',
  ),
  QuizQuestion(
    question: 'Kenapa fakta bahwa musuh-musuhnya aja ngakuin dia jujur itu penting?',
    options: [
      'Karena musuh biasanya lebih pintar menilai daripada teman dekat',
      'Karena pengakuan itu bikin musuh-musuhnya langsung masuk Islam',
      'Karena pengakuan dari pihak lawan itu bukti kredibilitas luar biasa',
      'Karena orang Arab zaman dulu terkenal gak pernah bohong sama sekali',
    ],
    correctIndex: 2,
    explanation: 'Abu Sufyan, musuh terbesar Muhammad ﷺ, ketika ditanya \'pernahkah dia berbohong?\' menjawab \'tidak.\' Kredibilitas seorang jujur yang diakui bahkan oleh musuh.',
  ),
  QuizQuestion(
    question: 'Apa yang bikin Muhammad ﷺ beda dari tokoh agama lain?',
    options: [
      'Dia menulis sendiri kitab sucinya berdasarkan ilham dari Tuhan',
      'Dia nabi terakhir yang risalahnya buat seluruh umat manusia',
      'Dia satu-satunya tokoh agama yang pernah memimpin sebuah negara',
      'Dia mengajarkan agamanya khusus untuk bangsa Arab di masanya',
    ],
    correctIndex: 1,
    explanation: 'Nabi mengklaim dapat pesan langsung dari Tuhan. Muhammad ﷺ spesial karena nabi TERAKHIR dan risalahnya buat seluruh manusia, bukan cuma satu kaum.',
  ),
  QuizQuestion(
    question: 'Meskipun jadi pemimpin negara dan panglima perang, hidup Muhammad ﷺ...',
    options: [
      'Bergelimang harta rampasan perang yang terkumpul bertahun-tahun',
      'Berpindah-pindah dari satu kediaman megah ke kediaman lainnya',
      'Dibiayai penuh oleh para sahabatnya yang kaya raya seperti raja',
      'Tetap sederhana — kasur dari tikar, makan sering cuma kurma dan air',
    ],
    correctIndex: 3,
    explanation: 'Meskipun punya kekuasaan besar, hidupnya tetap sederhana. Kekuasaannya gak dipake buat diri sendiri — ini beda banget dari raja atau diktator kebanyakan.',
  ),
  QuizQuestion(
    question: 'Apa hubungan antara karakter Muhammad ﷺ dengan kebenaran kerasulannya?',
    options: [
      'Orang se-jujur itu gak mungkin ngarang soal Tuhan',
      'Karakter baik otomatis membuat semua ucapannya jadi wahyu',
      'Kejujurannya baru muncul setelah dia diangkat menjadi nabi',
      'Karakternya gak relevan, yang penting isi kitab sucinya aja',
    ],
    correctIndex: 0,
    explanation: 'Muhammad ﷺ jujur sebelum jadi nabi, jujur sesudah jadi nabi. Konsistensi karakternya selama puluhan tahun jadi argumen kuat: orang se-jujur ini gak mungkin bohong soal Tuhan.',
  ),
];

const _akidah1_5Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Iman itu terdiri dari berapa komponen, apa aja?',
    options: [
      'Satu aja: keyakinan yang tertanam kuat di dalam hati',
      'Dua: keyakinan di dalam hati dan diucapkan dengan lisan',
      'Tiga: diyakini hati, diucapkan lisan, dibuktikan perbuatan',
      'Empat: hati, lisan, perbuatan, dan diwariskan ke keturunan',
    ],
    correctIndex: 2,
    explanation: 'Iman itu tiga komponen: keyakinan di hati, diucapkan lewat lisan, dan dibuktikan lewat perbuatan. Kalau cuma satu aja, belum sempurna.',
  ),
  QuizQuestion(
    question: 'Kenapa percaya kepada Malaikat itu penting?',
    options: [
      'Karena malaikat yang menentukan takdir baik-buruk manusia',
      'Karena malaikat bisa dimintai pertolongan saat kita kesulitan',
      'Karena tanpa malaikat, wahyu gak akan pernah sampai ke manusia',
      'Karena mereka bukti alam ini lebih luas dari yang keliatan mata',
    ],
    correctIndex: 3,
    explanation: 'Malaikat punya tugas penting: nyampein wahyu, mencatat amal, mendoain orang baik. Mereka bukti kalau ada dimensi lain di luar yang bisa kita lihat.',
  ),
  QuizQuestion(
    question: 'Apa bedanya kitab-kitab sebelumnya dengan Al-Quran?',
    options: [
      'Al-Quran kitab terakhir yang terjaga keasliannya sampai sekarang',
      'Kitab-kitab sebelumnya diturunkan dalam bahasa yang lebih sulit',
      'Al-Quran satu-satunya kitab yang berisi kisah para nabi terdahulu',
      'Kitab-kitab sebelumnya cuma berlaku buat para nabi penerimanya',
    ],
    correctIndex: 0,
    explanation: 'Allah ngasih petunjuk lewat beberapa kitab. Tapi yang terakhir dan terjaga keasliannya adalah Al-Quran. Kitab sebelumnya udah mengalami perubahan seiring waktu.',
  ),
  QuizQuestion(
    question: 'Apa arti percaya Hari Akhir dalam kehidupan sehari-hari?',
    options: [
      'Bikin kita takut mati sehingga lebih berhati-hati dalam bertindak',
      'Bikin hidup lebih bermakna karena tiap perbuatan ada konsekuensinya',
      'Bikin kita fokus ibadah aja dan meninggalkan semua urusan dunia',
      'Bikin kita pasrah karena semua sudah ditentukan sejak awal zaman',
    ],
    correctIndex: 1,
    explanation: 'Percaya Hari Akhir bikin hidup lebih bermakna. Kamu tahu apa yang kamu lakuin sekarang ada konsekuensinya — jadi hidup gak sekadar buat senang-senang.',
  ),
  QuizQuestion(
    question: 'Qada dan Qadar (takdir) berarti kamu pasif dan gak usah usaha?',
    options: [
      'Iya, karena hasil akhir semua urusan udah ditulis sejak azali',
      'Iya, usaha itu cuma formalitas karena gak mengubah apa-apa',
      'Engga, tapi takdir cuma berlaku buat hal-hal besar dalam hidup',
      'Engga — kamu wajib berusaha, hasilnya serahkan ke Allah',
    ],
    correctIndex: 3,
    explanation: 'Qadar itu kayak GPS: rute udah ditentukan, tapi kamu tetep harus nyetir. Kamu WAJIB berusaha — yang penting udah ngelakuin bagianmu, hasilnya urusan Allah.',
  ),
];

const _akidah1_6Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Apa yang menarik dari pasangan kata "ad-dunya" dan "al-akhirah" di Al-Quran?',
    options: [
      'Dua-duanya disebut dalam surah yang sama secara berurutan',
      'Sama-sama disebut 115 kali — jumlah yang identik',
      'Dua-duanya cuma disebut di surah-surah Makkiyah aja',
      'Jumlah penyebutan keduanya sama dengan jumlah hari dalam setahun',
    ],
    correctIndex: 1,
    explanation: '"Ad-dunya" (dunia) dan "al-akhirah" (akhirat) masing-masing disebut 115 kali. Ini cuma satu dari puluhan pasangan kata yang jumlahnya sama persis di Al-Quran.',
  ),
  QuizQuestion(
    question: 'Berapa kali kata "yawm" (hari) dalam bentuk tunggal disebut di Al-Quran?',
    options: [
      '360 kali — mendekati jumlah hari dalam setahun',
      '365 kali — tepat sama dengan jumlah hari dalam setahun',
      '354 kali — sesuai tahun Hijriyah (kalender bulan)',
      '7 kali — jumlah hari dalam seminggu',
    ],
    correctIndex: 1,
    explanation: 'Kata "yawm" (hari) dalam bentuk tunggal disebut 365 kali — persis jumlah hari dalam setahun. Sementara bentuk jamaknya (ayyam) disebut 30 kali — jumlah hari dalam sebulan.',
  ),
  QuizQuestion(
    question: 'Proporsi penyebutan laut dan darat di Al-Quran (32:13) ternyata setara dengan...',
    options: [
      'Jumlah lautan dan samudra di permukaan bumi',
      'Proporsi air dan daratan di bumi: ±71% air, ±29% darat',
      'Perbandingan panjang garis pantai dengan luas daratan',
      'Jumlah negara yang punya pantai dibanding yang tidak',
    ],
    correctIndex: 1,
    explanation: 'Laut disebut 32x, darat 13x. Total 45. 32/45 = 71,1% dan 13/45 = 28,9%. Ini cocok dengan proporsi air (71%) dan daratan (29%) di bumi — yang baru diketahui setelah satelit modern.',
  ),
  QuizQuestion(
    question: 'Menurut artikel, bagaimana sikap yang tepat terhadap temuan pola angka di Al-Quran?',
    options: [
      'Harus langsung percaya karena ini bukti paling kuat dari semua bukti',
      'Anggap saja kebetulan karena manusia memang suka mencari pola',
      'Pikirkan sendiri — dua-duanya valid, tapi makin banyak pola makin kecil kemungkinan kebetulan',
      'Komentari bahwa hitungan ini hanya ditemukan ilmuwan modern jadi gak valid',
    ],
    correctIndex: 2,
    explanation: 'Artikel bilang: dua-duanya valid. Tapi makin banyak pola yang ditemukan dan konsisten, makin kecil kemungkinan itu semua cuma kebetulan. Kamu yang nilai sendiri.',
  ),
  QuizQuestion(
    question: 'Temuan pola angka dalam Al-Quran ini ditemukan dengan cara apa?',
    options: [
      'Disebutkan langsung oleh Nabi Muhammad ﷺ dalam Hadits',
      'Ditulis dalam kitab tafsir klasik sejak zaman sahabat',
      'Ditemukan pakai penelitian komputer modern yang menganalisis kata',
      'Diketahui dari prasasti kuno di sekitar kota Makkah',
    ],
    correctIndex: 2,
    explanation: 'Pola-pola ini baru ditemukan setelah penelitian komputer modern yang menganalisis frekuensi kata di seluruh Al-Quran. Ini yang bikin makin menarik — teknologi modern makin ngebuktiin kedalaman Al-Quran.',
  ),
];

const _akidah1_7Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Angka berapa yang punya tempat istimewa dalam Al-Quran dan disebut dalam QS. Al-Muddassir: 30?',
    options: [
      '7',
      '19',
      '99',
      '313',
    ],
    correctIndex: 1,
    explanation: 'QS. Al-Muddassir: 30 — "Di atasnya ada 19 (malaikat penjaga)." Angka 19 muncul dalam banyak pola di Al-Quran: Basmalah 19 huruf, 114 surah (19×6), dll.',
  ),
  QuizQuestion(
    question: 'Berapa jumlah total surah dalam Al-Quran?',
    options: [
      '113',
      '114',
      '115',
      '120',
    ],
    correctIndex: 1,
    explanation: 'Al-Quran punya 114 surah. 114 = 19 × 6.',
  ),
  QuizQuestion(
    question: 'Apa hubungan nomor Surah Al-Ikhlas (112) dengan jumlah ayatnya (4)?',
    options: [
      'Tidak ada hubungan — ini murni kebetulan biasa',
      '1+1+2=4, sama dengan jumlah ayatnya',
      '112 - 4 = 108, jumlah surah lain yang belum disebut',
      '112 ÷ 4 = 28, jumlah huruf hijaiyah dalam bahasa Arab',
    ],
    correctIndex: 1,
    explanation: 'Surah Al-Ikhlas nomor 112. 1+1+2 = 4, sama dengan jumlah ayatnya. Surah An-Nas (114): 1+1+4 = 6, juga sama dengan jumlah ayatnya.',
  ),
  QuizQuestion(
    question: 'Berapa kali kata "shalawat" (sholat) disebut dalam Al-Quran?',
    options: [
      '17 kali — jumlah rakaat sholat wajib sehari',
      '5 kali — jumlah sholat wajib sehari semalam',
      '3 kali — jumlah sholat yang dijamak saat safar',
      '12 kali — jumlah rakaat sholat sunnah rawatib',
    ],
    correctIndex: 1,
    explanation: 'Kata "shalawat" (sholat) disebut 5 kali dalam Al-Quran — sama dengan jumlah sholat wajib sehari semalam.',
  ),
  QuizQuestion(
    question: 'Apa kesimpulan yang diajukan artikel soal pola angka di Al-Quran?',
    options: [
      'Ini bukti paling kuat dan final bahwa Al-Quran dari Allah',
      'Ini semua kebetulan dan gak ada hubungannya sama apa pun',
      'Makin banyak pola yang konsisten, makin kecil kemungkinan itu cuma kebetulan',
      'Pola angka ini hanya berlaku untuk Al-Quran edisi cetakan tertentu',
    ],
    correctIndex: 2,
    explanation: 'Bukan satu-dua pola — tapi puluhan/ratusan, semuanya konsisten. Semakin banyak polanya, semakin kecil kemungkinan itu semua kebetulan belaka.',
  ),
];

const _akidah1_8Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Apa nubuatan Al-Quran yang terbukti terjadi tentang Romawi?',
    options: [
      'Romawi akan hancur total dan tidak pernah bangkit lagi',
      'Kekaisaran Romawi akan terpecah menjadi dua bagian',
      'Romawi akan menang lagi dalam beberapa tahun setelah dikalahkan',
      'Romawi akan bersekutu dengan Persia menyerang Arab',
    ],
    correctIndex: 2,
    explanation: 'QS. Ar-Rum: 1-4 bilang Romawi bakal menang lagi dalam beberapa tahun setelah dikalahkan Persia. Saat itu ini terdengar mustahil, tapi benar terjadi ~7-9 tahun kemudian.',
  ),
  QuizQuestion(
    question: 'Apa yang sains modern temukan tentang gunung yang sesuai dengan deskripsi Al-Quran?',
    options: [
      'Gunung terbentuk dari aktivitas gunung berapi di dasar laut',
      'Gunung tertinggi di dunia ada di bawah laut, bukan di daratan',
      'Gunung punya "akar" yang menjulur dalam ke bumi seperti pasak',
      'Gunung selalu bergerak beberapa cm setiap tahunnya',
    ],
    correctIndex: 2,
    explanation: 'QS. An-Naba': 6-7 bilang gunung sebagai pasak (autad). Geologi modern mengkonfirmasi gunung punya akar yang menjulur jauh ke dalam bumi, berfungsi seperti pasak yang menstabilkan lempeng tektonik.',
  ),
  QuizQuestion(
    question: 'Kenapa Al-Quran nyebut "jari-jemari" secara spesifik dalam QS. Al-Qiyamah: 4?',
    options: [
      'Karena jari adalah anggota tubuh yang paling sering digunakan',
      'Karena sidik jari setiap manusia unik — bahkan kembar identik pun beda',
      'Karena jumlah ruas jari (14) sama dengan jumlah sujud dalam sholat',
      'Karena jari adalah simbol kekuatan dan ketangkasan manusia',
    ],
    correctIndex: 1,
    explanation: 'Kenapa Al-Quran spesifik nyebut jari? Karena sidik jari tiap manusia UNIK — fakta yang baru ditemukan sains abad ke-19. Al-Quran udah ngasih tahu 12 abad sebelumnya.',
  ),
  QuizQuestion(
    question: 'Al-Quran diturunkan dalam 23 tahun di 2 kota berbeda. Apa yang membuat ini menarik?',
    options: [
      'Karena dua kota itu saling berperang saat Al-Quran diturunkan',
      'Karena bahasanya berbeda antara ayat Makkah dan Madinah',
      'Karena isinya tetap konsisten tanpa kontradiksi meski situasi beda',
      'Karena para penulisnya berganti-ganti sepanjang 23 tahun itu',
    ],
    correctIndex: 2,
    explanation: 'Diturunkan 23 tahun, di Makkah dan Madinah, kondisi minoritas vs pemimpin negara — tapi nol kontradiksi. Allah nantang di QS. An-Nisa': 82 — cari kontradiksi kalau bisa.',
  ),
  QuizQuestion(
    question: 'Menurut modul ini, yang membedakan Al-Quran dari kitab lain adalah...',
    options: [
      'Al-Quran adalah satu-satunya kitab suci yang bisa dibaca dalam terjemahan',
      'Al-Quran punya 8+ bukti yang saling menguatkan dari berbagai sisi',
      'Al-Quran adalah kitab paling tebal di antara semua kitab suci',
      'Al-Quran adalah satu-satunya kitab yang diturunkan di malam hari',
    ],
    correctIndex: 1,
    explanation: 'Delapan bukti dari sisi berbeda — bahasa, sejarah, sains, angka, preservasi, nubuatan, dampak manusia — semuanya mengarah ke kesimpulan yang sama. Masing-masing mungkin bisa dijawab, tapi bersama-sama jadi sangat kuat.',
  ),
];

const _rukun2_1Quiz = <QuizQuestion>[
  QuizQuestion(
    question: '"Rukun Islam" artinya apa?',
    options: [
      'Lima amalan sunnah yang dianjurkan buat Muslim yang taat',
      'Lima tiang penopang yang jadi fondasi hidup seorang Muslim',
      'Lima aturan yang boleh dipilih sesuai kemampuan masing-masing',
      'Lima tingkatan spiritual yang dicapai berurutan seumur hidup',
    ],
    correctIndex: 1,
    explanation: 'Rukun artinya tiang penopang. Kelimanya wajib dan saling ngisi — gak bisa pilih-pilih.',
  ),
  QuizQuestion(
    question: 'Apa fungsi Sholat dalam kehidupan seorang Muslim?',
    options: [
      'Cara ngobrol langsung sama Allah — appointment tetap 5 kali sehari',
      'Ritual penghapus dosa yang dilakukan saat merasa bersalah aja',
      'Peregangan badan yang menyehatkan di lima waktu yang berbeda',
      'Kewajiban sosial biar dianggap Muslim yang baik oleh tetangga',
    ],
    correctIndex: 0,
    explanation: 'Sholat itu "appointment" tetap kamu sama Tuhan — 5 kali sehari, gak bisa di-delegate atau di-skip.',
  ),
  QuizQuestion(
    question: 'Zakat itu beda dari pajak karena...',
    options: [
      'Zakat jumlahnya jauh lebih besar daripada pajak pemerintah',
      'Zakat cuma dibayarkan setahun sekali pas bulan Ramadan aja',
      'Zakat dikelola langsung oleh masjid tanpa ada aturan tertentu',
      'Zakat itu pembersihan harta — ada hak orang lain di hartamu',
    ],
    correctIndex: 3,
    explanation: 'Zakat bukan pajak — ini pembersihan harta. Konsepnya: hartamu gak 100% milikmu, ada hak orang lain di situ.',
  ),
  QuizQuestion(
    question: 'Puasa Ramadan itu tujuannya bukan cuma tahan lapar, tapi juga...',
    options: [
      'Menghemat pengeluaran makan selama satu bulan penuh',
      'Membuktikan kekuatan fisik seorang Muslim ke sesamanya',
      'Melatih disiplin, empati, dan mendekatkan diri sama Allah',
      'Menjalankan tradisi turun-temurun dari para leluhur kita',
    ],
    correctIndex: 2,
    explanation: 'Puasa melatih disiplin dan empati. Bukan cuma tahan makan — tapi juga tahan emosi, gossip, dan hal negatif.',
  ),
  QuizQuestion(
    question: 'Kapan wajib Haji?',
    options: [
      'Sekali seumur hidup, kalau mampu secara fisik dan finansial',
      'Setiap lima tahun sekali buat yang punya penghasilan tetap',
      'Sekali seumur hidup buat semua Muslim tanpa ada terkecuali',
      'Setiap tahun buat yang tinggal dekat dengan kota Makkah',
    ],
    correctIndex: 0,
    explanation: 'Haji wajib sekali seumur hidup kalau mampu. Di sana, jutaan orang dari seluruh dunia berkumpul — gak ada bedanya kaya-miskin.',
  ),
];

const _rukun2_2Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Apa arti "Laa ilaaha illallah"?',
    options: [
      'Allah itu ada dan Dia yang menciptakan seluruh alam semesta',
      'Tidak ada satu pun yang bisa menandingi kekuasaan Allah',
      'Allah Maha Besar melebihi segala sesuatu yang pernah ada',
      'Tidak ada Tuhan yang layak disembah selain Allah',
    ],
    correctIndex: 3,
    explanation: 'Bukan cuma bilang \'Tuhan ada\' — tapi juga \'Dia aja yang layak aku sembah dan taati.\' Ini soal prioritas hidup.',
  ),
  QuizQuestion(
    question: 'Apa konsekuensi mengucapkan "Muhammadur Rasulullah"?',
    options: [
      'Wajib menghafal seluruh hadits yang diriwayatkan darinya',
      'Percaya dia utusan Allah DAN berkomitmen ikutin ajarannya',
      'Cukup mengenang jasa-jasanya setiap peringatan Maulid Nabi',
      'Menjadikan dia sebagai perantara semua doa kita ke Allah',
    ],
    correctIndex: 1,
    explanation: 'Kalau beneran percaya dia utusan Tuhan, maka logisnya: ikutin ajarannya. Kayak percaya sama mentor — pasti ikutin saran dia.',
  ),
  QuizQuestion(
    question: '"Laa ilaaha illallah" dalam kehidupan sehari-hari artinya...',
    options: [
      'Yang nomor satu dalam hidup adalah Allah, bukan duit atau jabatan',
      'Mengucapkan kalimat tersebut minimal seratus kali setiap harinya',
      'Menolak semua urusan dunia dan fokus pada ibadah ritual aja',
      'Menjauhi semua orang yang berbeda keyakinan dengan kita',
    ],
    correctIndex: 0,
    explanation: 'Laa ilaaha illallah = prioritas hidup. Gak boleh takut/bergantung sama selain Allah lebih dari-Nya.',
  ),
  QuizQuestion(
    question: 'Kenapa Syahadat jadi rukun PERTAMA?',
    options: [
      'Karena paling singkat dan paling mudah buat diamalkan',
      'Karena diucapkan Nabi ﷺ pertama kali saat menerima wahyu',
      'Karena tanpa syahadat, empat rukun lainnya gak punya dasar',
      'Karena urutan rukun disusun dari yang paling ringan dulu',
    ],
    correctIndex: 2,
    explanation: 'Sholat tanpa percaya Allah = gerakan kosong. Zakat tanpa komitmen = buang duit. Syahadat adalah fondasi yang bikin semua ibadah punya makna.',
  ),
  QuizQuestion(
    question: 'Syahadat itu akhir dari perjalanan spiritual?',
    options: [
      'Iya — begitu diucapkan, kewajiban utama seorang Muslim selesai',
      'Engga — itu titik awal, perjalanannya justru baru aja dimulai',
      'Iya, sisanya cuma pelengkap yang sifatnya gak terlalu penting',
      'Tergantung seberapa dalam pemahaman orang yang mengucapkannya',
    ],
    correctIndex: 1,
    explanation: 'Syahadat bukan finish line — itu starting line. Komitmen seumur hidup yang baru aja dimulai.',
  ),
];

const _rukun2_3Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Inti puasa Ramadan itu bukan cuma tahan lapar, tapi...',
    options: [
      'Latihan ngendaliin diri — emosi, nafsu, dan keinginan',
      'Membersihkan racun di dalam tubuh selama satu bulan penuh',
      'Menabung uang belanja makan buat persiapan hari Lebaran',
      'Membuktikan ketaatan kita ke keluarga dan tetangga sekitar',
    ],
    correctIndex: 0,
    explanation: 'Puasa itu gym-nya jiwa. Kalau kamu bisa ngendaliin keinginan paling dasar (makan), kamu juga bisa ngendaliin yang lebih kompleks.',
  ),
  QuizQuestion(
    question: 'Apa hubungan puasa dengan empati?',
    options: [
      'Puasa bikin kita lebih sering berbagi makanan sisa buka puasa',
      'Empati muncul karena kita berbuka bersama keluarga tiap hari',
      'Ngerasain lapar beneran bikin paham kondisi orang gak mampu',
      'Puasa melatih kesabaran menghadapi orang yang menyebalkan',
    ],
    correctIndex: 2,
    explanation: 'Dengan ngerasain lapar beneran, kamu jadi lebih paham kondisi orang yang gak mampu makan setiap hari.',
  ),
  QuizQuestion(
    question: 'Kalau lagi sakit, wajib gak puasa Ramadan?',
    options: [
      'Tetap wajib puasa penuh, sakit bukan alasan buat bolong',
      'Gak wajib dan gak perlu diganti karena udah ada uzurnya',
      'Wajib puasa setengah hari sesuai kemampuan fisik masing-masing',
      'Boleh gak puasa, tapi wajib qadha (ganti) setelah sembuh',
    ],
    correctIndex: 3,
    explanation: 'Islam fleksibel. Sakit = boleh gak puasa. Tapi begitu sembuh, wajib ganti di hari lain.',
  ),
  QuizQuestion(
    question: 'Lansia yang gak mampu puasa permanen, solusinya apa?',
    options: [
      'Puasanya diwakilkan oleh anak atau cucu yang masih kuat',
      'Gak wajib puasa, cukup bayar fidyah (memberi makan orang miskin)',
      'Puasa setengah hari aja dari subuh sampai waktu dzuhur',
      'Mengganti puasanya dengan memperbanyak dzikir dan doa',
    ],
    correctIndex: 1,
    explanation: 'Lansia/gak mampu permanen = gak wajib puasa, cukup fidyah. Islam gak memaksakan di luar batas kemampuan.',
  ),
  QuizQuestion(
    question: 'Puasa Ramadan itu hukuman atau pelatihan?',
    options: [
      'Hukuman — penebus dosa-dosa yang dilakukan setahun penuh',
      'Dua-duanya, tergantung banyaknya dosa orang yang menjalani',
      'Pelatihan — melatih disiplin, empati, dan ketergantungan pada Allah',
      'Ujian fisik tahunan buat mengukur kekuatan iman seseorang',
    ],
    correctIndex: 2,
    explanation: 'Puasa itu pelatihan, bukan hukuman. Satu bulan yang bikin 11 bulan sisanya lebih bermakna.',
  ),
];

const _rukun2_4Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Apa arti kata "zakat"?',
    options: [
      'Pemberian sukarela',
      'Kewajiban harta',
      'Bersih dan tumbuh',
      'Berbagi rezeki',
    ],
    correctIndex: 2,
    explanation: 'Zakat artinya \'bersih\' dan \'tumbuh.\' Konsepnya: bersihin hartamu dari hak orang lain, dan hartamu jadi lebih berkah.',
  ),
  QuizQuestion(
    question: 'Apa beda zakat, infaq, dan sedekah?',
    options: [
      'Zakat buat masjid, infaq buat fakir miskin, sedekah bebas ke siapa aja',
      'Zakat wajib dengan aturan (2.5%, nisab, haul); infaq dan sedekah sunnah',
      'Zakat pakai uang, infaq pakai barang, sedekah pakai tenaga atau jasa',
      'Ketiganya sama-sama wajib, bedanya cuma di waktu pembayarannya',
    ],
    correctIndex: 1,
    explanation: 'Zakat = wajib dengan aturan ketat (2.5%, nisab, haul). Infaq = sunnah, berbagi harta. Sedekah = sunnah, lebih luas — bahkan senyum aja udah sedekah.',
  ),
  QuizQuestion(
    question: 'Kenapa zakat bisa kurangi kesenjangan sosial?',
    options: [
      'Yang punya lebih ngasih 2.5% ke yang butuh — kekayaan terdistribusi',
      'Karena zakat memaksa orang kaya hidup sederhana seperti lainnya',
      'Karena semua hasil zakat dipakai buat membangun fasilitas umum',
      'Karena penerima zakat wajib memakai uangnya buat modal usaha',
    ],
    correctIndex: 0,
    explanation: 'Zakat = sistem distribusi kekayaan dari Allah. Yang mampu → ngasih 2.5% → yang butuh terbantu. Kalau semua patuh, kesenjangan berkurang signifikan.',
  ),
  QuizQuestion(
    question: 'Motivasi zakat yang benar itu apa?',
    options: [
      'Takut hartanya jadi gak berkah kalau gak segera dikeluarkan',
      'Mengharap pujian dan penghormatan dari masyarakat sekitar',
      'Menggugurkan kewajiban biar gak ditagih pengurus masjid',
      'Cinta — percaya itu hak mereka, dan mau hartamu bersih dan berkah',
    ],
    correctIndex: 3,
    explanation: 'Zakat motivasinya cinta, bukan paksaan. Kamu ngasih karena percaya itu hak mereka dan karena kamu sayang hartamu sendiri — mau yang bersih dan berkah.',
  ),
  QuizQuestion(
    question: 'Sedekah itu cuma soal uang?',
    options: [
      'Engga — senyum, nolong orang, bahkan buang duri dari jalan pun sedekah',
      'Iya, harus berupa uang tunai biar jelas nilai dan manfaatnya',
      'Uang atau barang berharga, yang penting bisa dihitung nilainya',
      'Iya, tapi khusus buat keluarga boleh diganti bantuan tenaga',
    ],
    correctIndex: 0,
    explanation: 'Sedekah itu lebih luas dari uang. Senyum, nolong orang, ngasih ilmu, bahkan buang duri dari jalan — semua itu sedekah.',
  ),
];

const _rukun2_5Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Kapan wajib haji?',
    options: [
      'Setiap tahun sekali buat semua Muslim yang badannya sehat',
      'Sekali seumur hidup, kalau mampu secara fisik dan finansial',
      'Dua kali seumur hidup: sewaktu muda dan setelah pensiun',
      'Kapan aja asal udah punya tabungan, tanpa syarat lainnya',
    ],
    correctIndex: 1,
    explanation: 'Haji wajib sekali seumur hidup TAPI cuma kalau mampu. Kalau belum mampu, gak dosa.',
  ),
  QuizQuestion(
    question: 'Kenapa semua jamaah haji pakai baju putih yang sama (ihram)?',
    options: [
      'Karena warna putih paling tahan panas di cuaca gurun Arab',
      'Biar petugas gampang membedakan jamaah dari penduduk lokal',
      'Mengikuti tradisi pakaian bangsa Arab sejak sebelum masa Islam',
      'Simbol kesetaraan — di depan Allah semua sama, gak ada beda harta',
    ],
    correctIndex: 3,
    explanation: 'Ihram = baju putih tanpa merek. Presiden, buruh, pengusaha — semua sama. Yang membedakan di mata Allah bukan harta, tapi ketakwaan.',
  ),
  QuizQuestion(
    question: 'Apa makna tawaf (keliling Ka\'bah 7x)?',
    options: [
      'Menghormati Ka\'bah sebagai bangunan paling tua di muka bumi',
      'Mengenang perjalanan hijrah Nabi ﷺ dari Makkah ke Madinah',
      'Hidup harus berpusat pada Allah, seperti planet yang mengorbit',
      'Melatih fisik jamaah sebelum rangkaian ibadah yang lebih berat',
    ],
    correctIndex: 2,
    explanation: 'Tawaf = simbol hidup berpusat pada Allah. Seperti planet yang mengorbit — hidupmu harus berputar di sekitar-Nya.',
  ),
  QuizQuestion(
    question: 'Kalau belum mampu haji secara finansial, apa yang terjadi?',
    options: [
      'Gak wajib — Allah gak membebankan di luar batas kemampuan',
      'Tetap wajib berangkat dengan cara mencicil atau meminjam',
      'Berdosa kecil yang bisa dihapus dengan memperbanyak sedekah',
      'Kewajibannya pindah ke anak yang wajib menghajikan orang tuanya',
    ],
    correctIndex: 0,
    explanation: 'Haji cuma wajib kalau mampu. Kalau belum mampu, gak dosa. Keluarga di rumah harus tetap tercukupi dulu.',
  ),
  QuizQuestion(
    question: 'Apa makna melempar jumrah saat haji?',
    options: [
      'Mengusir gangguan jin yang berkumpul di lembah kota Mina',
      'Melambangkan perang melawan musuh-musuh Islam zaman dulu',
      'Membuang sial dan penyakit supaya gak terbawa pulang ke rumah',
      'Simbol nolak godaan setan — dari yang kecil sampai yang besar',
    ],
    correctIndex: 3,
    explanation: 'Melempar jumrah = simbol nolak godaan setan. Dari jumrah kecil, sedang, sampai besar — makin lama makin tegas nolaknya.',
  ),
];

const _praktik3_1Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Berapa kali membasuh telapak tangan saat wudhu?',
    options: [
      '1 kali',
      '2 kali',
      '3 kali',
      '5 kali',
    ],
    correctIndex: 2,
    explanation: 'Setiap basuhan dalam wudhu dilakukan 3 kali. Ini sunnah yang dianjurkan.',
  ),
  QuizQuestion(
    question: 'Urutan wudhu yang benar setelah membasuh tangan adalah...',
    options: [
      'Kumur → hidung → wajah → tangan-siku → kepala → telinga → kaki',
      'Wajah → kumur → hidung → kepala → tangan-siku → telinga → kaki',
      'Kumur → wajah → hidung → telinga → kepala → tangan-siku → kaki',
      'Hidung → kumur → tangan-siku → wajah → kaki → kepala → telinga',
    ],
    correctIndex: 0,
    explanation: 'Urutan wudhu harus berurutan: kumur → hidung → wajah → tangan-siku → usap kepala → telinga → kaki. Bayangin nyiram dari atas ke bawah.',
  ),
  QuizQuestion(
    question: 'Usap kepala dilakukan berapa kali?',
    options: [
      '3 kali, sama seperti basuhan anggota wudhu yang lainnya',
      '1 kali aja — dari depan ke belakang, balik lagi ke depan',
      '2 kali dengan air yang diganti di tiap-tiap usapannya',
      '7 kali sambil membaca niat wudhu di dalam hati',
    ],
    correctIndex: 1,
    explanation: 'Usap kepala cukup 1 kali — dari depan ke belakang, balik lagi ke depan. Berbeda dari basuhan lain yang 3 kali.',
  ),
  QuizQuestion(
    question: 'Apa yang batalin wudhu?',
    options: [
      'Berbicara dengan orang lain sebelum sholatnya dimulai',
      'Makan dan minum sesudah selesai berwudhu',
      'Terkena debu atau kotoran saat perjalanan ke masjid',
      'Keluar sesuatu dari qubul/dubur, tidur nyenyak, hilang akal',
    ],
    correctIndex: 3,
    explanation: 'Wudhu batal kalau: kencing/buang air/kentut, tidur nyenyak, pingsan/mabuk, atau menyentuh kemaluan tanpa alas.',
  ),
  QuizQuestion(
    question: 'Kalau wudhu udah tapi belum batal, bisa dipake buat sholat berikutnya?',
    options: [
      'Engga, satu wudhu cuma berlaku buat satu kali sholat wajib',
      'Bisa — selama belum batal, wudhunya tetap sah dipakai lagi',
      'Bisa, tapi khusus buat sholat sunnah aja, bukan yang wajib',
      'Engga, kecuali jarak antar sholatnya kurang dari satu jam',
    ],
    correctIndex: 1,
    explanation: 'Wudhu tetap sah selama belum batal. Jadi kalau udah wudhu Subuh dan belum batal, bisa dipake buat Dzuhur juga.',
  ),
];

const _praktik3_2Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Apa bedanya syarat sah dan rukun sholat?',
    options: [
      'Syarat sah cuma berlaku buat imam, rukun buat semua makmum',
      'Syarat sah dipenuhi SEBELUM sholat, rukun dilakukan DI DALAM sholat',
      'Rukun boleh ditinggal kalau lupa, syarat sah gak boleh sama sekali',
      'Syarat sah buat sholat wajib, rukun buat sholat sunnah aja',
    ],
    correctIndex: 1,
    explanation: 'Syarat sah = hal di luar sholat (suci, tutup aurat, hadap kiblat, masuk waktu). Rukun = hal di dalam sholat (niat, takbir, ruku, sujud, dll).',
  ),
  QuizQuestion(
    question: 'Aurat laki-laki saat sholat itu...',
    options: [
      'Seluruh tubuh kecuali muka dan kedua telapak tangannya',
      'Dari bahu sampai ke bawah lutut termasuk kedua lengan',
      'Dari pusar sampai lutut',
      'Bebas asal pakaiannya rapi, bersih, dan gak tembus pandang',
    ],
    correctIndex: 2,
    explanation: 'Laki-laki: pusar sampai lutut harus tertutup. Perempuan: seluruh tubuh kecuali muka dan telapak tangan.',
  ),
  QuizQuestion(
    question: 'Berapa kali sujud dalam satu rakaat?',
    options: [
      '2 kali',
      '1 kali',
      '3 kali',
      '4 kali',
    ],
    correctIndex: 0,
    explanation: 'Setiap rakaat punya 2 sujud. Jadi sholat 2 rakaat = 4 sujud, sholat 4 rakaat = 8 sujud.',
  ),
  QuizQuestion(
    question: 'Apa yang menandai sholat DIMULAI?',
    options: [
      'Berdiri tegak dengan menghadap ke arah kiblat',
      'Membaca niat sholat di dalam hati dengan khusyuk',
      'Membaca Surat Al-Fatihah dari ayat yang pertama',
      'Takbiratul ihram — "Allahu Akbar" sambil angkat tangan',
    ],
    correctIndex: 3,
    explanation: 'Takbiratul ihram = \'Allahu Akbar\' pertama sambil angkat tangan. Ini tanda resmi sholat dimulai.',
  ),
  QuizQuestion(
    question: 'Sholat di luar waktu yang ditentukan, sah gak?',
    options: [
      'Sah, karena yang paling penting adalah niat di dalam hati',
      'Sah selama telatnya belum melewati waktu sholat berikutnya',
      'Gak sah — masuk waktu adalah salah satu syarat sah sholat',
      'Sah kalau dikerjakan berjamaah bersama imam di masjid',
    ],
    correctIndex: 2,
    explanation: 'Masuk waktu adalah syarat sah. Sholat di luar waktu = gak sah, harus diulang di waktu yang benar.',
  ),
];

const _praktik3_3Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Berapa rakaat sholat Subuh?',
    options: [
      '2 rakaat',
      '3 rakaat',
      '4 rakaat',
      '5 rakaat',
    ],
    correctIndex: 0,
    explanation: 'Subuh = 2 rakaat. Maghrib = 3. Dzuhur, Ashar, Isya = 4. Mulai dari Subuh dulu kalau masih belajar.',
  ),
  QuizQuestion(
    question: 'Setelah Al-Fatihah di rakaat 1, apa yang dibaca?',
    options: [
      'Doa iftitah sebagai pembuka bacaan rakaat pertama',
      'Langsung ruku sambil membaca kalimat Allahu Akbar',
      'Dua kalimat syahadat sebelum gerakan berikutnya',
      'Surah pendek — pemula disarankan baca Al-Ikhlas',
    ],
    correctIndex: 3,
    explanation: 'Setelah Al-Fatihah, baca surah pendek. Disarankan Al-Ikhlas untuk pemula — pendek dan gampang dihafal.',
  ),
  QuizQuestion(
    question: 'Posisi ruku yang benar itu...',
    options: [
      'Bungkuk dalam sampai dahi hampir menyentuh kedua lutut',
      'Tangan pegang lutut, punggung lurus, pandangan ke kaki',
      'Bungkuk sedikit dengan kedua tangan lurus ke bawah',
      'Tangan memegang paha, badan tegak menghadap kiblat',
    ],
    correctIndex: 1,
    explanation: 'Ruku: bungkuk, tangan pegang lutut, punggung lurus. Pandangan ke kaki, bukan ke depan.',
  ),
  QuizQuestion(
    question: 'Di rakaat 3 dan 4, apa yang dibaca?',
    options: [
      'Al-Fatihah ditambah surah pendek seperti rakaat sebelumnya',
      'Surah pendek aja tanpa Al-Fatihah biar lebih cepat selesai',
      'Cuma Al-Fatihah aja, tanpa tambahan surah pendek',
      'Bacaan tasyahud awal sebelum berdiri tegak sempurna',
    ],
    correctIndex: 2,
    explanation: 'Di rakaat 3 dan 4, cuma baca Al-Fatihah. Gak usah tambah surah pendek.',
  ),
  QuizQuestion(
    question: 'Salam ke kanan dan ke kiri artinya sholat...',
    options: [
      'Berpindah dari rakaat genap menuju rakaat yang ganjil',
      'Memasuki bagian doa-doa tambahan sebelum berdzikir',
      'Sedang memberi hormat kepada imam dan para makmum',
      'SELESAI — ini tanda resmi berakhirnya sholat',
    ],
    correctIndex: 3,
    explanation: 'Salam = tanda sholat selesai. Putar ke kanan \'Assalamu\'alaikum warahmatullah\', lalu ke kiri.',
  ),
];

const _praktik3_4Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Kapan membaca Al-Fatihah dalam sholat?',
    options: [
      'Cukup di rakaat pertama karena rakaat lain mengikutinya',
      'Di rakaat pertama dan terakhir, sebagai pembuka dan penutup',
      'Boleh dilewati kalau imam sudah membacanya dengan keras',
      'Di setiap rakaat — wajib, tanpa Al-Fatihah rakaatnya gak sah',
    ],
    correctIndex: 3,
    explanation: 'Al-Fatihah wajib dibaca di SETIAP rakaat, baik imam maupun sendirian. Tanpa Al-Fatihah, rakaatnya gak sah.',
  ),
  QuizQuestion(
    question: 'Bacaan ruku dan sujud itu...',
    options: [
      'Sama persis, dua-duanya membaca Subhana rabbiyal adzimi',
      'Beda: ruku "rabbiyal \'adzimi", sujud "rabbiyal a\'la"',
      'Bebas memilih dzikir apa pun asal diucapkan tiga kali',
      'Cukup membaca Allahu Akbar berulang sebanyak tiga kali',
    ],
    correctIndex: 1,
    explanation: 'Ruku = Subhana rabbiyal \'adzimi wa bihamdih (Maha Suci Tuhanku Yang Maha Agung). Sujud = Subhana rabbiyal a\'la wa bihamdih (Maha Suci Tuhanku Yang Maha Tinggi).',
  ),
  QuizQuestion(
    question: 'Tasyahud akhir ditambah apa dari tasyahud awal?',
    options: [
      'Ditambah bacaan Al-Fatihah sebagai penutup rangkaian sholat',
      'Ditambah doa iftitah yang dibaca di awal sholat tadi',
      'Ditambah sholawat Ibrahimiyah untuk Nabi Muhammad ﷺ',
      'Gak ada bedanya, cuma posisi duduknya aja yang berubah',
    ],
    correctIndex: 2,
    explanation: 'Tasyahud akhir = tasyahud awal + sholawat Ibrahimiyah. Sholawat wajib dibaca di tasyahud akhir.',
  ),
  QuizQuestion(
    question: 'Bacaan duduk antara dua sujud itu meminta apa?',
    options: [
      'Ampunan, rahmat, kecukupan, derajat, maaf, dan rezeki',
      'Perlindungan dari siksa kubur dan fitnah di akhir zaman',
      'Keselamatan dunia akhirat buat orang tua dan keluarga',
      'Petunjuk jalan yang lurus seperti di Surat Al-Fatihah',
    ],
    correctIndex: 0,
    explanation: 'Allahummaghfirli (ampun), warhamni (rahmat), wajburni (cukup), warfa\'ni (angkat derajat), wa\'fu \'anni (maaf), warzuqni (rezeki).',
  ),
  QuizQuestion(
    question: 'Modul ini (cheat-sheet) berguna buat apa?',
    options: [
      'Bahan wajib yang harus dihafal seluruhnya dalam satu hari',
      'Referensi cepat — semua bacaan sholat ada di satu tempat',
      'Pengganti praktik sholat kalau lagi gak sempat mengerjakan',
      'Materi khusus buat yang mau jadi imam sholat berjamaah',
    ],
    correctIndex: 1,
    explanation: 'Cheat-sheet = referensi cepat. Bookmark modul ini, kamu bakal sering balik ke sini saat belajar sholat.',
  ),
];

const _praktik3_5Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Berapa rakaat sholat Subuh?',
    options: [
      '4',
      '3',
      '2',
      '5',
    ],
    correctIndex: 2,
    explanation: 'Subuh = 2 rakaat. Sholat wajib paling sedikit rakaatnya.',
  ),
  QuizQuestion(
    question: 'Sholat wajib yang 3 rakaat itu...',
    options: [
      'Maghrib',
      'Subuh',
      'Isya',
      'Dzuhur',
    ],
    correctIndex: 0,
    explanation: 'Maghrib = 3 rakaat. Satu-satunya sholat wajib yang 3 rakaat. Subuh 2, yang lain 4.',
  ),
  QuizQuestion(
    question: 'Total rakaat sholat wajib dalam satu hari ada berapa?',
    options: [
      '20',
      '15',
      '19',
      '17',
    ],
    correctIndex: 3,
    explanation: '2 + 4 + 4 + 3 + 4 = 17 rakaat. Dibagi sepanjang hari, gak banyak kok.',
  ),
  QuizQuestion(
    question: 'Waktu Ashar itu mulai kapan?',
    options: [
      'Ketika matahari tepat berada di atas kepala kita',
      'Ketika bayangan benda sama panjang dengan bendanya',
      'Ketika langit mulai berwarna kemerahan di ufuk barat',
      'Ketika bayangan benda dua kali panjang bendanya',
    ],
    correctIndex: 1,
    explanation: 'Ashar masuk ketika bayangan benda sama panjangnya dengan benda itu sendiri (sekitar jam 15:00).',
  ),
  QuizQuestion(
    question: 'Kenapa Subuh cuma 2 rakaat?',
    options: [
      'Karena waktunya pendek — dari fajar sampai terbit matahari',
      'Karena Allah kasih keringanan buat orang yang baru bangun',
      'Karena dulu Nabi ﷺ mengqashar sholat Subuh saat perjalanan',
      'Karena rakaatnya digenapi oleh sholat sunnah qabliyah',
    ],
    correctIndex: 0,
    explanation: 'Subuh cuma 2 rakaat karena waktunya pendek. Jumlah rakaat ditentukan Nabi ﷺ berdasarkan wahyu.',
  ),
];

const _praktik3_6Quiz = <QuizQuestion>[
  QuizQuestion(
    question: 'Kalau lupa udah rakaat keberapa, solusinya...',
    options: [
      'Batalkan sholatnya dan mulai lagi dari takbiratul ihram',
      'Ambil yang lebih sedikit, tambah sujud sahwi setelah salam',
      'Ambil yang lebih banyak biar rakaatnya gak sampai kurang',
      'Ikuti perkiraan yang paling kuat lalu langsung salam aja',
    ],
    correctIndex: 1,
    explanation: 'Ambil yang lebih sedikit, tambah sujud sahwi setelah salam. Lupa itu manusiawi — gak usah panik.',
  ),
  QuizQuestion(
    question: 'Gak hafal surah pendek selain Al-Fatihah, gimana?',
    options: [
      'Tunda dulu sholatnya sampai hafal minimal tiga surah pendek',
      'Baca terjemahan Indonesianya sebagai pengganti surah pendek',
      'Gak masalah — Al-Fatihah aja udah cukup, sisanya nyusul',
      'Ulangi bacaan Al-Fatihah dua kali di setiap rakaatnya',
    ],
    correctIndex: 2,
    explanation: 'Al-Fatihah itu yang wajib. Surah pendek itu tambahan — boleh surah apa saja yang dihafal. Fokus hafalin Al-Fatihah dulu.',
  ),
  QuizQuestion(
    question: 'Sholat qashar artinya...',
    options: [
      'Meringkas sholat 4 rakaat jadi 2, khusus buat musafir',
      'Mempercepat gerakan sholat karena waktu yang mendesak',
      'Menggabungkan dua sholat wajib di satu waktu perjalanan',
      'Mengganti sholat yang terlewat di waktu sholat berikutnya',
    ],
    correctIndex: 0,
    explanation: 'Qashar = meringkas 4 rakaat jadi 2. Khusus untuk musafir (perjalanan jauh). Islam gak memberatkan.',
  ),
  QuizQuestion(
    question: 'Bolehkah bacaan rukun sholat pakai bahasa Indonesia?',
    options: [
      'Boleh, karena Allah memahami semua bahasa hamba-Nya',
      'Boleh khusus pemula, sampai dia hafal bacaan Arabnya',
      'Tergantung kebiasaan masjid dan imam di tiap daerah',
      'Tidak — rukun harus Arab; doa tambahan bebas bahasanya',
    ],
    correctIndex: 3,
    explanation: 'Rukun = Arab (wajib, karena Al-Quran dalam bahasa Arab dan sholat distandarkan Nabi). Doa tambahan = bebas bahasa apa aja.',
  ),
  QuizQuestion(
    question: 'Sholat belum perfect, tapi udah berusaha — sah gak?',
    options: [
      'Belum sah sampai semua bacaan fasih dan gerakannya tepat',
      'Sah cuma kalau dikerjakan berjamaah di belakang imam',
      'Sah — asal syarat sah terpenuhi dan rukunnya lengkap',
      'Sahnya setengah, jadi pahalanya juga dapat setengahnya',
    ],
    correctIndex: 2,
    explanation: 'Sholat yang gak perfect > gak sholat sama sekali. Allah tahu kamu lagi belajar. Yang penting JANGAN BERHENTI.',
  ),
];


// ─── Learning service (persistence + XP claim) ───

class LearningService {
  static const _key = 'learning_state_v1';
  static LearningState _cache = LearningState();
  static LearningState get current => _cache;

  static Future<LearningState> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw != null) {
      try {
        _cache = LearningState.fromMap(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    return _cache;
  }

  static Future<void> _save(LearningState s) async {
    _cache = s;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(s.toMap()));
    SupabaseSync.saveLearning(s.toMap()); // fire-and-forget
  }

  static ModuleProgress? getProgress(String moduleId) {
    for (final p in _cache.progress) {
      if (p.moduleId == moduleId) return p;
    }
    return null;
  }

  static bool isCompleted(String moduleId) =>
      getProgress(moduleId)?.completed ?? false;

  static bool isXpClaimed(String moduleId) =>
      getProgress(moduleId)?.xpClaimed ?? false;

  static bool isUnlocked(String moduleId) =>
      LearningContent.isModuleUnlocked(moduleId, _cache.progress);

  /// Batas lulus quiz — dipakai juga BelajarResultScreen (_passed).
  static const passScore = 70;

  static Future<LearningState> completeModule(String moduleId, int quizScore) async {
    final existing = getProgress(moduleId);
    final updated = ModuleProgress(
      moduleId: moduleId,
      // Gagal quiz tidak menandai modul selesai (modul berikutnya tetap
      // terkunci); status selesai yang sudah diraih tidak dicabut.
      completed: quizScore >= passScore || (existing?.completed ?? false),
      quizScore: quizScore > (existing?.quizScore ?? 0) ? quizScore : (existing?.quizScore ?? 0),
      xpClaimed: existing?.xpClaimed ?? false,
    );
    final progress = existing == null
        ? [..._cache.progress, updated]
        : _cache.progress.map((p) => p.moduleId == moduleId ? updated : p).toList();
    final newState = _cache.copyWith(progress: progress);
    await _save(newState);
    return newState;
  }

  static Future<LearningState> claimXp(String moduleId) async {
    final existing = getProgress(moduleId);
    if (existing == null || !existing.completed || existing.xpClaimed) return _cache;
    final updated = existing.copyWith(xpClaimed: true);
    final progress = _cache.progress.map((p) => p.moduleId == moduleId ? updated : p).toList();
    final newState = _cache.copyWith(progress: progress);
    await _save(newState);
    return newState;
  }

  static int get totalXpClaimed {
    var total = 0;
    for (final p in _cache.progress) {
      if (p.xpClaimed) {
        final mod = LearningContent.getAllModulesOrdered()
            .where((m) => m.id == p.moduleId).firstOrNull;
        if (mod != null) total += mod.xpReward;
      }
    }
    return total;
  }

  static int get completedCount =>
      _cache.progress.where((p) => p.completed).length;

  static int get totalModules => LearningContent.getAllModulesOrdered().length;
}
