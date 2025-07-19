enum ViewMode { list, grid }

enum InputType { textField, selection, datePicker, passwordChange }

enum TtsState { playing, stopped, paused, continued }

enum TimePeriod {
  months6(180, 'Last 6 months');

  final int days;
  final String displayName;

  const TimePeriod(this.days, this.displayName);
}
