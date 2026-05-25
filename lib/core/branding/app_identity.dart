import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/utils/crowd_hero_labels.dart';

/// نوع الفريق لطبقة الجمهور (ملعب + تصويت) — يُشتق من [FanAppIdentity.registryAppId].
enum CrowdTeamType {
  ahly,
  zamalek,
}

/// حزمة أصوات اختيارية — إن لم يوجد الملف في الـ assets يُتجاهل التشغيل بصمت.
class CrowdAudioPack {
  const CrowdAudioPack({
    required this.cheerAsset,
    required this.leaderStingAsset,
    required this.ambienceAsset,
    this.ambienceGain = 1.0,
    this.cheerGain = 1.0,
    this.leaderGain = 1.0,
    this.cheerPlaybackRate = 1.0,
    this.leaderPlaybackRate = 1.0,
  });

  final String cheerAsset;
  final String leaderStingAsset;
  final String ambienceAsset;
  /// مكاسب نسبية (0..1+) — أهلي: Bass-heavy؛ زمالك: High-clean.
  final double ambienceGain;
  final double cheerGain;
  final double leaderGain;
  final double cheerPlaybackRate;
  final double leaderPlaybackRate;
}

/// أسلوب جزيئات الملعب (سرعة/كثافة) — يُضبط من [CrowdMomentumTier].
class CrowdParticlesStyle {
  const CrowdParticlesStyle({
    required this.baseDensity,
    required this.maxDrift,
    required this.minSize,
    required this.maxSize,
  });

  final double baseDensity;
  final double maxDrift;
  final double minSize;
  final double maxSize;

  CrowdParticlesStyle lerpTo(CrowdParticlesStyle b, double t) {
    return CrowdParticlesStyle(
      baseDensity: baseDensity + (b.baseDensity - baseDensity) * t,
      maxDrift: maxDrift + (b.maxDrift - maxDrift) * t,
      minSize: minSize + (b.minSize - minSize) * t,
      maxSize: maxSize + (b.maxSize - maxSize) * t,
    );
  }
}

/// مستوى زخم التصويت (يؤثر على لون الملعب والجزيئات والتوهج).
enum CrowdMomentumTier {
  calm,
  warm,
  hot,
  inferno,
}

/// هوية بصرية/صوتية موحّدة لشاشة الجمهور — طبقة فوق نفس الـ widgets والـ logic.
class CrowdAppIdentity {
  const CrowdAppIdentity._({
    required this.appName,
    required this.teamType,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentGlow,
    required this.stadiumTheme,
    required this.audio,
    required this.glowPrimary,
    required this.glowSecondary,
    required this.pitchGradientTop,
    required this.pitchGradientBottom,
    required this.momentumTintCalm,
    required this.momentumTintWarm,
    required this.momentumTintHot,
    required this.momentumTintInferno,
    required this.particlesCalm,
    required this.particlesInferno,
    required this.votingTitle,
    required this.leaderBannerDominating,
    required this.reactionEmojiPrimary,
    required this.reactionEmojiSecondary,
  });

  final String appName;
  final CrowdTeamType teamType;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentGlow;
  final String stadiumTheme;
  final CrowdAudioPack audio;
  final Color glowPrimary;
  final Color glowSecondary;
  final Color pitchGradientTop;
  final Color pitchGradientBottom;
  final Color momentumTintCalm;
  final Color momentumTintWarm;
  final Color momentumTintHot;
  final Color momentumTintInferno;
  final CrowdParticlesStyle particlesCalm;
  final CrowdParticlesStyle particlesInferno;
  final String votingTitle;
  final String leaderBannerDominating;
  final String reactionEmojiPrimary;
  final String reactionEmojiSecondary;

  static CrowdAppIdentity get current {
    final ahly = FanAppIdentity.registryAppId == 'ahly';
    if (ahly) {
      return CrowdAppIdentity._(
        appName: 'جمهور الأهلي',
        teamType: CrowdTeamType.ahly,
        primaryColor: const Color(0xFFC8102E),
        secondaryColor: const Color(0xFFFFD700),
        accentGlow: const Color(0xFFFFD700),
        stadiumTheme: 'ahly_aggressive',
        audio: const CrowdAudioPack(
          cheerAsset: 'assets/sounds/nesr_cheer.mp3',
          leaderStingAsset: 'assets/sounds/nesr_cheer.mp3',
          ambienceAsset: 'assets/sounds/nesr_cheer.mp3',
          ambienceGain: 1.08,
          cheerGain: 1.06,
          leaderGain: 1.0,
          cheerPlaybackRate: 0.97,
          leaderPlaybackRate: 1.02,
        ),
        glowPrimary: const Color(0xFFFF4D4D),
        glowSecondary: const Color(0xFFFFD700),
        pitchGradientTop: const Color(0xFF120808),
        pitchGradientBottom: const Color(0xFF050A06),
        momentumTintCalm: const Color(0x00000000),
        momentumTintWarm: const Color(0x33C8102E),
        momentumTintHot: const Color(0x55C8102E),
        momentumTintInferno: const Color(0x88FFD700),
        particlesCalm: const CrowdParticlesStyle(
          baseDensity: 0.55,
          maxDrift: 14,
          minSize: 0.6,
          maxSize: 1.6,
        ),
        particlesInferno: const CrowdParticlesStyle(
          baseDensity: 1.35,
          maxDrift: 32,
          minSize: 1.0,
          maxSize: 3.2,
        ),
        votingTitle: CrowdHeroLabels.matchTitle,
        leaderBannerDominating: '🔥 النسر يكتسح التصويت',
        reactionEmojiPrimary: '🔥',
        reactionEmojiSecondary: '👏',
      );
    }
    return CrowdAppIdentity._(
      appName: 'زملكاوي',
      teamType: CrowdTeamType.zamalek,
      primaryColor: const Color(0xFFFFFFFF),
      secondaryColor: const Color(0xFF0D47A1),
      accentGlow: const Color(0xFF42A5F5),
      stadiumTheme: 'zamalek_royal',
      audio: const CrowdAudioPack(
        cheerAsset: 'assets/sounds/nesr_cheer.mp3',
        leaderStingAsset: 'assets/sounds/nesr_cheer.mp3',
        ambienceAsset: 'assets/sounds/nesr_cheer.mp3',
        ambienceGain: 0.88,
        cheerGain: 0.94,
        leaderGain: 1.05,
        cheerPlaybackRate: 1.02,
        leaderPlaybackRate: 1.04,
      ),
      glowPrimary: const Color(0xFFE3F2FD),
      glowSecondary: const Color(0xFF1565C0),
      pitchGradientTop: const Color(0xFF060A12),
      pitchGradientBottom: const Color(0xFF020508),
      momentumTintCalm: const Color(0x00000000),
      momentumTintWarm: const Color(0x331565C0),
      momentumTintHot: const Color(0x551E88E5),
      momentumTintInferno: const Color(0x88FFFFFF),
      particlesCalm: const CrowdParticlesStyle(
        baseDensity: 0.5,
        maxDrift: 12,
        minSize: 0.5,
        maxSize: 1.4,
      ),
      particlesInferno: const CrowdParticlesStyle(
        baseDensity: 1.25,
        maxDrift: 28,
        minSize: 0.9,
        maxSize: 2.8,
      ),
      votingTitle: CrowdHeroLabels.matchTitle,
      leaderBannerDominating: '🐎 الفارس يسيطر على الجماهير',
      reactionEmojiPrimary: '🐎',
      reactionEmojiSecondary: '⚡',
    );
  }

  Color momentumTint(CrowdMomentumTier tier) {
    switch (tier) {
      case CrowdMomentumTier.calm:
        return momentumTintCalm;
      case CrowdMomentumTier.warm:
        return momentumTintWarm;
      case CrowdMomentumTier.hot:
        return momentumTintHot;
      case CrowdMomentumTier.inferno:
        return momentumTintInferno;
    }
  }

  CrowdParticlesStyle particlesFor(CrowdMomentumTier tier) {
    final t = switch (tier) {
      CrowdMomentumTier.calm => 0.0,
      CrowdMomentumTier.warm => 0.35,
      CrowdMomentumTier.hot => 0.65,
      CrowdMomentumTier.inferno => 1.0,
    };
    return particlesCalm.lerpTo(particlesInferno, t);
  }

  TextStyle stadiumTitleStyle(double fontSize) {
    final w = teamType == CrowdTeamType.zamalek;
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: w ? 0.4 : 0.2,
      color: Colors.white,
      shadows: [
        Shadow(
          blurRadius: 14,
          color: primaryColor.withValues(alpha: w ? 0.35 : 0.55),
        ),
        const Shadow(blurRadius: 8, color: Colors.black87),
      ],
    );
  }

  /// لون خطوط الملعب التكتيكية في الـ overlay.
  Color get tacticalLineAccent =>
      teamType == CrowdTeamType.ahly ? const Color(0xFF39FF14) : const Color(0xFFFF6B2C);
}

/// يحسب طبقة الزخم من نسبة أصوات المتصدر.
CrowdMomentumTier crowdMomentumTierFromLeaderShare(double share) {
  if (share >= 0.75) return CrowdMomentumTier.inferno;
  if (share >= 0.50) return CrowdMomentumTier.hot;
  if (share >= 0.25) return CrowdMomentumTier.warm;
  return CrowdMomentumTier.calm;
}
