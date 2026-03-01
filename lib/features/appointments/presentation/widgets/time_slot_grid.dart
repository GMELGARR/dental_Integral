import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/appointment.dart';

/// Visual representation of a single 30-minute time slot.
enum SlotState { available, occupied, past }

/// Data for a single time slot.
class TimeSlot {
  const TimeSlot({
    required this.hora,
    required this.state,
    this.appointmentLabel,
  });

  /// "HH:mm" formatted time.
  final String hora;
  final SlotState state;

  /// Short label when occupied (e.g. patient name).
  final String? appointmentLabel;
}

/// Displays a grid of 30-minute time slots for a specific odontólogo + date.
///
/// Green = available (tappable) · Red = occupied · Grey = past.
class TimeSlotGrid extends StatelessWidget {
  const TimeSlotGrid({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
    this.odontologoNombre,
    this.fechaLabel,
  });

  final List<TimeSlot> slots;
  final String? selectedSlot;
  final ValueChanged<String> onSlotSelected;
  final String? odontologoNombre;
  final String? fechaLabel;

  /// Build the slot list from schedule + existing appointments.
  static List<TimeSlot> buildSlots({
    required String horaInicio,
    required String horaFin,
    required DateTime fecha,
    required List<Appointment> existingAppointments,
    int slotMinutes = 30,
  }) {
    final start = _parseTime(horaInicio);
    final end = _parseTime(horaFin);
    final now = DateTime.now();
    final isToday = fecha.year == now.year &&
        fecha.month == now.month &&
        fecha.day == now.day;
    final isPastDate = fecha.isBefore(DateTime(now.year, now.month, now.day));

    // Build a set of occupied start times for fast lookup.
    // Each appointment occupies from its hora to hora + duracion.
    final occupiedMap = <String, String>{}; // hora -> patientLabel
    for (final appt in existingAppointments) {
      if (AppointmentStatus.isTerminal(appt.estado) &&
          appt.estado != AppointmentStatus.completada) {
        // Cancelled/no-show don't block the slot.
        continue;
      }
      final apptStart = _parseTime(appt.hora);
      final duration = appt.duracionMinutos;
      // Mark each slot within the appointment's duration.
      for (var m = 0; m < duration; m += slotMinutes) {
        final slotTime = apptStart.add(Duration(minutes: m));
        final key = _formatTime(slotTime);
        occupiedMap[key] = appt.pacienteNombre;
      }
    }

    final slots = <TimeSlot>[];
    var current = start;
    while (current.isBefore(end)) {
      final key = _formatTime(current);

      SlotState state;
      if (isPastDate) {
        state = SlotState.past;
      } else if (isToday &&
          (current.hour < now.hour ||
              (current.hour == now.hour && current.minute < now.minute))) {
        state = SlotState.past;
      } else if (occupiedMap.containsKey(key)) {
        state = SlotState.occupied;
      } else {
        state = SlotState.available;
      }

      slots.add(TimeSlot(
        hora: key,
        state: state,
        appointmentLabel: occupiedMap[key],
      ));
      current = current.add(Duration(minutes: slotMinutes));
    }

    return slots;
  }

  static DateTime _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ──────────────────────────────────────────────
        if (odontologoNombre != null || fechaLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.calendar_view_day_rounded,
                    size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      if (odontologoNombre != null)
                        'Dr(a). $odontologoNombre',
                      if (fechaLabel != null) fechaLabel!,
                    ].join(' — '),
                    style: tt.titleSmall?.copyWith(color: cs.primary),
                  ),
                ),
              ],
            ),
          ),

        // ── Legend ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _legendDot(AppColors.success, 'Disponible'),
              const SizedBox(width: 16),
              _legendDot(AppColors.error, 'Ocupado'),
              const SizedBox(width: 16),
              _legendDot(Colors.grey, 'Pasado'),
            ],
          ),
        ),

        // ── Grid ────────────────────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = slot.hora == selectedSlot;
            return _SlotChip(
              slot: slot,
              isSelected: isSelected,
              onTap: slot.state == SlotState.available
                  ? () => onSlotSelected(slot.hora)
                  : null,
            );
          }).toList(),
        ),

        // ── Summary ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            '${slots.where((s) => s.state == SlotState.available).length} '
            'horarios disponibles de ${slots.length} total',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.isSelected,
    this.onTap,
  });

  final TimeSlot slot;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    Color borderColor;

    switch (slot.state) {
      case SlotState.available:
        if (isSelected) {
          bgColor = AppColors.primary;
          fgColor = Colors.white;
          borderColor = AppColors.primaryDark;
        } else {
          bgColor = AppColors.success.withValues(alpha: 0.1);
          fgColor = AppColors.success;
          borderColor = AppColors.success.withValues(alpha: 0.3);
        }
      case SlotState.occupied:
        bgColor = AppColors.error.withValues(alpha: 0.1);
        fgColor = AppColors.error;
        borderColor = AppColors.error.withValues(alpha: 0.3);
      case SlotState.past:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        fgColor = Colors.grey;
        borderColor = Colors.grey.withValues(alpha: 0.2);
    }

    return Tooltip(
      message: slot.state == SlotState.occupied
          ? slot.appointmentLabel ?? 'Ocupado'
          : slot.state == SlotState.past
              ? 'Horario pasado'
              : 'Disponible — toca para seleccionar',
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 76,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              slot.hora,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: fgColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
