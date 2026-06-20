package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.*
import com.example.ui.theme.*
import com.example.viewmodel.GameViewModel

// ═══════════════════════════════════════════════════════════════
// MODULE CONTENT REGISTRY — Add new modules here (prompt 2-9+)
// ═══════════════════════════════════════════════════════════════

object LearningContent {

    val categories: List<LearningCategory> = listOf(
        LearningCategory(
            id = "akidah",
            label = "Akidah",
            icon = "🕋",
            modules = listOf(
                LearningModule(
                    id = "akidah_1.1",
                    categoryId = "akidah",
                    title = "Kenapa Harus Percaya Ada Tuhan?",
                    icon = "🌌",
                    estimatedMinutes = 4,
                    xpReward = 50
                ),
                LearningModule(
                    id = "akidah_1.2",
                    categoryId = "akidah",
                    title = "Kenapa Allah Itu Esa (Tauhid)?",
                    icon = "☝️",
                    estimatedMinutes = 5,
                    xpReward = 60
                ),
                LearningModule(
                    id = "akidah_1.3",
                    categoryId = "akidah",
                    title = "Al-Quran: Firman Tuhan, Bukan Karangan Manusia",
                    icon = "📖",
                    estimatedMinutes = 6,
                    xpReward = 70
                )
                // Future: akidah_1.4, akidah_1.5, ...
            )
        ),
        LearningCategory(
            id = "rukun_islam",
            label = "Rukun Islam",
            icon = "🕌",
            modules = listOf(
                LearningModule(
                    id = "rukun_1.1",
                    categoryId = "rukun_islam",
                    title = "Rukun Islam: Apa Aja Sih?",
                    icon = "⭐",
                    estimatedMinutes = 5,
                    xpReward = 60
                )
            )
        ),
        LearningCategory(
            id = "praktik_ibadah",
            label = "Praktik Ibadah",
            icon = "🤲",
            modules = listOf(
                LearningModule(
                    id = "praktik_1.1",
                    categoryId = "praktik_ibadah",
                    title = "Cara Sholat: Step by Step",
                    icon = "🧎",
                    estimatedMinutes = 6,
                    xpReward = 70
                )
            )
        )
    )

    // ─── Article Content ───
    fun getArticleContent(moduleId: String): List<ArticleBlock> {
        return when (moduleId) {
            "akidah_1.1" -> akidah1_1Article
            "akidah_1.2" -> akidah1_2Article
            "akidah_1.3" -> akidah1_3Article
            "rukun_1.1" -> rukun1_1Article
            "praktik_1.1" -> praktik1_1Article
            else -> emptyList()
        }
    }

    // ─── Quiz Content ───
    fun getQuizQuestions(moduleId: String): List<QuizQuestion> {
        return when (moduleId) {
            "akidah_1.1" -> akidah1_1Quiz
            "akidah_1.2" -> akidah1_2Quiz
            "akidah_1.3" -> akidah1_3Quiz
            "rukun_1.1" -> rukun1_1Quiz
            "praktik_1.1" -> praktik1_1Quiz
            else -> emptyList()
        }
    }

    // ─── Helper: get ordered module list for unlock logic ───
    fun getAllModulesOrdered(): List<LearningModule> {
        return categories.flatMap { it.modules }
    }

    fun isModuleUnlocked(moduleId: String, progress: List<ModuleProgress>): Boolean {
        val allModules = getAllModulesOrdered()
        val index = allModules.indexOfFirst { it.id == moduleId }
        if (index <= 0) return true // first module always unlocked
        // Previous module must be completed
        val prevModule = allModules[index - 1]
        return progress.any { it.moduleId == prevModule.id && it.completed }
    }

    // ═══════════════════════════════════════════
    // ARTIKEL: AKIDAH 1.1 — Kenapa Harus Percaya Ada Tuhan?
    // ═══════════════════════════════════════════
    private val akidah1_1Article = listOf(
        ArticleBlock.Heading("Kenapa Harus Percaya Ada Tuhan?"),
        ArticleBlock.Paragraph(
            "Oke, sebelum ngomongin sholat, puasa, atau ibadah lainnya — " +
            "kita perlu jawab pertanyaan paling dasar dulu: \"Emangnya Tuhan itu ada?\""
        ),
        ArticleBlock.Paragraph(
            "Ini pertanyaan yang wajar banget. Justru bagus kalau kamu mau mikirin ini, " +
            "karena artinya kamu serius mau cari kebenaran. Yuk kita bahas pakai logika sederhana."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("🔍 Argumen 1: Desain Alam Semesta"),
        ArticleBlock.Paragraph(
            "Coba lihat sekeliling kamu. HP yang kamu pegang sekarang — ada layar, prosesor, " +
            "kamera, baterai. Secanggih itu. Tapi kamu tahu kan pasti ADA yang merancang? " +
            "Gak mungkin komponen-komponen itu tiba-tiba nongol sendiri dari kosong."
        ),
        ArticleBlock.Paragraph(
            "Sekarang bayangin: alam semesta ini JAUH lebih kompleks dari HP. " +
            "Ada triliunan galaksi, masing-masing punya miliaran bintang. " +
            "Gravitasi, kecepatan cahaya, siklus air, fotosintesis — semuanya bekerja " +
            "dengan presisi gila. Kalau HP aja butuh perancang, masa alam semesta " +
            "yang jauh lebih canggih ini kebetulan ada sendiri?"
        ),
        ArticleBlock.Highlight("HP aja butuh yang merancang. Alam semesta? Jauh lebih kompleks."),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("⛓️ Argumen 2: Sebab-Akibat"),
        ArticleBlock.Paragraph(
            "Ini hukum paling basic di dunia: segala sesuatu pasti punya penyebab. " +
            "Meja ada karena ada yang bikin. Pohon tumbuh karena ada biji. " +
            "Kamu ada karena ada orang tua."
        ),
        ArticleBlock.Paragraph(
            "Kalau kita telusuri terus ke belakang — siapa yang bikin X, siapa yang bikin Y — " +
            "pasti harus berhenti di satu titik: sesuatu yang GAK butuh penyebab lain. " +
            "Sesuatu yang udah ada dari awal. Itulah yang kita sebut Tuhan."
        ),
        ArticleBlock.Paragraph(
            "Bayangin kayak rantai: kalau setiap mata rantai bergantung pada rantai sebelumnya, " +
            "siapa yang nge-link pertama? Pasti ada sesuatu yang bukan rantai, tapi jadi " +
            "sumber dari semua rantai itu."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("🎯 Argumen 3: Keteraturan Gak Mungkin Kebetulan"),
        ArticleBlock.Paragraph(
            "Coba lempar koin 100 kali. Berapa kali kamu bisa dapat muka semua? " +
            "Hampir mustahil. Sekarang bayangin: alam semesta ini punya HUKUM yang bekerja " +
            "konsisten selama miliaran tahun. Gravitasi gak pernah libur. " +
            "Atom gak pernah ngawur. Siklus siang-malam gak pernah telat."
        ),
        ArticleBlock.Paragraph(
            "Keteraturan se-ekstrem ini tanpa Perancang? Itu kayak bilang novel " +
            "yang udah jadi muncul dari ledakan di percetakan. Logikanya gak nyambung."
        ),
        ArticleBlock.Highlight(
            "Keteraturan alam = bukti kuat ada Perancang di balik semuanya."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("💡 Jadi...?"),
        ArticleBlock.Paragraph(
            "Percaya pada Tuhan bukan soal \"harus percaya buta\". " +
            "Justru logika dan akal sehat kita ngasih tanda-tanda yang kuat: " +
            "ada Perancang di balik semua ini."
        ),
        ArticleBlock.Paragraph(
            "Dan kalau memang ada yang merancang alam semesta se-kompleks ini, " +
            "pasti dong Dia punya tujuan? Pasti dong Dia ngasih petunjuk? " +
            "Nah, itu yang bakal kita bahas di modul-modul selanjutnya."
        ),
        ArticleBlock.EducatorNote(
            "\"Sesungguhnya dalam penciptaan langit dan bumi, " +
            "dan pergantian malam dan siang terdapat tanda-tanda bagi orang yang berakal.\" " +
            "(QS. Ali Imran: 190)"
        ),
        ArticleBlock.Cta(
            "Kamu udah selesai baca! Sekarang coba jawab kuisnya buat klaim XP. 🎯"
        )
    )

    private val akidah1_1Quiz = listOf(
        QuizQuestion(
            question = "Kenapa HP yang canggih dijadiin contoh di artikel ini?",
            options = listOf(
                "Biar artikelnya kekinian aja",
                "Buat nunjukin kalau bahkan barang sederhana aja butuh perancang, apalagi alam semesta",
                "Karena HP itu penting buat kehidupan",
                "Biar kamu beli HP baru"
            ),
            correctIndex = 1,
            explanation = "Logikanya simpel: kalau HP yang \"cuma\" elektronik aja ada perancangnya, alam semesta yang jauh lebih kompleks pasti juga dong."
        ),
        QuizQuestion(
            question = "Apa itu \"argumen sebab-akibat\"?",
            options = listOf(
                "Semua hal terjadi tanpa sebab",
                "Hanya benda hidup yang punya penyebab",
                "Setiap sesuatu pasti punya penyebab, sampai ke satu penyebab pertama",
                "Tuhan juga butuh penyebab"
            ),
            correctIndex = 2,
            explanation = "Rantai sebab-akibat harus berhenti di satu titik: sesuatu yang gak butuh penyebab lain. Itulah Tuhan."
        ),
        QuizQuestion(
            question = "Kenapa keteraturan alam dijadiin bukti ada Tuhan?",
            options = listOf(
                "Karena alam itu indah",
                "Karena keteraturan se-konsisten itu mustahil terjadi tanpa Perancang",
                "Karena buku bilang begitu",
                "Karena orang tua kita ngajarin begitu"
            ),
            correctIndex = 1,
            explanation = "Hukum alam bekerja konsisten selama miliaran tahun — itu gak mungkin kebetulan. Pasti ada yang ngerancang."
        ),
        QuizQuestion(
            question = "Menurut artikel, percaya pada Tuhan itu...",
            options = listOf(
                "Harus buta, gak boleh pakai logika",
                "Cuma buat orang tua",
                "Justru didukung oleh logika dan akal sehat",
                "Gak penting buat kehidupan"
            ),
            correctIndex = 2,
            explanation = "Percaya pada Tuhan bukan soal buta. Justru logika kita sendiri yang ngasih tanda-tanda kuat kalau ada Perancang."
        ),
        QuizQuestion(
            question = "Setelah percaya ada Tuhan, langkah selanjutnya menurut artikel adalah...",
            options = listOf(
                "Udah selesai, gak perlu ngapa-ngapain lagi",
                "Cari tahu tujuan Dia dan petunjuk yang Dia kasih",
                "Langsung berdoa aja",
                "Lupakan aja, yang penting percaya"
            ),
            correctIndex = 1,
            explanation = "Kalau memang ada Perancang alam semesta, pasti Dia punya tujuan dan petunjuk. Nah itu yang bakal kita pelajari bareng!"
        )
    )

    // ═══════════════════════════════════════════
    // ARTIKEL: AKIDAH 1.2 — Kenapa Allah Itu Esa (Tauhid)?
    // ═══════════════════════════════════════════
    private val akidah1_2Article = listOf(
        ArticleBlock.Heading("Kenapa Allah Itu Esa (Tauhid)?"),
        ArticleBlock.Paragraph(
            "Oke, di modul sebelumnya kita udah bahas kalau ada Perancang di balik alam semesta. " +
            "Pertanyaan selanjutnya: \"Emangnya cuma satu? Bisa dong lebih dari satu?\""
        ),
        ArticleBlock.Paragraph(
            "Pertanyaan ini penting banget, karena jawabannya ngaruh ke cara kita ngelihat " +
            "seluruh alam semesta. Yuk kita bahas pakai logika yang sama — santai, gak ribet."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("🚗 Analogi: Dua Sopir, Satu Kemudi"),
        ArticleBlock.Paragraph(
            "Bayangin kamu naik mobil. Tiba-tiba ada DUA orang yang megang kemudi. " +
            "Yang satu mau belok kiri, yang satu mau belok kanan. Apa yang terjadi? " +
            "Kecelakaan. Kacau. Gak ada yang sampai tujuan."
        ),
        ArticleBlock.Paragraph(
            "Sekarang bayangin alam semesta ini. Ada jutaan hukum fisika yang bekerja " +
            "bersamaan dengan super presisi — gravitasi, elektromagnetik, gaya nuklir kuat dan lemah. " +
            "Semuanya saling melengkapi, gak konflik satu sama lain."
        ),
        ArticleBlock.Paragraph(
            "Kalau ada DUA \"Tuhan\" dengan kehendak berbeda, " +
            "pasti ada tabrakan di suatu titik. Satu mau atur gravitasi naik, satu mau turun. " +
            "Satu mau bikin air mengalir ke bawah, satu mau ke atas. Hasilnya? Kekacauan."
        ),
        ArticleBlock.Highlight(
            "Tapi kenyataannya: alam semesta ini rapi banget. Konsisten miliaran tahun. " +
            "Itu cuma mungkin kalau ADA SATU sumber kehendak."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("🔬 Bukti dari Keteraturan Kosmos"),
        ArticleBlock.Paragraph(
            "Para ilmuwan udah mengamati alam semesta selama ratusan tahun. " +
            "Dan yang mereka temuin: hukum-hukum alam itu UNIVERSAL. " +
            "Gravitasi di Bumi sama dengan gravitasi di galaksi lain. " +
            "Kecepatan cahaya konstan di mana pun."
        ),
        ArticleBlock.Paragraph(
            "Kalau ada lebih dari satu \"pengatur\", " +
            "mustahil keteraturan ini bisa terjaga konsisten. " +
            "Bayangin: satu perusahaan aja kalau ada dua CEO yang visinya beda, " +
            "pasti karyawan bingung. Apalagi alam semesta."
        ),
        ArticleBlock.Paragraph(
            "Jadi logikanya: kalau alam semesta ini teratur dan konsisten, " +
            "sumbernya pasti SATU. Satu Perancang. Satu Pengatur. " +
            "Dalam Islam, itu disebut Allah — yang Esa, gak berbilang."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("📜 Tauhid di Awal Sejarah"),
        ArticleBlock.Paragraph(
            "Menariknya, konsep \"Tuhan itu Esa\" bukan cuma ajaran Islam. " +
            "Di awal sejarahnya, hampir semua agama besar ngajarin Tauhid — " +
            "bahwa Tuhan itu satu."
        ),
        ArticleBlock.Paragraph(
            "Nabi Ibrahim ajarin Tauhid. Nabi Musa ajarin Tauhid. " +
            "Nabi Isa ajarin Tauhid. Tapi seiring waktu, ajaran itu berubah " +
            "karena campur tangan manusia. Islam datang sebagai penyempurnaan — " +
            "mengembalikan ajaran Tauhid murni yang udah ada sejak awal."
        ),
        ArticleBlock.Highlight(
            "Tauhid itu ajaran paling tua dalam sejarah manusia. " +
            "Islam bukan \"agama baru\" — Islam adalah Tauhid yang asli."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("📖 Ayat Al-Qur'an: Surat Al-Ikhlas"),
        ArticleBlock.Paragraph(
            "Surat Al-Ikhlas (QS. 112) adalah inti dari konsep Tauhid. " +
            "Cuma 4 ayat, tapi isinya ngejelasin konsep ke-Esa-an Allah secara sempurna:"
        ),
        ArticleBlock.EducatorNote(
            "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\n\n" +
            "قُلْ هُوَ اللَّهُ أَحَدٌ ١\n" +
            "Qul huwallahu ahad. (1)\n" +
            "Katakanlah: Dia-lah Allah, Yang Maha Esa.\n\n" +
            "اللَّهُ الصَّمَدُ ٢\n" +
            "Allahus-samad. (2)\n" +
            "Allah tempat meminta segala sesuatu.\n\n" +
            "لَمْ يَلِدْ وَلَمْ يُولَدْ ٣\n" +
            "Lam yalid wa lam yuulad. (3)\n" +
            "Dia tidak beranak dan tidak pula diperanakkan.\n\n" +
            "وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ ٤\n" +
            "Wa lam yakun lahu kufuwan ahad. (4)\n" +
            "Dan tidak ada sesuatu pun yang setara dengan Dia."
        ),
        ArticleBlock.Paragraph(
            "\"Al-Ahad\" artinya Yang Maha Esa — bener-bener satu, " +
            "gak ada duanya, gak ada yang nyamain. \"As-Samad\" artinya " +
            "tempat bergantung segala sesuatu — Dia butuh siapa-siapa, " +
            "tapi semua yang ada butuh Dia."
        ),
        ArticleBlock.Paragraph(
            "\"Tidak beranak dan tidak diperanakkan\" artinya Dia gak " +
            "lahir dari siapa pun dan gak melahirkan siapa pun. " +
            "Dia ada tanpa sebab — karena Dia SEBAB dari segalanya."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("💡 Kesimpulan"),
        ArticleBlock.Paragraph(
            "Tauhid itu sederhana: Allah itu SATU. Esa. Gak ada duanya. " +
            "Dan itu bukan cuma soal iman — tapi juga logika. " +
            "Alam semesta yang teratur ini cuma mungkin kalau sumbernya satu."
        ),
        ArticleBlock.Paragraph(
            "Di modul berikutnya, kita bakal bahas: kalau Allah udah ada " +
            "dan Esa, terus apa hubungannya sama kita? Dia ngurus kita gak sih? " +
            "Stay tuned."
        ),
        ArticleBlock.Cta(
            "Selesai baca! Saatnya kuis. Kamu pasti bisa. 🎯"
        )
    )

    private val akidah1_2Quiz = listOf(
        QuizQuestion(
            question = "Kenapa analogi \"dua sopir, satu kemudi\" dipake di artikel ini?",
            options = listOf(
                "Biar seru aja ceritanya",
                "Buat nunjukin kalau dua kehendak berbeda di satu sistem pasti bikin kacau",
                "Karena sopir itu penting",
                "Biar kamu hati-hati naik mobil"
            ),
            correctIndex = 1,
            explanation = "Logikanya: kalau ada dua pihak dengan kehendak beda megang kendali yang sama, hasilnya konflik. Makanya alam semesta yang rapi = bukti satu sumber kehendak."
        ),
        QuizQuestion(
            question = "Apa bukti dari keteraturan kosmos kalau Allah itu Esa?",
            options = listOf(
                "Bintang-bintang bentuknya bagus",
                "Hukum fisika universal dan konsisten miliaran tahun",
                "Langit biru warnanya cantik",
                "Bumi itu bulat"
            ),
            correctIndex = 1,
            explanation = "Hukum alam yang konsisten di mana pun dan kapan pun = mustahil kalau ada lebih dari satu \"pengatur\" dengan kehendak berbeda."
        ),
        QuizQuestion(
            question = "Menurut artikel, konsep Tauhid di agama-agama besar itu...",
            options = listOf(
                "Baru ada setelah Islam datang",
                "Cuma ada di Kristen aja",
                "Udah ada di awal sejarah agama-agama besar, tapi berubah seiring waktu",
                "Gak ada hubungannya sama Islam"
            ),
            correctIndex = 2,
            explanation = "Di awal sejarahnya, Nabi Ibrahim, Musa, dan Isa semuanya ngajarin Tauhid. Islam datang sebagai penyempurnaan dan pengembalian ke ajaran asli."
        ),
        QuizQuestion(
            question = "Apa arti \"As-Samad\" dalam Surat Al-Ikhlas?",
            options = listOf(
                "Yang Maha Kuasa",
                "Yang Maha Esa",
                "Tempat meminta / tempat bergantung segala sesuatu",
                "Yang Maha Pemurah"
            ),
            correctIndex = 2,
            explanation = "As-Samad artinya tempat bergantung. Allah gak butuh siapa-siapa, tapi semua yang ada butuh Dia."
        ),
        QuizQuestion(
            question = "\"Lam yalid wa lam yuulad\" artinya...",
            options = listOf(
                "Dia punya banyak anak",
                "Dia tidak beranak dan tidak diperanakkan",
                "Dia lahir dari manusia",
                "Dia punya orang tua"
            ),
            correctIndex = 1,
            explanation = "Allah gak lahir dari siapa pun dan gak melahirkan siapa pun. Dia ada tanpa sebab — karena Dia SEBAB dari segalanya."
        )
    )

    // ═══════════════════════════════════════════
    // ARTIKEL: AKIDAH 1.3 — Al-Quran: Firman Tuhan, Bukan Karangan Manusia
    // ═══════════════════════════════════════════
    private val akidah1_3Article = listOf(
        ArticleBlock.Heading("Al-Quran: Firman Tuhan, Bukan Karangan Manusia"),
        ArticleBlock.Paragraph(
            "Kita udah bahas kalau Tuhan itu ada dan Esa. " +
            "Pertanyaan berikutnya yang wajar banget: \"Oke, kalau Tuhan ada — " +
            "dia ngomong sama kita gak? Ada buktinya?\""
        ),
        ArticleBlock.Paragraph(
            "Kalau kamu Muslim, kamu pasti dengar \"Al-Quran itu firman Allah.\" " +
            "Tapi kenapa bisa yakin? Apa bedanya sama buku biasa? " +
            "Yuk kita lihat beberapa hal yang menarik — kamu nilai sendiri."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("1️⃣ Nabi Muhammad ﷺ Gak Bisa Baca-Tulis"),
        ArticleBlock.Paragraph(
            "Ini fakta sejarah yang disepakati semua sejarawan, " +
            "baik Muslim maupun non-Muslim: Muhammad ﷺ itu ummi — " +
            "gak bisa baca, gak bisa tulis. Tumbuh di jazirah Arab abad ke-7, " +
            "di mana tingkat literasi sangat rendah."
        ),
        ArticleBlock.Paragraph(
            "Sekarang bayangin: orang yang gak pernah baca buku, " +
            "gak pernah sekolah, gak pernah belajar sastra atau sains — " +
            "tiba-tiba menghasilkan teks sepanjang 30 juz (6.000+ ayat) " +
            "dengan bahasa Arab paling tinggi tingkat sastranya, " +
            "isi yang konsisten, dan pembahasan yang mencakup hukum, " +
            "sejarah, sains, filsafat, dan spiritualitas."
        ),
        ArticleBlock.Highlight(
            "Secara logika: kalau kamu gak pernah belajar coding, " +
            "bisakah kamu tiba-tiba bikin app sekompleks Gojek? " +
            "Sama halnya dengan Al-Quran."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("2️⃣ Keajaiban Bahasa (I'jaz)"),
        ArticleBlock.Paragraph(
            "Al-Quran itu bukan cuma soal isinya — bahasanya pun " +
            "di luar kemampuan manusia biasa. Zaman Nabi ﷺ, bangsa Arab " +
            "terkenal sebagai bangsa sastrawan. Puisi dan pidato itu " +
            "olahraga nasional mereka."
        ),
        ArticleBlock.Paragraph(
            "Tapi ketika Al-Quran dibacakan, para penyair terbaik Arab " +
            "pada saat itu — yang udah bertahun-tahun bikin puisi — " +
            "gak bisa menandinginya. Bahkan mereka mengakui: ini bukan " +
            "karya manusia."
        ),
        ArticleBlock.Paragraph(
            "Al-Quran sendiri menantang terbuka: \"Coba bikin 1 surah " +
            "semisal ini kalau kamu sanggup.\" (QS. Al-Baqarah: 23). " +
            "Tantangan itu udah ada selama 1.400 tahun. " +
            "Belum ada yang berhasil."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("3️⃣ Diwahyukan 23 Tahun, Tanpa Kontradiksi"),
        ArticleBlock.Paragraph(
            "Bayangin kamu nulis buku — tapi gak sekaligus. " +
            "Kamu nulisnya sedikit-sedikit selama 23 TAHUN. " +
            "Di rumah, di perjalanan, di saat perang, di saat damai, " +
            "di saat senang, di saat susah."
        ),
        ArticleBlock.Paragraph(
            "Teks yang dihasilkan harus konsisten. Gak boleh ada " +
            "yang saling bertentangan. Gak boleh lupa apa yang udah " +
            "ditulis sebelumnya. Dan harus relevan dengan kejadian " +
            "yang sedang terjadi saat itu."
        ),
        ArticleBlock.Paragraph(
            "Al-Quran diwahyukan selama 23 tahun, di kondisi yang " +
            "sangat berbeda-beda — dari Makkah (minoritas tertindas) " +
            "sampai Madinah (memimpin negara). Tapi isinya konsisten. " +
            "Gak ada kontradiksi internal. Cobain nulis jurnal 23 tahun " +
            "tanpa pernah kontradiksi diri sendiri — susah banget kan?"
        ),
        ArticleBlock.Highlight(
            "23 tahun. Ribuan ayat. Berbagai kondisi. " +
            "Nol kontradiksi. Coba lakuin itu pakai buku catatanmu."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("4️⃣ Satu-Satunya Kitab Suci yang Teksnya Terjaga 100%"),
        ArticleBlock.Paragraph(
            "Ini fakta yang jarang orang sadari: hampir semua kitab suci " +
            "di dunia pernah mengalami perubahan teks seiring waktu. " +
            "Manuskrip lama ditemukan dengan variasi. Ada penambahan, " +
            "pengurangan, atau perbedaan antar versi."
        ),
        ArticleBlock.Paragraph(
            "Al-Quran? Dari awal diturunkan sampai sekarang — " +
            "1.400+ tahun — teksnya IDENTIK. Gak ada perbedaan satu huruf pun. " +
            "Kenapa? Karena Al-Quran dijaga dengan dua cara: " +
            "ditulis DAN dihafal."
        ),
        ArticleBlock.Paragraph(
            "Saat ini ada JUTAAN orang di seluruh dunia yang hafal " +
            "seluruh 30 juz Al-Quran dari luar. Kalau semua mushaf " +
            "di dunia hilang sekalipun, Al-Quran bisa ditulis ulang " +
            "100% persis sama dari hafalan mereka."
        ),
        ArticleBlock.Paragraph(
            "Gak ada kitab suci lain yang punya sistem preservasi se-ekstrem ini. " +
            "Ini bukan soal iman — ini fakta historis yang bisa diverifikasi."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("5️⃣ Informasi yang \"Gak Mungkin Diketahui\" di Abad ke-7"),
        ArticleBlock.Paragraph(
            "Al-Quran berisi beberapa hal yang menarik — " +
            "sesuatu yang baru bisa diverifikasi oleh sains modern, " +
            "tapi udah disebutkan 14 abad lalu. Contoh:"
        ),
        ArticleBlock.Paragraph(
            "• Perkembangan janin secara bertahap (QS. Al-Mu'minun: 12-14) — " +
            "menggambarkan tahapan embrio dengan detail yang baru " +
            "bisa diamati lewat mikroskop modern."
        ),
        ArticleBlock.Paragraph(
            "• Alam semesta yang mengembang (QS. Adz-Dzariyat: 47) — " +
            "\"Dan langit itu Kami bangun dengan kekuatan dan sesungguhnya Kami " +
            "benar-benar meluaskannya.\" Fakta ini baru ditemukan astronom " +
            "Edwin Hubble tahun 1929."
        ),
        ArticleBlock.Paragraph(
            "• Siklus air (QS. Az-Zumar: 21) — menggambarkan proses " +
            "penguapan, pembentukan awan, dan turunnya hujan secara " +
            "ilmiah, jauh sebelum meteorologi modern."
        ),
        ArticleBlock.EducatorNote(
            "Catatan penting: ini bukan klaim \"Al-Quran = buku sains.\" " +
            "Al-Quran adalah kitab petunjuk. Tapi ayat-ayat ini menarik " +
            "untuk direnungkan — bagaimana seseorang di abad ke-7 " +
            "bisa tahu hal-hal ini tanpa alat modern? Worth thinking about."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("6️⃣ Tantangan Terbuka yang Belum Terjawab"),
        ArticleBlock.Paragraph(
            "Al-Quran punya satu tantangan yang gak pernah berubah " +
            "selama 1.400 tahun: \"Buatlah satu surah semisal Al-Quran.\" " +
            "(QS. Yunus: 38, Al-Baqarah: 23-24, Hud: 13)"
        ),
        ArticleBlock.Paragraph(
            "Tantangan ini bukan cuma soal bikin puisi bagus. " +
            "Kriterianya: harus dalam bahasa Arab yang setara, " +
            "isinya harus konsisten, harus punya hukum dan petunjuk, " +
            "dan harus bisa meyakinkan jutaan orang selama berabad-abad."
        ),
        ArticleBlock.Paragraph(
            "Selama 14 abad, banyak yang mencoba. " +
            "Hasilnya? Gak ada yang bertahan. " +
            "Para pakar sastra Arab sendiri mengakui: " +
            "gaya bahasa Al-Quran itu unik — bukan puisi, bukan prosa, " +
            "bukan pidato. Kategorinya sendiri."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("💭 Refleksi"),
        ArticleBlock.Paragraph(
            "Kamu gak harus langsung percaya semua ini. " +
            "Gak ada yang maksa. Justru bagus kalau kamu mau " +
            "renungkan pelan-pelan, tanya-tanya, cari tahu sendiri."
        ),
        ArticleBlock.Paragraph(
            "Yang menarik: semua poin di atas — ummi, i'jaz, " +
            "23 tahun konsistensi, preservasi, informasi ilmiah, " +
            "tantangan terbuka — ini bukan satu argumen lemah. " +
            "Ini banyak argumen yang saling menguatkan."
        ),
        ArticleBlock.Paragraph(
            "Dan kalau memang Al-Quran beneran dari Tuhan — " +
            "maka isinya layak banget dibaca pelan-pelan. " +
            "Mungkin itu langkah berikutnya."
        ),
        ArticleBlock.Cta(
            "Kamu udah selesai baca! Sekarang coba jawab kuisnya. 🎯"
        )
    )

    private val akidah1_3Quiz = listOf(
        QuizQuestion(
            question = "Kenapa fakta bahwa Nabi Muhammad ﷺ itu ummi (gak bisa baca-tulis) jadi penting?",
            options = listOf(
                "Karena itu artinya dia bodoh",
                "Karena mustahil orang yang gak bisa baca-tulis mengarang teks serumit Al-Quran",
                "Karena itu artinya dia kaya",
                "Karena itu gak penting sama sekali"
            ),
            correctIndex = 1,
            explanation = "Secara logika, orang yang gak pernah belajar sastra atau sains gak mungkin menghasilkan teks 30 juz dengan bahasa Arab paling tinggi tingkatnya. Ini jadi argumen kuat kalau Al-Quran bukan karangan manusia."
        ),
        QuizQuestion(
            question = "Apa itu i'jaz Al-Quran?",
            options = listOf(
                "Jumlah ayat dalam Al-Quran",
                "Keajaiban bahasa Al-Quran yang gak bisa ditandingi oleh siapa pun",
                "Cara membaca Al-Quran yang benar",
                "Nama surah pertama"
            ),
            correctIndex = 1,
            explanation = "I'jaz artinya membuat takjub. Bahasa Al-Quran itu unik — bukan puisi, bukan prosa, bukan pidato. Para penyair terbaik Arab pun gagal menandinginya."
        ),
        QuizQuestion(
            question = "Al-Quran diwahyukan selama berapa tahun, dan kenapa itu mengagumkan?",
            options = listOf(
                "1 tahun, karena cepat",
                "23 tahun di berbagai kondisi, tapi tetap konsisten tanpa kontradiksi",
                "50 tahun, karena terlalu lama",
                "10 tahun di satu kondisi saja"
            ),
            correctIndex = 1,
            explanation = "23 tahun di kondisi sangat berbeda (minoritas tertindas → pemimpin negara), tapi isinya konsisten tanpa kontradiksi internal. Cobain nulis jurnal 23 tahun tanpa pernah kontradiksi diri — susah banget."
        ),
        QuizQuestion(
            question = "Apa yang bikin Al-Quran beda dari kitab suci lain soal preservasi?",
            options = listOf(
                "Cuma ditulis di batu",
                "Dijaga lewat tulisan DAN dihafal jutaan orang — teksnya identik selama 1.400 tahun",
                "Diterjemahkan ke banyak bahasa",
                "Disimpan di satu tempat khusus"
            ),
            correctIndex = 1,
            explanation = "Al-Quran dijaga dua cara: ditulis dan dihafal. Jutaan hafiz hafal 30 juz dari luar. Kalau semua mushaf hilang pun, Al-Quran bisa ditulis ulang 100% identik."
        ),
        QuizQuestion(
            question = "Sikap yang tepat setelah baca modul ini menurut artikel adalah...",
            options = listOf(
                "Harus langsung percaya 100%",
                "Tidak usah percaya sama sekali",
                "Renyungkan pelan-pelan, tanya-tanya, cari tahu sendiri",
                "Simpan aja, gak usah dipikirin"
            ),
            correctIndex = 2,
            explanation = "Artikel bilang: kamu gak harus langsung percaya. Justru bagus kalau mau renungkan pelan-pelan, tanya-tanya, dan cari tahu sendiri. Kebenaran itu layak ditelusuri."
        )
    )

    // ═══════════════════════════════════════════
    // ARTIKEL: RUKUN ISLAM 1.1 (placeholder for future prompt)
    // ═══════════════════════════════════════════
    private val rukun1_1Article = listOf(
        ArticleBlock.Heading("Rukun Islam: Apa Aja Sih?"),
        ArticleBlock.Paragraph("Konten akan datang di prompt berikutnya. Stay tuned! 🚀"),
        ArticleBlock.Cta("Kuis belum tersedia untuk modul ini.")
    )

    private val rukun1_1Quiz = listOf(
        QuizQuestion(
            question = "Modul ini belum tersedia. Kuis akan hadir segera!",
            options = listOf("Oke, tunggu aja", "Siap!", "Penasaran", "Sip"),
            correctIndex = 0,
            explanation = "Modul ini sedang dalam pengembangan. Tunggu update berikutnya ya!"
        )
    )

    // ═══════════════════════════════════════════
    // ARTIKEL: PRAKTIK IBADAH 1.1 (placeholder for future prompt)
    // ═══════════════════════════════════════════
    private val praktik1_1Article = listOf(
        ArticleBlock.Heading("Cara Sholat: Step by Step"),
        ArticleBlock.Paragraph("Konten akan datang di prompt berikutnya. Stay tuned! 🚀"),
        ArticleBlock.Cta("Kuis belum tersedia untuk modul ini.")
    )

    private val praktik1_1Quiz = listOf(
        QuizQuestion(
            question = "Modul ini belum tersedia. Kuis akan hadir segera!",
            options = listOf("Oke, tunggu aja", "Siap!", "Penasaran", "Sip"),
            correctIndex = 0,
            explanation = "Modul ini sedang dalam pengembangan. Tunggu update berikutnya ya!"
        )
    )
}

// ═══════════════════════════════════════════
// Article Block Types (rich content model)
// ═══════════════════════════════════════════
sealed class ArticleBlock {
    data class Heading(val text: String) : ArticleBlock()
    data class Subheading(val text: String) : ArticleBlock()
    data class Paragraph(val text: String) : ArticleBlock()
    data class Highlight(val text: String) : ArticleBlock()
    data class EducatorNote(val text: String) : ArticleBlock()
    data class Cta(val text: String) : ArticleBlock()
    object Divider : ArticleBlock()
}

// ═══════════════════════════════════════════
// MAIN BELAJAR SCREEN — Navigation hub
// ═══════════════════════════════════════════

@Composable
fun BelajarScreen(
    viewModel: GameViewModel,
    state: MuslimLevelingData
) {
    // Sub-screen navigation: "hub", "article:<moduleId>", "quiz:<moduleId>", "result:<moduleId>:<score>"
    var currentView by remember { mutableStateOf("hub") }
    var selectedModuleId by remember { mutableStateOf<String?>(null) }

    when {
        currentView.startsWith("article:") -> {
            val moduleId = currentView.removePrefix("article:")
            ModuleArticleView(
                moduleId = moduleId,
                onBack = { currentView = "hub" },
                onStartQuiz = { currentView = "quiz:$moduleId" }
            )
        }
        currentView.startsWith("quiz:") -> {
            val moduleId = currentView.removePrefix("quiz:")
            ModuleQuizView(
                moduleId = moduleId,
                viewModel = viewModel,
                onBack = { currentView = "article:$moduleId" },
                onFinish = { score ->
                    currentView = "result:$moduleId:$score"
                }
            )
        }
        currentView.startsWith("result:") -> {
            val parts = currentView.removePrefix("result:").split(":")
            val moduleId = parts[0]
            val score = parts[1].toIntOrNull() ?: 0
            QuizResultView(
                moduleId = moduleId,
                score = score,
                viewModel = viewModel,
                onBackToHub = { currentView = "hub" },
                onRetry = { currentView = "quiz:$moduleId" }
            )
        }
        else -> {
            BelajarHubView(
                state = state,
                onModuleTap = { moduleId ->
                    selectedModuleId = moduleId
                    currentView = "article:$moduleId"
                }
            )
        }
    }
}

// ═══════════════════════════════════════════
// HUB VIEW — Category tabs + module cards
// ═══════════════════════════════════════════

@Composable
fun BelajarHubView(
    state: MuslimLevelingData,
    onModuleTap: (String) -> Unit
) {
    val categories = LearningContent.categories
    var selectedCategoryIndex by remember { mutableIntStateOf(0) }
    val selectedCategory = categories[selectedCategoryIndex]
    val progress = state.learningState.progress

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
            .muslimPattern()
            .windowInsetsPadding(WindowInsets.statusBars)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(top = 28.dp, bottom = 80.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Header
        Text(
            text = "LEARNING HUB",
            fontSize = 11.sp,
            fontWeight = FontWeight.ExtraBold,
            color = GoldAccent,
            letterSpacing = 2.5.sp
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "Belajar Bareng 📚",
            fontSize = 22.sp,
            fontWeight = FontWeight.Black,
            color = TextLight
        )
        Text(
            text = "Mulai dari dasar, naik pelan-pelan. Gak ada yang nyuruh buru-buru kok.",
            fontSize = 12.sp,
            color = TextMuted,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 6.dp, bottom = 24.dp)
        )

        // Segmented Control
        SegmentedControl(
            categories = categories,
            selectedIndex = selectedCategoryIndex,
            onSelect = { selectedCategoryIndex = it }
        )

        Spacer(modifier = Modifier.height(20.dp))

        // Category description
        val categoryDesc = when (selectedCategory.id) {
            "akidah" -> "Dasar kepercayaan — kenapa kita butuh Tuhan, siapa Dia, dan apa hubungannya sama kita."
            "rukun_islam" -> "Pilar-pilar Islam yang jadi fondasi ibadah seorang Muslim."
            "praktik_ibadah" -> "Cara praktis ibadah sehari-hari, dari nol sampai lancar."
            else -> ""
        }
        Text(
            text = categoryDesc,
            fontSize = 12.sp,
            color = TextMuted,
            lineHeight = 17.sp,
            modifier = Modifier.padding(bottom = 16.dp)
        )

        // Module Cards
        selectedCategory.modules.forEachIndexed { index, module ->
            val moduleProgress = progress.find { it.moduleId == module.id }
            val isUnlocked = LearningContent.isModuleUnlocked(module.id, progress)
            val status = when {
                moduleProgress?.xpClaimed == true -> ModuleStatus.CLAIMED
                moduleProgress?.completed == true -> ModuleStatus.COMPLETED
                isUnlocked -> ModuleStatus.AVAILABLE
                else -> ModuleStatus.LOCKED
            }

            ModuleCard(
                module = module,
                status = status,
                orderNumber = index + 1,
                onClick = {
                    if (status != ModuleStatus.LOCKED) onModuleTap(module.id)
                }
            )
            if (index < selectedCategory.modules.lastIndex) {
                Spacer(modifier = Modifier.height(12.dp))
            }
        }

        if (selectedCategory.modules.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        Color(0xFF111827).copy(alpha = 0.5f),
                        RoundedCornerShape(16.dp)
                    )
                    .border(
                        BorderStroke(1.dp, Color(0xFF1F2937)),
                        RoundedCornerShape(16.dp)
                    )
                    .padding(32.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Modul untuk kategori ini segera hadir! 🚀",
                    color = TextMuted,
                    fontSize = 13.sp,
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

enum class ModuleStatus { LOCKED, AVAILABLE, COMPLETED, CLAIMED }

@Composable
fun SegmentedControl(
    categories: List<LearningCategory>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(DarkSurface, RoundedCornerShape(14.dp))
            .border(1.dp, DarkSurfaceVariant, RoundedCornerShape(14.dp))
            .padding(4.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        categories.forEachIndexed { index, category ->
            val isSelected = index == selectedIndex
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(10.dp))
                    .background(
                        if (isSelected) IslamicGreen.copy(alpha = 0.15f)
                        else Color.Transparent
                    )
                    .clickable { onSelect(index) }
                    .padding(vertical = 10.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = category.icon,
                        fontSize = 16.sp
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = category.label,
                        fontSize = 11.sp,
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                        color = if (isSelected) IslamicGreen else TextMuted
                    )
                }
            }
        }
    }
}

@Composable
fun ModuleCard(
    module: LearningModule,
    status: ModuleStatus,
    orderNumber: Int,
    onClick: () -> Unit
) {
    val borderColor = when (status) {
        ModuleStatus.LOCKED -> DarkSurfaceVariant.copy(alpha = 0.5f)
        ModuleStatus.AVAILABLE -> IslamicGreen.copy(alpha = 0.3f)
        ModuleStatus.COMPLETED -> GoldAccent.copy(alpha = 0.5f)
        ModuleStatus.CLAIMED -> DarkSurfaceVariant
    }

    val containerAlpha = if (status == ModuleStatus.LOCKED) 0.5f else 1f

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(enabled = status != ModuleStatus.LOCKED) { onClick() },
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(
            containerColor = DarkSurface.copy(alpha = containerAlpha)
        ),
        border = BorderStroke(1.2.dp, borderColor)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Module number / icon
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(
                        when (status) {
                            ModuleStatus.LOCKED -> DarkSurfaceVariant
                            ModuleStatus.AVAILABLE -> IslamicGreen.copy(alpha = 0.12f)
                            ModuleStatus.COMPLETED -> GoldAccent.copy(alpha = 0.12f)
                            ModuleStatus.CLAIMED -> DarkSurfaceVariant
                        }
                    ),
                contentAlignment = Alignment.Center
            ) {
                when (status) {
                    ModuleStatus.LOCKED -> Text("🔒", fontSize = 20.sp)
                    ModuleStatus.COMPLETED -> Text("✅", fontSize = 20.sp)
                    ModuleStatus.CLAIMED -> Text("✅", fontSize = 20.sp)
                    else -> Text(module.icon, fontSize = 22.sp)
                }
            }

            Spacer(modifier = Modifier.width(14.dp))

            // Module info
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = module.title,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = if (status == ModuleStatus.LOCKED) TextMuted else TextLight
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Status text
                    Text(
                        text = when (status) {
                            ModuleStatus.LOCKED -> "🔒 Terkunci"
                            ModuleStatus.AVAILABLE -> "📖 Belum selesai"
                            ModuleStatus.COMPLETED -> "✅ Selesai"
                            ModuleStatus.CLAIMED -> "✅ Selesai"
                        },
                        fontSize = 11.sp,
                        color = when (status) {
                            ModuleStatus.LOCKED -> TextMuted
                            ModuleStatus.AVAILABLE -> IslamicGreen
                            ModuleStatus.COMPLETED -> GoldAccent
                            ModuleStatus.CLAIMED -> TextMuted
                        }
                    )
                    // Estimasi baca
                    Text(
                        text = "⏱ ${module.estimatedMinutes} mnt",
                        fontSize = 10.sp,
                        color = TextMuted
                    )
                }
            }

            // XP badge
            Box(
                modifier = Modifier
                    .background(
                        if (status == ModuleStatus.CLAIMED) DarkSurfaceVariant
                        else IslamicGreen.copy(alpha = 0.15f),
                        RoundedCornerShape(8.dp)
                    )
                    .padding(horizontal = 10.dp, vertical = 5.dp)
            ) {
                Text(
                    text = if (status == ModuleStatus.CLAIMED) "✓ Claimed"
                    else "+${module.xpReward} XP",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.ExtraBold,
                    color = if (status == ModuleStatus.CLAIMED) TextMuted else IslamicGreen
                )
            }
        }
    }
}

// ═══════════════════════════════════════════
// ARTICLE VIEW — Clean blog post style
// ═══════════════════════════════════════════

@Composable
fun ModuleArticleView(
    moduleId: String,
    onBack: () -> Unit,
    onStartQuiz: () -> Unit
) {
    val blocks = LearningContent.getArticleContent(moduleId)
    val module = LearningContent.getAllModulesOrdered().find { it.id == moduleId }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
            .windowInsetsPadding(WindowInsets.statusBars)
    ) {
        // Top bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .clip(CircleShape)
                    .clickable { onBack() }
                    .padding(8.dp)
            ) {
                Text("← Kembali", color = IslamicGreen, fontSize = 13.sp, fontWeight = FontWeight.Bold)
            }
            Spacer(modifier = Modifier.weight(1f))
            module?.let {
                Text(
                    text = "${it.icon} ${it.title}",
                    fontSize = 12.sp,
                    color = TextMuted,
                    maxLines = 1
                )
            }
        }

        HorizontalDivider(color = DarkSurfaceVariant, thickness = 1.dp)

        // Article content
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 20.dp)
        ) {
            blocks.forEach { block ->
                when (block) {
                    is ArticleBlock.Heading -> {
                        Text(
                            text = block.text,
                            fontSize = 24.sp,
                            fontWeight = FontWeight.Black,
                            color = TextLight,
                            lineHeight = 32.sp,
                            modifier = Modifier.padding(bottom = 16.dp)
                        )
                    }
                    is ArticleBlock.Subheading -> {
                        Text(
                            text = block.text,
                            fontSize = 17.sp,
                            fontWeight = FontWeight.Bold,
                            color = GoldAccent,
                            modifier = Modifier.padding(top = 8.dp, bottom = 10.dp)
                        )
                    }
                    is ArticleBlock.Paragraph -> {
                        Text(
                            text = block.text,
                            fontSize = 14.sp,
                            color = TextLight.copy(alpha = 0.9f),
                            lineHeight = 22.sp,
                            modifier = Modifier.padding(bottom = 12.dp)
                        )
                    }
                    is ArticleBlock.Highlight -> {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 12.dp),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = IslamicGreen.copy(alpha = 0.08f)
                            ),
                            border = BorderStroke(1.dp, IslamicGreen.copy(alpha = 0.3f))
                        ) {
                            Row(modifier = Modifier.padding(16.dp)) {
                                Text("💡 ", fontSize = 16.sp)
                                Text(
                                    text = block.text,
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = IslamicGreen,
                                    lineHeight = 21.sp
                                )
                            }
                        }
                    }
                    is ArticleBlock.EducatorNote -> {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 12.dp),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = GoldAccent.copy(alpha = 0.06f)
                            ),
                            border = BorderStroke(1.dp, GoldAccent.copy(alpha = 0.2f))
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text(
                                    text = "📖 Catatan",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.ExtraBold,
                                    color = GoldAccent,
                                    letterSpacing = 1.sp
                                )
                                Spacer(modifier = Modifier.height(6.dp))
                                Text(
                                    text = block.text,
                                    fontSize = 13.sp,
                                    fontStyle = FontStyle.Italic,
                                    color = GoldAccent.copy(alpha = 0.85f),
                                    lineHeight = 20.sp
                                )
                            }
                        }
                    }
                    is ArticleBlock.Cta -> {
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = block.text,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                            color = IslamicGreen,
                            textAlign = TextAlign.Center,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp)
                        )
                    }
                    is ArticleBlock.Divider -> {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 16.dp),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .width(40.dp)
                                    .height(2.dp)
                                    .background(DarkSurfaceVariant, CircleShape)
                            )
                            Text(
                                text = "  ✦  ",
                                color = TextMuted,
                                fontSize = 10.sp
                            )
                            Box(
                                modifier = Modifier
                                    .width(40.dp)
                                    .height(2.dp)
                                    .background(DarkSurfaceVariant, CircleShape)
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
        }

        // Bottom CTA button
        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = DarkSurface,
            shadowElevation = 12.dp
        ) {
            Button(
                onClick = onStartQuiz,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp, vertical = 16.dp)
                    .height(52.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = IslamicGreen
                ),
                shape = RoundedCornerShape(14.dp)
            ) {
                Text(
                    text = "Lanjut ke Kuis 🎯",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.Black
                )
            }
        }
    }
}

// ═══════════════════════════════════════════
// QUIZ VIEW — Satisfying check/cross per answer
// ═══════════════════════════════════════════

@Composable
fun ModuleQuizView(
    moduleId: String,
    viewModel: GameViewModel,
    onBack: () -> Unit,
    onFinish: (Int) -> Unit
) {
    val questions = LearningContent.getQuizQuestions(moduleId)
    if (questions.isEmpty()) {
        Box(
            modifier = Modifier.fillMaxSize().background(DarkBackground),
            contentAlignment = Alignment.Center
        ) {
            Text("Kuis belum tersedia", color = TextMuted)
        }
        return
    }

    var currentIndex by remember { mutableIntStateOf(0) }
    var correctCount by remember { mutableIntStateOf(0) }
    var selectedOption by remember { mutableIntStateOf(-1) }
    var showResult by remember { mutableStateOf(false) }

    val question = questions[currentIndex]

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
            .windowInsetsPadding(WindowInsets.statusBars)
    ) {
        // Top bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .clip(CircleShape)
                    .clickable { onBack() }
                    .padding(8.dp)
            ) {
                Text("← Kembali", color = IslamicGreen, fontSize = 13.sp, fontWeight = FontWeight.Bold)
            }
            Spacer(modifier = Modifier.weight(1f))
            Text(
                text = "Soal ${currentIndex + 1}/${questions.size}",
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                color = TextLight
            )
        }

        // Progress bar
        LinearProgressIndicator(
            progress = { (currentIndex + 1).toFloat() / questions.size },
            modifier = Modifier
                .fillMaxWidth()
                .height(4.dp),
            color = IslamicGreen,
            trackColor = DarkSurfaceVariant
        )

        HorizontalDivider(color = DarkSurfaceVariant, thickness = 1.dp)

        // Question content
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 24.dp)
        ) {
            // Question text
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                border = BorderStroke(1.dp, DarkSurfaceVariant)
            ) {
                Text(
                    text = question.question,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextLight,
                    lineHeight = 24.sp,
                    modifier = Modifier.padding(20.dp)
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Options
            question.options.forEachIndexed { index, option ->
                val isSelected = selectedOption == index
                val isCorrect = index == question.correctIndex
                val showFeedback = showResult

                val optionBorder = when {
                    !showFeedback && isSelected -> IslamicGreen.copy(alpha = 0.6f)
                    showFeedback && isCorrect -> IslamicGreen
                    showFeedback && isSelected && !isCorrect -> RingRed
                    else -> DarkSurfaceVariant.copy(alpha = 0.6f)
                }

                val optionBg = when {
                    !showFeedback && isSelected -> IslamicGreen.copy(alpha = 0.08f)
                    showFeedback && isCorrect -> IslamicGreen.copy(alpha = 0.1f)
                    showFeedback && isSelected && !isCorrect -> RingRed.copy(alpha = 0.08f)
                    else -> DarkSurface
                }

                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 10.dp)
                        .clickable(enabled = !showResult) {
                            selectedOption = index
                        },
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = optionBg),
                    border = BorderStroke(1.2.dp, optionBorder)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Option letter
                        Box(
                            modifier = Modifier
                                .size(32.dp)
                                .clip(CircleShape)
                                .background(
                                    when {
                                        showFeedback && isCorrect -> IslamicGreen
                                        showFeedback && isSelected && !isCorrect -> RingRed
                                        isSelected -> IslamicGreen.copy(alpha = 0.3f)
                                        else -> DarkSurfaceVariant
                                    }
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = when {
                                    showFeedback && isCorrect -> "✓"
                                    showFeedback && isSelected && !isCorrect -> "✗"
                                    else -> ('A' + index).toString()
                                },
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = when {
                                    showFeedback && (isCorrect || (isSelected && !isCorrect)) -> Color.Black
                                    isSelected -> IslamicGreen
                                    else -> TextMuted
                                }
                            )
                        }

                        Spacer(modifier = Modifier.width(14.dp))

                        Text(
                            text = option,
                            fontSize = 13.sp,
                            color = if (showFeedback && isSelected && !isCorrect)
                                TextMuted else TextLight,
                            lineHeight = 19.sp,
                            modifier = Modifier.weight(1f)
                        )

                        // Feedback icon
                        AnimatedVisibility(
                            visible = showFeedback && isCorrect,
                            enter = scaleIn(initialScale = 0.5f) + fadeIn()
                        ) {
                            Text("✅", fontSize = 18.sp)
                        }
                        AnimatedVisibility(
                            visible = showFeedback && isSelected && !isCorrect,
                            enter = scaleIn(initialScale = 0.5f) + fadeIn()
                        ) {
                            Text("❌", fontSize = 18.sp)
                        }
                    }
                }
            }

            // Explanation (shown after answering)
            AnimatedVisibility(
                visible = showResult,
                enter = expandVertically() + fadeIn()
            ) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 8.dp),
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = GoldAccent.copy(alpha = 0.06f)
                    ),
                    border = BorderStroke(1.dp, GoldAccent.copy(alpha = 0.2f))
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = "💡 Penjelasan",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.ExtraBold,
                            color = GoldAccent,
                            letterSpacing = 1.sp
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = question.explanation,
                            fontSize = 13.sp,
                            color = TextLight.copy(alpha = 0.85f),
                            lineHeight = 20.sp
                        )
                    }
                }
            }
        }

        // Bottom action
        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = DarkSurface,
            shadowElevation = 12.dp
        ) {
            if (!showResult) {
                Button(
                    onClick = {
                        if (selectedOption == -1) return@Button
                        showResult = true
                        if (selectedOption == question.correctIndex) {
                            correctCount++
                        }
                    },
                    enabled = selectedOption != -1,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 24.dp, vertical = 16.dp)
                        .height(52.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = IslamicGreen,
                        disabledContainerColor = DarkSurfaceVariant
                    ),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text(
                        text = "Jawab",
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                        color = if (selectedOption != -1) Color.Black else TextMuted
                    )
                }
            } else {
                Button(
                    onClick = {
                        if (currentIndex < questions.size - 1) {
                            currentIndex++
                            selectedOption = -1
                            showResult = false
                        } else {
                            val score = (correctCount * 100) / questions.size
                            viewModel.submitModuleQuiz(moduleId, score)
                            onFinish(score)
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 24.dp, vertical = 16.dp)
                        .height(52.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (currentIndex < questions.size - 1)
                            IslamicGreen else GoldAccent
                    ),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text(
                        text = if (currentIndex < questions.size - 1)
                            "Soal Berikutnya →"
                        else "Lihat Hasil 🎯",
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.Black
                    )
                }
            }
        }
    }
}

// ═══════════════════════════════════════════
// QUIZ RESULT VIEW — Score + XP claim
// ═══════════════════════════════════════════

@Composable
fun QuizResultView(
    moduleId: String,
    score: Int,
    viewModel: GameViewModel,
    onBackToHub: () -> Unit,
    onRetry: () -> Unit
) {
    val passed = score >= 70
    val module = LearningContent.getAllModulesOrdered().find { it.id == moduleId }
    val xpReward = module?.xpReward ?: 0

    // Animated score counter
    var animatedScore by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        val steps = 20
        val delay = 30L
        for (i in 0..steps) {
            animatedScore = (score * i) / steps
            kotlinx.coroutines.delay(delay)
        }
        animatedScore = score
    }

    // Claim XP automatically if passed
    var xpClaimed by remember { mutableStateOf(false) }
    LaunchedEffect(passed) {
        if (passed && !xpClaimed) {
            viewModel.claimModuleXp(moduleId, xpReward)
            xpClaimed = true
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
            .windowInsetsPadding(WindowInsets.statusBars)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Spacer(modifier = Modifier.height(60.dp))

        // Result icon
        Text(
            text = if (passed) "🎉" else "😅",
            fontSize = 64.sp
        )

        Spacer(modifier = Modifier.height(20.dp))

        Text(
            text = if (passed) "Kamu Lulus!" else "Belum Lolos",
            fontSize = 28.sp,
            fontWeight = FontWeight.Black,
            color = if (passed) GoldAccent else RingRed
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = if (passed) "Keren! Kamu jawab ${score}% dengan benar."
            else "Kamu jawab ${score}% benar. Butuh minimal 70% buat lulus. Coba lagi yuk!",
            fontSize = 14.sp,
            color = TextMuted,
            textAlign = TextAlign.Center,
            lineHeight = 21.sp
        )

        Spacer(modifier = Modifier.height(32.dp))

        // Score circle
        Box(
            modifier = Modifier
                .size(120.dp)
                .clip(CircleShape)
                .background(
                    brush = Brush.radialGradient(
                        colors = listOf(
                            (if (passed) IslamicGreen else RingRed).copy(alpha = 0.15f),
                            DarkSurface
                        )
                    )
                )
                .border(
                    3.dp,
                    if (passed) IslamicGreen else RingRed,
                    CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "$animatedScore%",
                    fontSize = 36.sp,
                    fontWeight = FontWeight.Black,
                    color = if (passed) IslamicGreen else RingRed
                )
                Text(
                    text = "skor",
                    fontSize = 11.sp,
                    color = TextMuted
                )
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        // XP reward card (only if passed)
        if (passed) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = IslamicGreen.copy(alpha = 0.08f)
                ),
                border = BorderStroke(1.dp, IslamicGreen.copy(alpha = 0.3f))
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("🎁", fontSize = 24.sp)
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text(
                            text = "+$xpReward XP",
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Black,
                            color = IslamicGreen
                        )
                        Text(
                            text = "Reward sudah masuk ke karaktermu!",
                            fontSize = 12.sp,
                            color = TextMuted
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
        }

        // Action buttons
        if (!passed) {
            Button(
                onClick = onRetry,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                colors = ButtonDefaults.buttonColors(containerColor = IslamicGreen),
                shape = RoundedCornerShape(14.dp)
            ) {
                Text(
                    text = "Coba Lagi 🔄",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.Black
                )
            }
            Spacer(modifier = Modifier.height(12.dp))
        }

        OutlinedButton(
            onClick = onBackToHub,
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
            shape = RoundedCornerShape(14.dp),
            border = BorderStroke(1.dp, DarkSurfaceVariant)
        ) {
            Text(
                text = "Kembali ke Learning Hub",
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = TextLight
            )
        }

        Spacer(modifier = Modifier.height(60.dp))
    }
}
