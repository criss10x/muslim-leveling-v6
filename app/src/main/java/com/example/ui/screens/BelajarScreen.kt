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
                ),
                LearningModule(
                    id = "akidah_1.4",
                    categoryId = "akidah",
                    title = "Siapa Itu Nabi Muhammad ﷺ?",
                    icon = "🫶",
                    estimatedMinutes = 4,
                    xpReward = 55
                ),
                LearningModule(
                    id = "akidah_1.5",
                    categoryId = "akidah",
                    title = "Apa Itu Iman dan Rukun Iman?",
                    icon = "💎",
                    estimatedMinutes = 5,
                    xpReward = 65
                )
            )
        ),
        LearningCategory(
            id = "rukun_islam",
            label = "Rukun Islam",
            icon = "🕌",
            modules = listOf(
                LearningModule(
                    id = "rukun_2.1",
                    categoryId = "rukun_islam",
                    title = "5 Rukun Islam: Fondasi Hidup Seorang Muslim",
                    icon = "⭐",
                    estimatedMinutes = 5,
                    xpReward = 60
                ),
                LearningModule(
                    id = "rukun_2.2",
                    categoryId = "rukun_islam",
                    title = "Syahadat: Gerbang Pertama",
                    icon = "🚪",
                    estimatedMinutes = 4,
                    xpReward = 50
                ),
                LearningModule(
                    id = "rukun_2.3",
                    categoryId = "rukun_islam",
                    title = "Kenapa Harus Puasa Ramadan?",
                    icon = "🌙",
                    estimatedMinutes = 5,
                    xpReward = 55
                ),
                LearningModule(
                    id = "rukun_2.4",
                    categoryId = "rukun_islam",
                    title = "Zakat: Kenapa Harus Berbagi?",
                    icon = "💰",
                    estimatedMinutes = 4,
                    xpReward = 50
                ),
                LearningModule(
                    id = "rukun_2.5",
                    categoryId = "rukun_islam",
                    title = "Haji: Perjalanan Sekali Seumur Hidup",
                    icon = "🕋",
                    estimatedMinutes = 4,
                    xpReward = 55
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
            "akidah_1.4" -> akidah1_4Article
            "akidah_1.5" -> akidah1_5Article
            "rukun_2.1" -> rukun2_1Article
            "rukun_2.2" -> rukun2_2Article
            "rukun_2.3" -> rukun2_3Article
            "rukun_2.4" -> rukun2_4Article
            "rukun_2.5" -> rukun2_5Article
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
            "akidah_1.4" -> akidah1_4Quiz
            "akidah_1.5" -> akidah1_5Quiz
            "rukun_2.1" -> rukun2_1Quiz
            "rukun_2.2" -> rukun2_2Quiz
            "rukun_2.3" -> rukun2_3Quiz
            "rukun_2.4" -> rukun2_4Quiz
            "rukun_2.5" -> rukun2_5Quiz
            "praktik_1.1" -> praktik1_1Quiz
            else -> emptyList()
        }
    }

    // ─── Helper: get ordered module list for unlock logic ───
    fun getAllModulesOrdered(): List<LearningModule> {
        return categories.flatMap { it.modules }
    }

    fun isModuleUnlocked(moduleId: String, progress: List<ModuleProgress>): Boolean {
        // Find which category this module belongs to
        val category = categories.find { cat -> cat.modules.any { it.id == moduleId } } ?: return false
        val indexInCategory = category.modules.indexOfFirst { it.id == moduleId }
        if (indexInCategory <= 0) return true // first module in each category always unlocked
        // Previous module IN SAME CATEGORY must be completed
        val prevModule = category.modules[indexInCategory - 1]
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
    // ARTIKEL: AKIDAH 1.4 — Siapa Itu Nabi Muhammad ﷺ?
    // ═══════════════════════════════════════════
    private val akidah1_4Article = listOf(
        ArticleBlock.Heading("Siapa Itu Nabi Muhammad ﷺ?"),
        ArticleBlock.Paragraph(
            "Di modul sebelumnya kita bahas Al-Quran. " +
            "Sekarang pertanyaan alamiah: siapa orang yang nrima wahyu itu? " +
            "Kenapa jutaan orang percaya dia utusan Tuhan?"
        ),
        ArticleBlock.Paragraph(
            "Kita gak bakal cerita panjang lebar soal sejarah hidupnya — " +
            "itu buku tersendiri. Tapi ada beberapa hal tentang Muhammad ﷺ " +
            "yang menarik banget dan worth kamu tahu."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("🤝 Al-Amin — \"Yang Terpercaya\""),
        ArticleBlock.Paragraph(
            "Sebelum jadi nabi di usia 40 tahun, Muhammad ﷺ udah tinggal " +
            "di Makkah selama 40 tahun. Dan julukannya? Al-Amin — " +
            "artinya \"yang terpercaya.\" Bukan dikasih sama Muslim, " +
            "tapi sama seluruh masyarakat Makkah, termasuk yang gak " +
            "seiman."
        ),
        ArticleBlock.Paragraph(
            "Orang-orang nitip barang berharga sama dia. " +
            "Mau nyari solusi sengketa? Datang ke Muhammad. " +
            "Musuh-musuhnya aja — yang kemudian mau ngebunuh dia — " +
            "sebelum kenal Islam, mereka TETEP percaya dia orang jujur. " +
            "Bahkan Abu Sufyan, salah satu musuh terbesarnya, " +
            "ketika ditanya Romawi: \"Pernahkah dia berbohong?\" " +
            "Jawab: \"Tidak.\""
        ),
        ArticleBlock.Highlight(
            "Bayangin: orang yang mau ngebunuh kamu aja ngakuin kamu gak pernah bohong. " +
            "Seberapa kuat kredibilitas seseorang kalau musuhnya aja ngakuin kejujurannya?"
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("📖 Kenapa Dipercaya Utusan Terakhir?"),
        ArticleBlock.Paragraph(
            "Beberapa alasan kenapa umat Islam percaya Muhammad ﷺ " +
            "itu utusan terakhir:"
        ),
        ArticleBlock.Paragraph(
            "• Al-Quran sendiri yang mengklaim — dan Al-Quran " +
            "punya bukti keasliannya (yang udah kita bahas di modul sebelumnya)."
        ),
        ArticleBlock.Paragraph(
            "• Konsistensi karakter — dari muda sampai wafat, " +
            "gak pernah ada catatan dia berbohong, meskipun itu " +
            "bisa nguntungin dia secara politik."
        ),
        ArticleBlock.Paragraph(
            "• Nubuatan di kitab-kitab sebelumnya — " +
            "Taurat dan Injil menyebutkan akan datang nabi setelah " +
            "Musa dan Isa. Banyak ciri-cirinya cocok sama Muhammad ﷺ."
        ),
        ArticleBlock.Paragraph(
            "• Kehidupannya terdokumentasi super detail — " +
            "Hadits (catatan perkataan dan perbuatannya) itu " +
            "jutaan, diriwayatkan dengan rantai periwayatan " +
            "yang bisa ditelusuri. Gak ada tokoh sejarah lain " +
            "yang hidupnya tercatat se-detail ini."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("⚖️ Nabi vs Tokoh Agama Lain"),
        ArticleBlock.Paragraph(
            "Yang bikin nabi beda dari tokoh agama lain: " +
            "nabi mengklaim langsung dapat pesan dari Tuhan. " +
            "Tokoh agama biasanya mengaku punya ilham atau inspirasi, " +
            "tapi nabi bilang: \"Tuhan ngomong langsung ke saya, " +
            "dan saya harus sampaikan ke kalian.\""
        ),
        ArticleBlock.Paragraph(
            "Muhammad ﷺ juga beda dari nabi-nabi sebelumnya: " +
            "dia nabi terakhir. Gak ada nabi setelah dia. " +
            "Dan risalahnya bukan buat satu kaum aja — tapi buat " +
            "seluruh manusia, sampai kiamat."
        ),
        ArticleBlock.Paragraph(
            "Yang menarik: meskipun jadi pemimpin negara dan " +
            "panglima perang, hidupnya tetep sederhana. " +
            "Kasurnya dari tikar, makannya sering cuma kurma dan air. " +
            "Gak kayak raja atau diktator yang hidup mewah. " +
            "Kekuasaannya gak dipake buat diri sendiri."
        ),
        ArticleBlock.Highlight(
            "Karakter Muhammad ﷺ: jujur sebelum jadi nabi, " +
            "jujur sesudah jadi nabi. Gak pernah berubah " +
            "meskipun punya kekuasaan besar."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("💡 Penutup"),
        ArticleBlock.Paragraph(
            "Muhammad ﷺ bukan tokoh mitos. Dia manusia nyata " +
            "dengan sejarah yang super detail. Dan karakternya " +
            "adalah salah satu bukti terkuat: orang se-jujur " +
            "itu gak mungkin ngarang soal Tuhan."
        ),
        ArticleBlock.Paragraph(
            "Di modul terakhir kategori Akidah, kita bakal " +
            "rangkum semua yang udah kita pelajari jadi satu " +
            "kerangka yang utuh: apa sih artinya \"beriman\"?"
        ),
        ArticleBlock.Cta(
            "Selesai baca! Kuisnya menanti. 🎯"
        )
    )

    private val akidah1_4Quiz = listOf(
        QuizQuestion(
            question = "Apa julukan Muhammad ﷺ sebelum jadi nabi, dan siapa yang ngasih?",
            options = listOf(
                "Al-Fatihah, dari keluarganya",
                "Al-Amin (Yang Terpercaya), dari seluruh masyarakat Makkah termasuk yang non-Muslim",
                "As-Sidiq, dari para sahabat",
                "Al-Mustafa, dari Tuhannya"
            ),
            correctIndex = 1,
            explanation = "Al-Amin artinya 'yang terpercaya.' Julukan ini dikasih oleh seluruh masyarakat Makkah — termasuk yang gak seiman — karena selama 40 tahun hidup di sana, dia gak pernah ketahuan bohong."
        ),
        QuizQuestion(
            question = "Kenapa fakta bahwa musuh-musuhnya aja ngakuin dia jujur itu penting?",
            options = listOf(
                "Karena musuh pasti jujur",
                "Karena kalau bahkan orang yang mau ngebunuh kamu aja ngakuin kamu gak pernah bohong, itu bukti kredibilitas luar biasa",
                "Karena musuh itu baik hati",
                "Karena itu gak penting"
            ),
            correctIndex = 1,
            explanation = "Abu Sufyan, musuh terbesar Muhammad ﷺ, ketika ditanya 'pernahkah dia berbohong?' menjawab 'tidak.' Kredibilitas seorang jujur yang diakui bahkan oleh musuh."
        ),
        QuizQuestion(
            question = "Apa yang bikin Muhammad ﷺ beda dari tokoh agama lain?",
            options = listOf(
                "Dia lebih kaya dari tokoh lain",
                "Dia mengklaim langsung dapat pesan dari Tuhan dan jadi nabi terakhir untuk seluruh manusia",
                "Dia cuma ngajar satu kaum aja",
                "Dia gak punya kitab suci"
            ),
            correctIndex = 1,
            explanation = "Nabi mengklaim dapat pesan langsung dari Tuhan. Muhammad ﷺ spesial karena nabi TERAKHIR dan risalahnya buat seluruh manusia, bukan cuma satu kaum."
        ),
        QuizQuestion(
            question = "Meskipun jadi pemimpin negara dan panglima perang, hidup Muhammad ﷺ...",
            options = listOf(
                "Sangat mewah seperti raja",
                "Sederhana — kasur dari tikar, makan sering cuma kurma dan air",
                "Biasa aja, gak ada yang spesial",
                "Penuh harta rampasan perang"
            ),
            correctIndex = 1,
            explanation = "Meskipun punya kekuasaan besar, hidupnya tetap sederhana. Kekuasaannya gak dipake buat diri sendiri — ini beda banget dari raja atau diktator kebanyakan."
        ),
        QuizQuestion(
            question = "Apa hubungan antara karakter Muhammad ﷺ dengan kebenaran kerasulannya?",
            options = listOf(
                "Gak ada hubungannya",
                "Orang se-jujur itu gak mungkin ngarang soal Tuhan — karakternya jadi bukti kuat",
                "Yang penting cuma kitabnya",
                "Karakter gak penting, yang penting banyak pengikut"
            ),
            correctIndex = 1,
            explanation = "Muhammad ﷺ jujur sebelum jadi nabi, jujur sesudah jadi nabi. Konsistensi karakternya selama puluhan tahun jadi argumen kuat: orang se-jujur ini gak mungkin bohong soal Tuhan."
        )
    )

    // ═══════════════════════════════════════════
    // ARTIKEL: AKIDAH 1.5 — Apa Itu Iman dan Rukun Iman?
    // ═══════════════════════════════════════════
    private val akidah1_5Article = listOf(
        ArticleBlock.Heading("Apa Itu Iman dan Rukun Iman?"),
        ArticleBlock.Paragraph(
            "Keren! Kamu udah sampai di modul terakhir kategori Akidah. " +
            "Di 4 modul sebelumnya, kita udah bahas: Tuhan itu ada, " +
            "Allah itu Esa, Al-Quran firman Tuhan, dan Muhammad ﷺ utusan-Nya."
        ),
        ArticleBlock.Paragraph(
            "Sekarang kita rangkum semuanya jadi satu kerangka utuh: " +
            "Apa sih artinya \"beriman\"? Dan apa aja yang wajib dipercaya " +
            "seorang Muslim?"
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("✨ Apa Itu Iman?"),
        ArticleBlock.Paragraph(
            "Iman itu bukan cuma ngomong \"aku percaya.\" " +
            "Iman itu keyakinan di hati yang diucapkan lisan dan " +
            "dibuktikan lewat perbuatan. Tiga komponen: hati, lisan, " +
            "dan amal. Kalau cuma ngomong tapi gak yakin di hati? " +
            "Belum iman. Kalau yakin di hati tapi gak pernah " +
            "ngelakuin? Belum sempurna."
        ),
        ArticleBlock.Paragraph(
            "Dalam Islam, ada 6 hal yang wajib dipercaya. " +
            "Namanya Rukun Iman. \"Rukun\" artinya tiang penyangga — " +
            "kalau salah satu copot, bangunan iman goyah."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("1️⃣ Percaya kepada Allah"),
        ArticleBlock.Paragraph(
            "Ini fondasi dari semuanya. Percaya Allah itu ada, " +
            "Esa, punya sifat-sifat sempurna, dan Dia satu-satunya " +
            "yang layak disembah. Tanpa ini, yang lain gak ada artinya. " +
            "Udah kita bahas panjang lebar di modul 1.1 dan 1.2."
        ),
        ArticleBlock.Highlight(
            "Percaya Allah = percaya ada Perancang, dan Dia layak " +
            "jadi pusat hidupmu."
        ),
        ArticleBlock.Subheading("2️⃣ Percaya kepada Malaikat"),
        ArticleBlock.Paragraph(
            "Malaikat itu makhluk dari cahaya yang diciptakan Allah. " +
            "Mereka gak punya nafsu, gak pernah durhaka, " +
            "dan selalu patuh. Kenapa penting percaya? " +
            "Karena mereka punya tugas penting: nyampein wahyu, " +
            "mencatat amal, mendoain orang baik, dan banyak lagi. " +
            "Mereka bukti kalau alam ini lebih luas dari yang keliatan mata."
        ),
        ArticleBlock.Subheading("3️⃣ Percaya kepada Kitab-kitab"),
        ArticleBlock.Paragraph(
            "Allah pernah ngasih petunjuk ke manusia lewat " +
            "beberapa kitab: Taurat (ke Nabi Musa), Zabur (ke Nabi Daud), " +
            "Injil (ke Nabi Isa), dan Al-Quran (ke Nabi Muhammad ﷺ). " +
            "Percaya kitab-kitab = percaya Allah itu konsisten ngasih " +
            "petunjuk dari dulu. Tapi yang terakhir dan terjaga " +
            "keasliannya adalah Al-Quran."
        ),
        ArticleBlock.Subheading("4️⃣ Percaya kepada Rasul-rasul"),
        ArticleBlock.Paragraph(
            "Allah gak ninggalin manusia sendirian. Dia ngasih " +
            "contoh nyata lewat para rasul — manusia biasa yang " +
            "dipilih buat nyampein pesan-Nya. Dari Nabi Adam sampai " +
            "Nabi Muhammad ﷺ, semuanya manusia, bukan Tuhan. " +
            "Percaya rasul = percaya Allah peduli dan ngasih " +
            "panutan yang bisa diteladani."
        ),
        ArticleBlock.Subheading("5️⃣ Percaya kepada Hari Akhir"),
        ArticleBlock.Paragraph(
            "Hidup di dunia ini gak selamanya. Akan ada hari " +
            "di mana semuanya berakhir, dan semua perbuatan " +
            "akan dihitung. Percaya Hari Akhir = percaya bahwa " +
            "apa yang kamu lakuin sekarang ada konsekuensinya. " +
            "Ini bikin hidup lebih bermakna: gak sekadar hidup " +
            "buat senang-senang, tapi ada tujuan jangka panjang."
        ),
        ArticleBlock.Subheading("6️⃣ Percaya kepada Qada dan Qadar"),
        ArticleBlock.Paragraph(
            "Qada dan Qadar itu takdir dari Allah — " +
            "semua yang terjadi udah dalam pengetahuan dan kehendak-Nya. " +
            "Tapi ini BUKAN berarti kamu pasif. " +
            "Justru karena Allah udah tahu segalanya, " +
            "kamu tetep HARUS berusaha. Hasilnya? " +
            "Itu urusan Allah. Yang penting kamu udah ngelakuin bagianmu."
        ),
        ArticleBlock.Highlight(
            "Qadar itu kayak GPS: rute udah ditentukan, " +
            "tapi kamu tetep harus nyetir mobilnya."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("💡 Rangkuman Kategori Akidah"),
        ArticleBlock.Paragraph(
            "Lima modul ini adalah fondasi kepercayaan seorang Muslim: " +
            "Tuhan ada → Allah Esa → Al-Quran firman-Nya → " +
            "Muhammad ﷺ utusan-Nya → dan ada 6 pilar iman " +
            "yang jadi penyangga."
        ),
        ArticleBlock.Paragraph(
            "Kalau kamu udah paham ini, kamu udah punya dasar " +
            "yang kuat. Sekarang waktunya naik level: dari \"percaya\" " +
            "ke \"ngelakuin.\""
        ),
        ArticleBlock.Cta(
            "Kategori Akidah selesai! 🎉 Sekarang lanjut ke tab \"Rukun Islam\" " +
            "buat belajar 5 pilar yang jadi aksi nyata seorang Muslim. " +
            "Kamu udah di jalur yang bener! 🚀"
        )
    )

    private val akidah1_5Quiz = listOf(
        QuizQuestion(
            question = "Iman itu terdiri dari berapa komponen, apa aja?",
            options = listOf(
                "Cuma 1: percaya di hati aja",
                "2: hati dan lisan",
                "3: hati (keyakinan), lisan (ucapan), dan amal (perbuatan)",
                "4: hati, lisan, amal, dan doa"
            ),
            correctIndex = 2,
            explanation = "Iman itu tiga komponen: keyakinan di hati, diucapkan lewat lisan, dan dibuktikan lewat perbuatan. Kalau cuma satu aja, belum sempurna."
        ),
        QuizQuestion(
            question = "Kenapa percaya kepada Malaikat itu penting?",
            options = listOf(
                "Karena malaikat itu lucu",
                "Karena mereka bukti alam ini lebih luas dari yang keliatan mata, dan mereka punya tugas penting dari Allah",
                "Karena semua orang percaya",
                "Karena malaikat bisa ngasih uang"
            ),
            correctIndex = 1,
            explanation = "Malaikat punya tugas penting: nyampein wahyu, mencatat amal, mendoain orang baik. Mereka bukti kalau ada dimensi lain di luar yang bisa kita lihat."
        ),
        QuizQuestion(
            question = "Apa bedanya kitab-kitab sebelumnya dengan Al-Quran?",
            options = listOf(
                "Gak ada bedanya",
                "Al-Quran lebih pendek",
                "Al-Quran adalah kitab terakhir dan terjaga keasliannya 100%",
                "Kitab sebelumnya lebih penting"
            ),
            correctIndex = 2,
            explanation = "Allah ngasih petunjuk lewat beberapa kitab. Tapi yang terakhir dan terjaga 100% keasliannya adalah Al-Quran. Kitab sebelumnya udah mengalami perubahan seiring waktu."
        ),
        QuizQuestion(
            question = "Apa arti percaya Hari Akhir dalam kehidupan sehari-hari?",
            options = listOf(
                "Biar takut sama neraka aja",
                "Bikin hidup lebih bermakna — perbuatan ada konsekuensi, bukan sekadar senang-senang",
                "Gak ngaruh ke kehidupan",
                "Biar rajin sedekah aja"
            ),
            correctIndex = 1,
            explanation = "Percaya Hari Akhir bikin hidup lebih bermakna. Kamu tahu apa yang kamu lakuin sekarang ada konsekuensinya — jadi hidup gak sekadar buat senang-senang."
        ),
        QuizQuestion(
            question = "Qada dan Qadar (takdir) berarti kamu pasif dan gak usah usaha?",
            options = listOf(
                "Iya, karena udah ditentukan",
                "Engga — justru kamu WAJIB berusaha, hasilnya serahkan ke Allah",
                "Tergantung mood",
                "Cuma buat hal besar aja, hal kecil gak usah"
            ),
            correctIndex = 1,
            explanation = "Qadar itu kayak GPS: rute udah ditentukan, tapi kamu tetep harus nyetir. Kamu WAJIB berusaha — yang penting udah ngelakuin bagianmu, hasilnya urusan Allah."
        )
    )

    // ═══════════════════════════════════════════
    // ARTIKEL: RUKUN ISLAM 2.1 — 5 Rukun Islam: Fondasi Hidup Seorang Muslim
    // ═══════════════════════════════════════════
    private val rukun2_1Article = listOf(
        ArticleBlock.Heading("5 Rukun Islam: Fondasi Hidup Seorang Muslim"),
        ArticleBlock.Paragraph(
            "Oke, sekarang kamu udah paham soal dasar kepercayaan (Akidah). " +
            "Sekarang pertanyaannya: kalau udah percaya, terus ngapain? " +
            "Jawabannya ada di Rukun Islam."
        ),
        ArticleBlock.Paragraph(
            "Rukun Islam itu 5 hal yang jadi FONDASI hidup seorang Muslim. " +
            "\"Rukun\" artinya tiang penopang — kalau satu copot, " +
            "bangunan goyah. Kelimanya saling ngisi, gak bisa pilih-pilih."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("1️⃣ Syahadat — \"Aku Bersaksi\""),
        ArticleBlock.Paragraph(
            "Ini gerbang masuk Islam. Dua kalimat syahadat: " +
            "bersaksi bahwa gak ada Tuhan selain Allah, dan Muhammad ﷺ utusan Allah. " +
            "Bukan cuma diucapkan — tapi diyakini di hati. " +
            "Ini komitmen seumur hidup, bukan sekadar kata-kata."
        ),
        ArticleBlock.Highlight(
            "Syahadat itu kayak \"terms & conditions\" — " +
            "tapi yang beneran kamu baca dan setujuin, bukan langsung klik \"accept.\""
        ),
        ArticleBlock.Subheading("2️⃣ Sholat — 5 Waktu Sehari"),
        ArticleBlock.Paragraph(
            "Sholat itu cara ngobrol langsung sama Allah, 5 kali sehari. " +
            "Subuh, Dzuhur, Ashar, Maghrib, Isya. " +
            "Bukan ritual kosong — ada gerakan, bacaan, dan makna di tiap langkah. " +
            "Ini \"appointment\" tetap kamu sama Tuhan. " +
            "Gak bisa di-delegate, gak bisa di-skip."
        ),
        ArticleBlock.Subheading("3️⃣ Zakat — Berbagi dari Harta"),
        ArticleBlock.Paragraph(
            "Kalau udah punya harta yang cukup (nisab), " +
            "wajib ngasih 2.5% ke yang membutuhkan. " +
            "Bukan pajak — ini pembersihan harta. " +
            "Konsepnya: harta yang kamu punya gak 100% milikmu, " +
            "ada hak orang lain di situ. Zakat bikin harta berkah."
        ),
        ArticleBlock.Subheading("4️⃣ Puasa (Ramadan) — Tahan Lapar, Tahan Diri"),
        ArticleBlock.Paragraph(
            "Setiap Ramadan, umat Islam puasa dari terbit sampai terbenam matahari. " +
            "Gak cuma tahan makan dan minum — tapi juga tahan emosi, " +
            "gossip, dan hal-hal negatif. Tujuannya: melatih disiplin, " +
            "empati sama yang kurang mampu, dan deketin diri sama Allah. " +
            "Satu bulan penuh, setiap tahun."
        ),
        ArticleBlock.Subheading("5️⃣ Haji — Sekali Seumur Hidup"),
        ArticleBlock.Paragraph(
            "Kalau mampu (secara fisik dan finansial), " +
            "wajib ke Makkah sekali seumur hidup. " +
            "Ini ibadah terbesar — jutaan orang dari seluruh dunia " +
            "berkumpul di satu tempat, pakai baju yang sama, " +
            "ibadah yang sama. Gak ada bedanya kaya-miskin, " +
            "bos-karyawan. Semuanya sama di depan Allah."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("💡 Kenapa 5, Bukan 3 atau 7?"),
        ArticleBlock.Paragraph(
            "Lima rukun ini udah ditetapkan langsung oleh Nabi Muhammad ﷺ. " +
            "Masing-masing ngisi aspek kehidupan yang berbeda: " +
            "Syahadat = hati, Sholat = waktu, Zakat = harta, " +
            "Puasa = nafsu, Haji = fisik. " +
            "Lengkap. Gak kurang, gak lebih."
        ),
        ArticleBlock.Paragraph(
            "Di modul-modul berikutnya, kita bakal bahas satu per satu " +
            "secara detail — mulai dari Syahadat di modul selanjutnya. " +
            "Stay tuned!"
        ),
        ArticleBlock.Cta(
            "Kamu udah paham overview-nya! Sekarang jawab kuis buat klaim XP. 🎯"
        )
    )

    private val rukun2_1Quiz = listOf(
        QuizQuestion(
            question = "\"Rukun Islam\" artinya apa?",
            options = listOf(
                "Aturan Islam yang bisa dipilih-pilih",
                "5 tiang penopang yang jadi fondasi — kalau satu copot, bangunan goyah",
                "Anjuran saja, gak wajib",
                "Hanya untuk orang yang rajin ibadah"
            ),
            correctIndex = 1,
            explanation = "Rukun artinya tiang penopang. Kelimanya wajib dan saling ngisi — gak bisa pilih-pilih."
        ),
        QuizQuestion(
            question = "Apa fungsi Sholat dalam kehidupan seorang Muslim?",
            options = listOf(
                "Cuma buat ngilangin capek",
                "Cara ngobrol langsung sama Allah, 5 kali sehari — appointment tetap yang gak bisa di-skip",
                "Biar dibilang rajin sama orang",
                "Cuma wajib kalau lagi mood"
            ),
            correctIndex = 1,
            explanation = "Sholat itu \"appointment\" tetap kamu sama Tuhan — 5 kali sehari, gak bisa di-delegate atau di-skip."
        ),
        QuizQuestion(
            question = "Zakat itu beda dari pajak karena...",
            options = listOf(
                "Sama aja, cuma beda nama",
                "Zakat itu pembersihan harta — ada hak orang lain di hartamu, bikin harta berkah",
                "Zakat lebih mahal dari pajak",
                "Zakat cuma buat orang kaya"
            ),
            correctIndex = 1,
            explanation = "Zakat bukan pajak — ini pembersihan harta. Konsepnya: hartamu gak 100% milikmu, ada hak orang lain di situ."
        ),
        QuizQuestion(
            question = "Puasa Ramadan itu tujuannya bukan cuma tahan lapar, tapi juga...",
            options = listOf(
                "Biar kurus",
                "Melatih disiplin, empati sama yang kurang mampu, dan deketin diri sama Allah",
                "Biar bisa makan enak pas buka",
                "Cuma tradisi tahunan"
            ),
            correctIndex = 1,
            explanation = "Puasa melatih disiplin dan empati. Bukan cuma tahan makan — tapi juga tahan emosi, gossip, dan hal negatif."
        ),
        QuizQuestion(
            question = "Kapan wajib Haji?",
            options = listOf(
                "Setiap tahun wajib",
                "Wajib sekali seumur hidup, kalau mampu secara fisik dan finansial",
                "Cuma buat orang tua aja",
                "Gak wajib, cuma sunnah"
            ),
            correctIndex = 1,
            explanation = "Haji wajib sekali seumur hidup kalau mampu. Di sana, jutaan orang dari seluruh dunia berkumpul — gak ada bedanya kaya-miskin."
        )
    )

    // ═══════════════════════════════════════════
    // ARTIKEL: RUKUN ISLAM 2.2 — Syahadat: Gerbang Pertama
    // ═══════════════════════════════════════════
    private val rukun2_2Article = listOf(
        ArticleBlock.Heading("Syahadat: Gerbang Pertama"),
        ArticleBlock.Paragraph(
            "\"Laa ilaaha illallah, Muhammadur Rasulullah.\" " +
            "Kamu pasti pernah dengar kalimat ini. Tapi apa artinya sebenernya? " +
            "Dan kenapa ini jadi rukun pertama?"
        ),
        ArticleBlock.Paragraph(
            "Syahadat itu bukan mantra. Bukan jimat. " +
            "Ini deklarasi — pernyataan resmi dari hati bahwa kamu " +
            "memilih jalan hidup tertentu. Yuk kita bedah satu per satu."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("📜 Kalimat Pertama: Laa Ilaaha Illallah"),
        ArticleBlock.Paragraph(
            "\"Tidak ada Tuhan (yang layak disembah) selain Allah.\" " +
            "Ini inti dari Tauhid yang udah kita bahas di modul 1.2. " +
            "Bukan cuma bilang \"Tuhan itu ada\" — tapi juga \"Dia aja " +
            "yang layak aku sembah dan taati.\""
        ),
        ArticleBlock.Paragraph(
            "Implikasinya: kamu gak boleh menyembah selain Allah. " +
            "Gak boleh takut sama selain Allah lebih dari takut sama-Nya. " +
            "Gak boleh bergantung sama selain Allah lebih dari bergantung " +
            "sama-Nya. Ini soal prioritas hidup."
        ),
        ArticleBlock.Highlight(
            "Laa ilaaha illallah = \"Yang nomor satu dalam hidupku " +
            "adalah Allah. Bukan duit, bukan jabatan, bukan orang lain.\""
        ),
        ArticleBlock.Subheading("📜 Kalimat Kedua: Muhammadur Rasulullah"),
        ArticleBlock.Paragraph(
            "\"Muhammad ﷺ adalah utusan Allah.\" " +
            "Ini artinya kamu percaya Muhammad ﷺ beneran diutus " +
            "oleh Allah buat jadi contoh hidup. " +
            "Dan kalau percaya, konsekuensinya: ikutin ajarannya."
        ),
        ArticleBlock.Paragraph(
            "Bayangin: kamu punya mentor yang udah terbukti " +
            "jujur, cerdas, dan peduli. Kamu percaya dia. " +
            "Maka kamu ikutin saran dia. Logis kan? " +
            "Sama halnya dengan Muhammad ﷺ — kalau beneran percaya " +
            "dia utusan Tuhan, maka ikutin ajarannya."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("⚡ Konsekuensi Logis"),
        ArticleBlock.Paragraph(
            "Syahadat itu bukan cuma ucapan — tapi komitmen. " +
            "Begitu kamu ngucapin dan yakinin, ada konsekuensi logis:"
        ),
        ArticleBlock.Paragraph(
            "• Kamu berkomitmen menyembah Allah aja — " +
            "sholat, berdoa, bersyukur, semuanya ke Allah."
        ),
        ArticleBlock.Paragraph(
            "• Kamu berkomitmen ngikutin ajaran Nabi ﷺ — " +
            "cara hidup yang udah dia contohin."
        ),
        ArticleBlock.Paragraph(
            "• Kamu berkomitmen ninggalin yang dilarang — " +
            "bukan karena takut hukuman, tapi karena kamu " +
            "percaya Allah lebih tahu apa yang terbaik buat kamu."
        ),
        ArticleBlock.Paragraph(
            "Ini kayak kontrak seumur hidup — tapi kontrak " +
            "yang bikin hidupmu lebih terarah dan bermakna."
        ),
        ArticleBlock.Highlight(
            "Syahadat itu bukan \"slesai\" begitu diucapkan. " +
            "Itu titik awal. Perjalanan baru aja dimulai."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("💡 Kenapa Ini Rukun Pertama?"),
        ArticleBlock.Paragraph(
            "Karena tanpa syahadat, 4 rukun yang lain gak punya dasar. " +
            "Sholat tanpa percaya Allah? Cuma gerakan kosong. " +
            "Zakat tanpa komitmen? Cuma buang duit. " +
            "Puasa tanpa tauhid? Cuma diet. " +
            "Haji tanpa iman? Cuma jalan-jalan."
        ),
        ArticleBlock.Paragraph(
            "Syahadat itu fondasinya. Yang bikin semua ibadah " +
            "punya makna. Dan yang bikin kamu jadi Muslim."
        ),
        ArticleBlock.Cta(
            "Selesai baca! Kuis waktunya tiba. 🎯"
        )
    )

    private val rukun2_2Quiz = listOf(
        QuizQuestion(
            question = "Apa arti \"Laa ilaaha illallah\"?",
            options = listOf(
                "Tuhan itu ada",
                "Tidak ada Tuhan (yang layak disembah) selain Allah",
                "Allah itu Maha Kuasa",
                "Muhammad utusan Allah"
            ),
            correctIndex = 1,
            explanation = "Bukan cuma bilang 'Tuhan ada' — tapi juga 'Dia aja yang layak aku sembah dan taati.' Ini soal prioritas hidup."
        ),
        QuizQuestion(
            question = "Apa konsekuensi mengucapkan \"Muhammadur Rasulullah\"?",
            options = listOf(
                "Cuma tahu sejarah Nabi",
                "Percaya Muhammad ﷺ utusan Allah DAN berkomitmen ikutin ajarannya",
                "Cuma baca Al-Quran aja",
                "Gak ada konsekuensi"
            ),
            correctIndex = 1,
            explanation = "Kalau beneran percaya dia utusan Tuhan, maka logisnya: ikutin ajarannya. Kayak percaya sama mentor — pasti ikutin saran dia."
        ),
        QuizQuestion(
            question = "\"Laa ilaaha illallah\" dalam kehidupan sehari-hari artinya...",
            options = listOf(
                "Cuma diucapkan pas sholat",
                "Yang nomor satu dalam hidup adalah Allah — bukan duit, jabatan, atau orang lain",
                "Gak boleh kerja keras",
                "Cuma boleh sembahyang di masjid"
            ),
            correctIndex = 1,
            explanation = "Laa ilaaha illallah = prioritas hidup. Gak boleh takut/bergantung sama selain Allah lebih dari-Nya."
        ),
        QuizQuestion(
            question = "Kenapa Syahadat jadi rukun PERTAMA?",
            options = listOf(
                "Karena paling gampang",
                "Karena tanpa syahadat, 4 rukun lainnya gak punya dasar dan makna",
                "Karena urutannya dari yang paling penting ke paling gak penting",
                "Karena Nabi ngucapin duluan"
            ),
            correctIndex = 1,
            explanation = "Sholat tanpa percaya Allah = gerakan kosong. Zakat tanpa komitmen = buang duit. Syahadat adalah fondasi yang bikin semua ibadah punya makna."
        ),
        QuizQuestion(
            question = "Syahadat itu akhir dari perjalanan spiritual?",
            options = listOf(
                "Iya, selesai begitu diucapkan",
                "Engga — itu titik awal. Perjalanannya baru dimulai.",
                "Tergantung orangnya",
                "Cuma formalitas aja"
            ),
            correctIndex = 1,
            explanation = "Syahadat bukan finish line — itu starting line. Komitmen seumur hidup yang baru aja dimulai."
        )
    )

    // ═══════════════════════════════════════════
    // ARTIKEL: RUKUN ISLAM 2.3 — Kenapa Harus Puasa Ramadan?
    // ═══════════════════════════════════════════
    private val rukun2_3Article = listOf(
        ArticleBlock.Heading("Kenapa Harus Puasa Ramadan?"),
        ArticleBlock.Paragraph(
            "Setiap tahun, umat Islam di seluruh dunia berhenti makan " +
            "dan minum dari subuh sampai maghrib selama satu bulan penuh. " +
            "Kedengerannya berat? Emang. Tapi ada alasan kuat di baliknya."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("🧘 Manfaat Spiritual: Latihan Self-Control"),
        ArticleBlock.Paragraph(
            "Inti puasa itu bukan \"tahan lapar.\" Intinya: " +
            "latihan ngendaliin diri. Kamu pengen makan? Tahan. " +
            "Kamu pengen marah? Tahan. Kamu pengen gossip? Tahan."
        ),
        ArticleBlock.Paragraph(
            "Bayangin: kalau kamu bisa ngendaliin keinginan yang PALING " +
            "dasar (makan dan minum), maka kamu juga bisa ngendaliin " +
            "keinginan yang lebih kompleks — emosi, nafsu, ambisi. " +
            "Puasa itu gym-nya jiwa."
        ),
        ArticleBlock.Highlight(
            "Puasa itu bukan soal \"gak makan.\" Tapi soal: \"siapa " +
            "yang pegang kendali — nafsu atau kamu?\""
        ),
        ArticleBlock.Subheading("🤝 Empati sama yang Kurang Mampu"),
        ArticleBlock.Paragraph(
            "Kamu pernah ngerasain lapar beneran? " +
            "Bukan \"luput sarapan\" — tapi beneran gak makan seharian. " +
            "Puasa bikin kamu ngerasain apa yang dirasain orang " +
            "yang gak mampu makan setiap hari. " +
            "Dari situ muncul empati — dan dorongan buat berbagi."
        ),
        ArticleBlock.Subheading("🏥 Manfaat Kesehatan (Secara Umum)"),
        ArticleBlock.Paragraph(
            "Banyak penelitian menunjukkan bahwa puasa intermiten " +
            "(yang polanya mirip puasa Ramadan) punya dampak positif " +
            "secara umum pada tubuh. Tapi ini bukan klaim medis — " +
            "setiap orang beda kondisinya. Yang jelas: " +
            "puasa Ramadan dirancang oleh Allah, dan Allah lebih tahu " +
            "apa yang terbaik buat hamba-Nya."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("📋 Siapa yang Wajib Puasa?"),
        ArticleBlock.Paragraph(
            "Semua Muslim yang udah baligh dan sehat wajib puasa. " +
            "Tapi ada keringanan untuk yang gak mampu:"
        ),
        ArticleBlock.Paragraph(
            "• Sakit — boleh gak puasa, tapi wajib qadha (ganti) " +
            "kalau udah sembuh."
        ),
        ArticleBlock.Paragraph(
            "• Musafir (perjalanan jauh) — boleh gak puasa, " +
            "wajib qadha juga."
        ),
        ArticleBlock.Paragraph(
            "• Hamil/menyusui — boleh gak puasa kalau khawatir " +
            "kebayi, qadha atau fidyah."
        ),
        ArticleBlock.Paragraph(
            "• Lansia/gak mampu permanen — gak wajib puasa, " +
            "cukup bayar fidyah (makan orang miskin per hari)."
        ),
        ArticleBlock.Highlight(
            "Islam itu fleksibel. Ada aturan, tapi ada keringanan. " +
            "Gak ada yang dipaksain di luar batas kemampuan."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("💡 Kesimpulan"),
        ArticleBlock.Paragraph(
            "Puasa Ramadan itu bukan hukuman — tapi pelatihan. " +
            "Melatih disiplin, empati, dan ketergantungan pada Allah. " +
            "Satu bulan penuh yang bikin 11 bulan sisanya lebih bermakna."
        ),
        ArticleBlock.Cta(
            "Selesai baca! Saatnya kuis. 🎯"
        )
    )

    private val rukun2_3Quiz = listOf(
        QuizQuestion(
            question = "Inti puasa Ramadan itu bukan cuma tahan lapar, tapi...",
            options = listOf(
                "Biar kurus sebelum Lebaran",
                "Latihan ngendaliin diri — emosi, nafsu, dan keinginan",
                "Cuma tradisi tahunan",
                "Biar bisa makan enak pas buka"
            ),
            correctIndex = 1,
            explanation = "Puasa itu gym-nya jiwa. Kalau kamu bisa ngendaliin keinginan paling dasar (makan), kamu juga bisa ngendaliin yang lebih kompleks."
        ),
        QuizQuestion(
            question = "Apa hubungan puasa dengan empati?",
            options = listOf(
                "Gak ada hubungannya",
                "Puasa bikin kamu ngerasain lapar yang dirasain orang gak mampu — muncul empati dan dorongan berbagi",
                "Empati itu cuma perasaan aja",
                "Puasa bikin kamu lupa sama orang miskin"
            ),
            correctIndex = 1,
            explanation = "Dengan ngerasain lapar beneran, kamu jadi lebih paham kondisi orang yang gak mampu makan setiap hari."
        ),
        QuizQuestion(
            question = "Kalau lagi sakit, wajib gak puasa Ramadan?",
            options = listOf(
                "Tetap wajib, gak boleh bolong",
                "Gak wajib — boleh gak puasa, tapi wajib qadha (ganti) kalau udah sembuh",
                "Gak wajib dan gak perlu ganti",
                "Tergantung dokter aja"
            ),
            correctIndex = 1,
            explanation = "Islam fleksibel. Sakit = boleh gak puasa. Tapi begitu sembuh, wajib ganti di hari lain."
        ),
        QuizQuestion(
            question = "Lansia yang gak mampu puasa permanen, solusinya apa?",
            options = listOf(
                "Tetap dipaksa puasa",
                "Gak wajib puasa, cukup bayar fidyah (makan orang miskin per hari)",
                "Gak perlu apa-apa",
                "Harus puasa setengah hari aja"
            ),
            correctIndex = 1,
            explanation = "Lansia/gak mampu permanen = gak wajib puasa, cukup fidyah. Islam gak memaksakan di luar batas kemampuan."
        ),
        QuizQuestion(
            question = "Puasa Ramadan itu hukuman atau pelatihan?",
            options = listOf(
                "Hukuman dari Allah",
                "Pelatihan — melatih disiplin, empati, dan ketergantungan pada Allah",
                "Cuma ritual aja",
                "Tergantung niatnya"
            ),
            correctIndex = 1,
            explanation = "Puasa itu pelatihan, bukan hukuman. Satu bulan yang bikin 11 bulan sisanya lebih bermakna."
        )
    )

    // ═══════════════════════════════════════════
    // ARTIKEL: RUKUN ISLAM 2.4 — Zakat: Kenapa Harus Berbagi?
    // ═══════════════════════════════════════════
    private val rukun2_4Article = listOf(
        ArticleBlock.Heading("Zakat: Kenapa Harus Berbagi?"),
        ArticleBlock.Paragraph(
            "Kamu udah dengar soal zakat di modul overview Rukun Islam. " +
            "Sekarang kita bedah lebih dalam: kenapa sih harus berbagi " +
            "dari harta yang udah susah payah kamu cari?"
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("🧹 Zakat = Pembersih Harta"),
        ArticleBlock.Paragraph(
            "Kata \"zakat\" sendiri artinya \"bersih\" dan \"tumbuh.\" " +
            "Konsepnya: harta yang kamu punya itu gak 100% milikmu. " +
            "Ada hak orang lain di situ — yang butuh, yang kurang mampu. " +
            "Dengan ngasih zakat, kamu \"bersihin\" hartamu dari hak mereka."
        ),
        ArticleBlock.Paragraph(
            "Bayangin: kamu punya gelas air yang terus dituang. " +
            "Kalau gak pernah dibagiin, gelasnya meluap dan tumpah. " +
            "Zakat itu bikin aliran tetap lancar — kamu terima, kamu bagikan, " +
            "dan hartamu jadi lebih berkah."
        ),
        ArticleBlock.Highlight(
            "Zakat bukan \"buang duit.\" Zakat investasi di akhirat " +
            "dan pembersihan harta di dunia."
        ),
        ArticleBlock.Subheading("📊 Beda Zakat, Infaq, dan Sedekah"),
        ArticleBlock.Paragraph(
            "Ketiganya sama-sama berbagi, tapi beda aturannya:"
        ),
        ArticleBlock.Paragraph(
            "• Zakat — WAJIB. Ada nisab (batas minimal harta) dan " +
            "haul (dimiliki setahun). Besarnya 2.5% dari harta. " +
            "Ada 8 golongan yang berhak menerima (asnaf)."
        ),
        ArticleBlock.Paragraph(
            "• Infaq — SUNNAH. Berbagi dari harta tanpa batasan " +
            "persentase. Bisa kapan saja, berapa saja, ke siapa saja."
        ),
        ArticleBlock.Paragraph(
            "• Sedekah — SUNNAH. Lebih luas dari infaq — " +
            "bukan cuma uang. Senyum aja udah sedekah. " +
            "Nolong orang, ngasih ilmu, bahkan buang duri dari jalan " +
            "itu sedekah."
        ),
        ArticleBlock.Subheading("🌍 Dampak Sosial: Kurangi Kesenjangan"),
        ArticleBlock.Paragraph(
            "Zakat itu sistem distribusi kekayaan yang unik. " +
            "Yang punya lebih → ngasih 2.5% → yang butuh terbantu. " +
            "Kalau semua orang yang mampu bayar zakat, " +
            "kesenjangan sosial bisa berkurang signifikan."
        ),
        ArticleBlock.Paragraph(
            "Ini bukan sosialisme ala Barat — ini sistem dari Allah. " +
            "Dan bedanya: zakat itu MOTIVASINYA cinta, bukan paksaan. " +
            "Kamu ngasih karena percaya itu hak mereka, " +
            "dan karena kamu sayang sama hartamu sendiri " +
            "(maunya yang bersih dan berkah)."
        ),
        ArticleBlock.Highlight(
            "Zakat: satu sistem yang bersihin hartamu " +
            "SEKALIGUS bantu sesama. Win-win."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("💡 Penutup"),
        ArticleBlock.Paragraph(
            "Zakat itu bukan beban — itu hak orang lain yang " +
            "dititipin di hartamu. Dan ketika kamu ngasih, " +
            "yang kamu \"bersihin\" bukan cuma hartamu — tapi juga hatimu."
        ),
        ArticleBlock.Cta(
            "Kamu udah paham soal zakat! Kuis waktunya. 🎯"
        )
    )

    private val rukun2_4Quiz = listOf(
        QuizQuestion(
            question = "Apa arti kata \"zakat\"?",
            options = listOf(
                "Pajak",
                "Bersih dan tumbuh",
                "Sedekah wajib",
                "Donasi"
            ),
            correctIndex = 1,
            explanation = "Zakat artinya 'bersih' dan 'tumbuh.' Konsepnya: bersihin hartamu dari hak orang lain, dan hartamu jadi lebih berkah."
        ),
        QuizQuestion(
            question = "Apa beda zakat, infaq, dan sedekah?",
            options = listOf(
                "Sama aja, cuma beda nama",
                "Zakat wajib (2.5%, ada nisab), infaq sunnah (berbagi harta), sedekah sunnah (lebih luas — senyum aja sedekah)",
                "Zakat paling sedikit, sedekah paling banyak",
                "Infaq yang paling wajib"
            ),
            correctIndex = 1,
            explanation = "Zakat = wajib dengan aturan ketat (2.5%, nisab, haul). Infaq = sunnah, berbagi harta. Sedekah = sunnah, lebih luas — bahkan senyum aja udah sedekah."
        ),
        QuizQuestion(
            question = "Kenapa zakat bisa kurangi kesenjangan sosial?",
            options = listOf(
                "Karena zakat bikin semua orang kaya",
                "Karena yang punya lebih ngasih 2.5% ke yang butuh — distribusi kekayaan secara alami",
                "Karena zakat itu wajib",
                "Karena zakat cuma buat orang kaya"
            ),
            correctIndex = 1,
            explanation = "Zakat = sistem distribusi kekayaan dari Allah. Yang mampu → ngasih 2.5% → yang butuh terbantu. Kalau semua patuh, kesenjangan berkurang signifikan."
        ),
        QuizQuestion(
            question = "Motivasi zakat yang benar itu apa?",
            options = listOf(
                "Takut dipenjara",
                "Cinta — percaya itu hak mereka, dan mau hartamu bersih dan berkah",
                "Biar dipuji orang",
                "Cuma kewajiban yang harus ditunaikan"
            ),
            correctIndex = 1,
            explanation = "Zakat motivasinya cinta, bukan paksaan. Kamu ngasih karena percaya itu hak mereka dan karena kamu sayang hartamu sendiri — mau yang bersih dan berkah."
        ),
        QuizQuestion(
            question = "Sedekah itu cuma soal uang?",
            options = listOf(
                "Iya, harus berupa uang",
                "Engga — senyum aja udah sedekah, nolong orang, ngasih ilmu, buang duri dari jalan",
                "Cuma berupa makanan",
                "Cuma buat orang kaya"
            ),
            correctIndex = 1,
            explanation = "Sedekah itu lebih luas dari uang. Senyum, nolong orang, ngasih ilmu, bahkan buang duri dari jalan — semua itu sedekah."
        )
    )

    // ═══════════════════════════════════════════
    // ARTIKEL: RUKUN ISLAM 2.5 — Haji: Perjalanan Sekali Seumur Hidup
    // ═══════════════════════════════════════════
    private val rukun2_5Article = listOf(
        ArticleBlock.Heading("Haji: Perjalanan Sekali Seumur Hidup"),
        ArticleBlock.Paragraph(
            "Ini rukun terakhir. Dan mungkin yang paling \"wow\" — " +
            "karena kamu harus beneran pergi ke satu tempat di " +
            "belahan dunia lain, bersama jutaan orang dari seluruh planet."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("🕋 Apa Itu Haji?"),
        ArticleBlock.Paragraph(
            "Haji itu ibadah ziarah ke Makkah, Arab Saudi. " +
            "Wajib sekali seumur hidup buat Muslim yang MAMPU " +
            "(secara fisik dan finansial). " +
            "Kalau belum mampu? Gak wajib. Simple."
        ),
        ArticleBlock.Paragraph(
            "Haji dilakukan setiap tanggal 8-12 Dzulhijjah " +
            "(bulan ke-12 kalender Islam). Ada rangkaian ibadah: " +
            "tawaf (keliling Ka'bah), sa'i (jalan bolak-balik), " +
            "wukuf di Arafah (puncak haji), melempar jumrah, " +
            "dan lain-lain."
        ),
        ArticleBlock.Subheading("👕 Ihram: Semua Sama Rata"),
        ArticleBlock.Paragraph(
            "Yang bikin haji beda dari ibadah lain: semua orang " +
            "pakai baju yang SAMA. Putih, tanpa jahitan, " +
            "gak ada merek, gak ada logo. " +
            "Namanya ihram."
        ),
        ArticleBlock.Paragraph(
            "Bayangin: Presiden, buruh, dokter, tukang ojek, " +
            "pengusaha — semuanya pakai baju yang sama. " +
            "Gak ada yang bisa pamer kekayaan. " +
            "Gak ada yang bisa pamer jabatan. " +
            "Di depan Allah, SEMUA SAMA."
        ),
        ArticleBlock.Highlight(
            "Ihram itu pengingat: di mata Allah, " +
            "yang membedakan kamu bukan harta atau jabatan — " +
            "tapi ketakwaanmu."
        ),
        ArticleBlock.Subheading("⚖️ Makna Simbolis Haji"),
        ArticleBlock.Paragraph(
            "Haji itu bukan sekadar perjalanan fisik. " +
            "Tiap ritual punya makna:"
        ),
        ArticleBlock.Paragraph(
            "• Tawaf (keliling Ka'bah 7x) — " +
            "hidupmu harus berpusat pada Allah, " +
            "seperti bumi yang mengelilingi matahari."
        ),
        ArticleBlock.Paragraph(
            "• Wukuf di Arafah — " +
            "pengingat Hari Kiamat, saat semua manusia " +
            "berkumpul di padang mahsyar."
        ),
        ArticleBlock.Paragraph(
            "• Melempar jumrah — " +
            "simbol nolak godaan setan, dari yang kecil sampai yang besar."
        ),
        ArticleBlock.Paragraph(
            "• Sa'i (lari bolak-balik Safa-Marwa) — " +
            "mengenang perjuangan Siti Hajar mencari air " +
            "untuk bayinya, Ismail. Simbol ketekunan dan tawakkal."
        ),
        ArticleBlock.Subheading("💰 Syarat Wajib Haji"),
        ArticleBlock.Paragraph(
            "Haji cuma wajib kalau kamu MAMPU. Artinya:"
        ),
        ArticleBlock.Paragraph(
            "• Fisik sehat — kuat jalan, berdiri, tahan cuaca panas. " +
            "Kalau sakit parah, gak wajib."
        ),
        ArticleBlock.Paragraph(
            "• Finansial cukup — punya biaya pergi DAN " +
            "keluarga di rumah tetap tercukupi. " +
            "Gak boleh haji tapi utang menumpuk."
        ),
        ArticleBlock.Paragraph(
            "• Aman perjalanannya — jalur ke Makkah aman."
        ),
        ArticleBlock.Highlight(
            "Haji itu wajib kalau mampu. " +
            "Kalau belum mampu, gak dosa. " +
            "Allah gak membebankan di luar batas kemampuan."
        ),
        ArticleBlock.Divider,
        ArticleBlock.Subheading("💡 Penutup Kategori Rukun Islam"),
        ArticleBlock.Paragraph(
            "Kelima rukun ini — Syahadat, Sholat, Puasa, Zakat, Haji — " +
            "adalah FONDASI hidup seorang Muslim. " +
            "Masing-masing ngisi aspek berbeda: hati, waktu, nafsu, " +
            "harta, dan fisik."
        ),
        ArticleBlock.Paragraph(
            "Kalau kamu udah paham Akidah dan Rukun Islam, " +
            "kamu udah punya kerangka yang kuat. " +
            "Sekarang waktunya masuk ke bagian praktisnya."
        ),
        ArticleBlock.Cta(
            "Kategori Rukun Islam selesai! 🎉 Lanjut ke tab \"Praktik Ibadah\" " +
            "buat belajar cara sholat dari nol. Kamu makin keren! 🚀"
        )
    )

    private val rukun2_5Quiz = listOf(
        QuizQuestion(
            question = "Kapan wajib haji?",
            options = listOf(
                "Setiap tahun wajib",
                "Sekali seumur hidup, kalau mampu secara fisik dan finansial",
                "Cuma buat orang tua",
                "Gak wajib, cuma sunnah"
            ),
            correctIndex = 1,
            explanation = "Haji wajib sekali seumur hidup TAPI cuma kalau mampu. Kalau belum mampu, gak dosa."
        ),
        QuizQuestion(
            question = "Kenapa semua jamaah haji pakai baju putih yang sama (ihram)?",
            options = listOf(
                "Karena murah",
                "Simbol kesetaraan — di depan Allah, semua sama, gak ada yang lebih karena harta atau jabatan",
                "Tradisi Arab aja",
                "Biar gampang nyari rombongan"
            ),
            correctIndex = 1,
            explanation = "Ihram = baju putih tanpa merek. Presiden, buruh, pengusaha — semua sama. Yang membedakan di mata Allah bukan harta, tapi ketakwaan."
        ),
        QuizQuestion(
            question = "Apa makna tawaf (keliling Ka'bah 7x)?",
            options = listOf(
                "Olahraga ringan",
                "Hidup harus berpusat pada Allah, seperti bumi mengelilingi matahari",
                "Cuma ritual tanpa makna",
                "Biar capek biar kurus"
            ),
            correctIndex = 1,
            explanation = "Tawaf = simbol hidup berpusat pada Allah. Seperti planet yang mengorbit — hidupmu harus berputar di sekitar-Nya."
        ),
        QuizQuestion(
            question = "Kalau belum mampu haji secara finansial, apa yang terjadi?",
            options = listOf(
                "Tetap wajib, harus pinjam uang",
                "Gak wajib — Allah gak membebankan di luar batas kemampuan",
                "Dosa besar",
                "Harus nabung 10 tahun dulu"
            ),
            correctIndex = 1,
            explanation = "Haji cuma wajib kalau mampu. Kalau belum mampu, gak dosa. Keluarga di rumah harus tetap tercukupi dulu."
        ),
        QuizQuestion(
            question = "Apa makna melempar jumrah saat haji?",
            options = listOf(
                "Main kelereng raksasa",
                "Simbol nolak godaan setan — dari yang kecil sampai yang besar",
                "Tradisi pra-Islam aja",
                "Biar seru-seruan"
            ),
            correctIndex = 1,
            explanation = "Melempar jumrah = simbol nolak godaan setan. Dari jumrah kecil, sedang, sampai besar — makin lama makin tegas nolaknya."
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
