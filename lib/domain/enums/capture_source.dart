/// How an intention was captured — SRS FR-1.5 / §9.1.
enum CaptureSource {
  /// Typed via the keyboard in the conversation panel.
  typed,

  /// Spoken via the device microphone and transcribed by native STT.
  voice,

  /// Created directly via structured primitives, bypassing the parser
  /// (SRS FR-3.8). E.g. created from the "+" affordance on the project
  /// view to add a sub-item.
  manual,
}