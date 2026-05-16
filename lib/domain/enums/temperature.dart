/// Per-item time-sensitivity, governing notification assertiveness
/// and frequency — SRS FR-3.4, FR-5.1.
///
/// Mapped to the three colored dots in PDD §4.3 / §9.2:
///   - [hot]  → red dot — hard-time items (medication, appointments, alarms)
///   - [warm] → amber dot — soft-deadline items ("this week", "by Friday")
///   - [cool] → green dot — drifting items ("sometime", "whenever")
///
/// Temperature is a property of the plan item, not of its time.
/// Two items can share the same time and have different temperatures —
/// "call mom by Friday" might be warm, "submit tax return by Friday"
/// might be hot.
enum Temperature {
  hot,
  warm,
  cool,
}