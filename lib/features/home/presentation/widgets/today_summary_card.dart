import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/home/l10n/home_strings.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/widgets/home_styles.dart';
import 'package:fisioterapia_pelvica/features/home/presentation/widgets/home_view_models.dart';

class TodaySummaryCard extends StatelessWidget {
  const TodaySummaryCard({
    required this.schedule,
    required this.onTap,
    super.key,
  });

  final List<ScheduleItem> schedule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = HomeStrings(context.watch<LocaleCubit>().state);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(kHomeCardRadius + 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(kHomeCardRadius + 2),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kHomeCardRadius + 2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [context.colors.primary, context.colors.primaryButton],
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.upcomingAppointmentsTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              if (schedule.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      t.noUpcomingAppointmentsMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                )
              else
                for (var i = 0; i < schedule.length; i++)
                  _ScheduleRow(item: schedule[i], showDivider: i != 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.item, required this.showDivider});

  final ScheduleItem item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LocaleCubit>().state;
    return Column(
      children: [
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.dayLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      item.time,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  item.patientName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(100)),
                ),
                child: Text(
                  item.status.label(language),
                  style: TextStyle(
                    color: item.status.foreground(context.colors),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
