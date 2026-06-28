import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'belajar_quiz.dart';

/// Belajar Article — long-form reading view with hero + body + start-quiz CTA.
class BelajarArticleScreen extends StatelessWidget {
  const BelajarArticleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background.withValues(alpha: 0.9),
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'MODUL 1',
              style: AppText.labelCaps().copyWith(color: AppColors.primary),
            ),
            centerTitle: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Mengenal Allah',
                  style: AppText.displayHero(32).copyWith(
                    color: AppColors.onSurface,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AKIDAH',
                        style: AppText.labelCaps().copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '10 menit baca',
                      style: AppText.bodyMd().copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.bookmark_border,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _heroImage(),
                const SizedBox(height: AppSpacing.lg),
                _section(
                  'Pendahuluan',
                  'Mengenal Allah adalah fondasi utama dalam beragama Islam. '
                  'Seorang Muslim yang bertaqwa harus memiliki pemahaman yang kuat '
                  'mengenai siapa Allah, bagaimana sifat-sifat-Nya, dan bagaimana '
                  'cara berinteraksi dengan-Nya.',
                ),
                _section(
                  'Sifat Wajib Allah',
                  'Sifat wajib bagi Allah adalah sifat yang pasti ada pada-Nya. '
                  'Ada 20 sifat wajib Allah yang harus kita imani, di antaranya: '
                  'Wujud (Ada), Qidam (Terdahulu), Baqa\' (Kekal), Mukhalafatu '
                  'lil hawaditsi (Berbeda dengan makhluk), Qiyamuhu binafsihi '
                  '(Berdiri sendiri), dan Wahdaniyyah (Maha Esa).',
                ),
                _quoteBox(
                  '"Tidak ada Tuhan yang berhak disembah selain Allah, '
                  'dan Muhammad adalah utusan Allah."',
                  '— Syahadat',
                ),
                _section(
                  'Sifat Mustahil Allah',
                  'Sebaliknya, sifat mustahil adalah sifat yang tidak mungkin '
                  'ada pada Allah. Ini adalah kebalikan dari sifat wajib, '
                  'misalnya: Tidak ada, Baru, Musnah, dan Berlebih-lebihan.',
                ),
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: HeroButton(
            label: 'MULAI QUIZ',
            trailingIcon: Icons.play_arrow,
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const BelajarQuizScreen()),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _heroImage() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.tertiary.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_stories,
          size: 80,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.titleLg()),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: AppText.bodyLg().copyWith(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _quoteBox(String quote, String source) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border(
          left: BorderSide(
            color: AppColors.secondaryFixed,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quote,
            style: AppText.bodyLg().copyWith(
              color: AppColors.secondaryFixed,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            source,
            style: AppText.labelCaps().copyWith(
              color: AppColors.secondaryContainer,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
