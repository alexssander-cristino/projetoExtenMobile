class PrescriptionResult {
  final String patientName;
  final String prontuario;
  final double weightKg;
  final String category;
  final double recommendedTDD;
  final double basalUnits;
  final double prandialUnits;
  final bool useNPH;
  final double nphMorning;
  final double nphNight;
  final bool preferIV;
  final double isf;
  final List<CorrectionStep> slidingScale;
  final IntRange targetRange;
  final int hypoAlert;
  final int hypoSignificant;
  final String notes;

  PrescriptionResult({
    required this.patientName,
    required this.prontuario,
    required this.weightKg,
    required this.category,
    required this.recommendedTDD,
    required this.basalUnits,
    required this.prandialUnits,
    required this.useNPH,
    required this.nphMorning,
    required this.nphNight,
    required this.preferIV,
    required this.isf,
    required this.slidingScale,
    required this.targetRange,
    required this.hypoAlert,
    required this.hypoSignificant,
    required this.notes,
  });
}

class CorrectionStep {
  final IntRange range;
  final int units;
  CorrectionStep({required this.range, required this.units});
}

class IntRange {
  final int min;
  final int max;
  IntRange(this.min, this.max);
}
