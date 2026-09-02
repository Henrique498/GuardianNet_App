import 'package:flutter/material.dart';
import '../models/mock_data.dart'; // Importa o AlertLevel oficial

class AppColors {
  AppColors._();

  static const navy = Color(0xFF0F172A);
  static const navy2 = Color(0xFF1E293B);
  static const navy3 = Color(0xFF334155);

  static const azulPastel = Color(0xFFA5F3FC);
  static const verdePastel = Color(0xFF86EFAC);
  static const onGradient = Color(0xFF0F172A);

  static const perigo = Color(0xFFEF4444);
  static const atencao = Color(0xFFF97316);
  static const seguro = Color(0xFF86EFAC);

  static const branco = Color(0xFFF8FAFC);
  static const brancoDim = Color(0xFF94A3B8);

  // Corrigido para const real (Hex com 15% de opacidade já embutida)
  static const borda = Color(0x2694A3B8);

  static const gradienteBrand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [azulPastel, verdePastel],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.navy,
    primaryColor: AppColors.azulPastel,
    cardColor: AppColors.navy2,
    dividerColor: AppColors.borda,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.azulPastel,
      brightness: Brightness.dark,
      primary: AppColors.azulPastel,
      secondary: AppColors.verdePastel,
      error: AppColors.perigo,
      surface: AppColors.navy2,
    ),
    useMaterial3: true,
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.branco),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.branco),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.branco),
      bodyLarge: TextStyle(color: AppColors.branco),
      bodyMedium: TextStyle(color: AppColors.branco),
      bodySmall: TextStyle(color: AppColors.brancoDim),
    ),
  );

  static ThemeData get light => dark;
}

// ---------------------------------------------------------
// COMPONENTES GLOBAIS DE UI
// ---------------------------------------------------------

class AppLogo extends StatelessWidget {
  final double width;
  final double height;
  final bool glow;

  // Tamanhos padrões retangulares (ajuste os valores se precisar de outra proporção)
  const AppLogo({super.key, this.width = 160, this.height = 90, this.glow = false});

  static const String assetPath = 'lib/assests/images/logo.png';

  @override
  Widget build(BuildContext context) {
    // Usamos a altura como base para manter os arredondamentos e sombras proporcionais
    final double radiusBase = height;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radiusBase * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        border: Border.all(
          color: AppColors.azulPastel.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: glow
            ? [
          BoxShadow(
            color: AppColors.azulPastel.withOpacity(0.35),
            blurRadius: radiusBase * 0.6,
            spreadRadius: 1,
          ),
        ]
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radiusBase * 0.28),
        child: Image.asset(
          assetPath,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover, // Preenche todo o container perfeitamente
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Container(
            alignment: Alignment.center,
            child: Icon(
              Icons.shield_rounded,
              color: AppColors.azulPastel,
              size: radiusBase * 0.55,
            ),
          ),
        ),
      ),
    );
  }
}
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool glow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.navy2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borda),
        boxShadow: glow
            ? [
          BoxShadow(
            color: AppColors.azulPastel.withOpacity(0.12),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ]
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class LabelCaps extends StatelessWidget {
  final String text;
  final Color? color;
  const LabelCaps(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: color ?? AppColors.brancoDim,
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final habilitado = onPressed != null && !loading;
    return Opacity(
      opacity: habilitado ? 1 : 0.7,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: habilitado ? onPressed : null,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.gradienteBrand,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: loading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onGradient),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.onGradient, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.onGradient,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OutlineButtonCustom extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onPressed;

  const OutlineButtonCustom({super.key, required this.text, this.icon, this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cor = color ?? AppColors.branco;
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color != null ? color!.withOpacity(0.4) : AppColors.borda),
        backgroundColor: AppColors.navy3.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: icon != null ? Icon(icon, size: 16, color: cor) : const SizedBox.shrink(),
      label: Text(text, style: TextStyle(color: cor, fontSize: 13.5, fontWeight: FontWeight.w500)),
    );
  }
}

class GradientChip extends StatelessWidget {
  final String label;
  final bool ativo;
  final VoidCallback onTap;
  const GradientChip({super.key, required this.label, required this.ativo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: ativo ? AppColors.gradienteBrand : null,
          color: ativo ? null : AppColors.navy3.withOpacity(0.6),
          borderRadius: BorderRadius.circular(999),
          border: ativo ? null : Border.all(color: AppColors.borda),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: ativo ? AppColors.onGradient : AppColors.brancoDim,
          ),
        ),
      ),
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final bool solid;
  const InitialsAvatar({super.key, required this.initials, this.size = 40, this.solid = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: solid ? AppColors.gradienteBrand : null,
        color: solid ? null : AppColors.navy3,
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: size * 0.35,
          color: solid ? AppColors.onGradient : AppColors.azulPastel,
        ),
      ),
    );
  }
}

class RiskBadge extends StatelessWidget {
  final AlertLevel risk;
  const RiskBadge({super.key, required this.risk});

  Color get _cor {
    switch (risk) {
      case AlertLevel.seguro:
        return AppColors.seguro;
      case AlertLevel.atencao:
        return AppColors.atencao;
      case AlertLevel.perigo:
        return AppColors.perigo;
    }
  }

  String get _label {
    switch (risk) {
      case AlertLevel.seguro:
        return 'Seguro';
      case AlertLevel.atencao:
        return 'Atenção';
      case AlertLevel.perigo:
        return 'Perigo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = _cor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cor.withOpacity(0.35)),
      ),
      child: Text(_label, style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}