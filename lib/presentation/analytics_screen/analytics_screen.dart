import 'package:fl_chart/fl_chart.dart';

import '../../core/app_export.dart';
import '../../database/database_helper.dart';
import '../../models/transaction_model.dart';


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isLoading = true;
  List<TransactionModel> _transactions = [];


  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _loadData();
    DatabaseHelper.instance.onTransactionsChanged.addListener(_loadData);
  }

  @override
  void dispose() {
    DatabaseHelper.instance.onTransactionsChanged.removeListener(_loadData);
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final txs = await _db.getAllTransactions();
      if (mounted) {
        setState(() {
          _transactions = txs;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  // ── Data Computation ──────────────────────────────────────────

  Map<String, double> get _categoryTotals {
    final Map<String, double> totals = {};
    for (final tx in _transactions) {
      if (tx.type == TransactionType.expense) {
        totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
      }
    }
    return totals;
  }



  Color _categoryColor(String category) {
    final tx = _transactions.firstWhere(
      (t) => t.category == category,
      orElse: () => TransactionModel(
        title: '',
        amount: 0,
        category: category,
        categoryIcon: 'more_horiz',
        categoryColor: '#6B7280',
        date: DateTime.now(),
        type: TransactionType.expense,
      ),
    );
    return _hexToColor(tx.categoryColor);
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Weekly totals: last 7 days, grouped by day of week
  List<double> get _weeklyExpenses {
    final now = DateTime.now();
    final List<double> daily = List.filled(7, 0.0);
    for (final tx in _transactions) {
      if (tx.type == TransactionType.expense) {
        final diff = now.difference(tx.date).inDays;
        if (diff >= 0 && diff < 7) {
          daily[6 - diff] += tx.amount;
        }
      }
    }
    return daily;
  }

  /// Monthly totals: last 6 months
  List<_MonthData> get _monthlyTrend {
    final now = DateTime.now();
    final List<_MonthData> months = [];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      double expense = 0;
      double income = 0;
      for (final tx in _transactions) {
        if (tx.date.year == month.year && tx.date.month == month.month) {
          if (tx.type == TransactionType.expense) {
            expense += tx.amount;
          } else {
            income += tx.amount;
          }
        }
      }
      months.add(_MonthData(month: month, expense: expense, income: income));
    }
    return months;
  }

  double get _totalExpenses {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _totalIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: Column(
        children: [
          _buildGradientHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          left: 4.w,
                          right: 4.w,
                          top: 2.h,
                          bottom: 12.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryRow(),
                            SizedBox(height: 2.h),
                            _buildPieChartSection(),
                            SizedBox(height: 2.h),
                            _buildWeeklyBarChartSection(),
                            SizedBox(height: 2.h),
                            _buildMonthlyTrendSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              Text(
                'Analytics',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            label: 'Total Income',
            amount: _totalIncome,
            color: AppTheme.income,
            icon: Icons.arrow_downward_rounded,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildSummaryCard(
            label: 'Total Expenses',
            amount: _totalExpenses,
            color: AppTheme.expense,
            icon: Icons.arrow_upward_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.mutedLight,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  SettingsService.instance.formatAmount(amount, decimalDigits: 0),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pie Chart ─────────────────────────────────────────────────

  Widget _buildPieChartSection() {
    final totals = _categoryTotals;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Spending by Category', Icons.pie_chart_rounded),
          const SizedBox(height: 16),
          totals.isEmpty
              ? _buildEmptyChart('No expense data available')
              : Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      _touchedPieIndex = -1;
                                      return;
                                    }
                                    _touchedPieIndex = pieTouchResponse
                                        .touchedSection!
                                        .touchedSectionIndex;
                                  });
                                },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 3,
                          centerSpaceRadius: 50,
                          sections: _buildPieSections(totals),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPieLegend(totals),
                  ],
                ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> totals) {
    final total = totals.values.fold(0.0, (a, b) => a + b);
    final entries = totals.entries.toList();
    return List.generate(entries.length, (i) {
      final entry = entries[i];
      final isTouched = i == _touchedPieIndex;
      final pct = total > 0 ? (entry.value / total * 100) : 0.0;
      return PieChartSectionData(
        color: _categoryColor(entry.key),
        value: entry.value,
        title: '${pct.toStringAsFixed(0)}%',
        radius: isTouched ? 65 : 55,
        titleStyle: GoogleFonts.outfit(
          fontSize: isTouched ? 13 : 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildPieLegend(Map<String, double> totals) {
    final total = totals.values.fold(0.0, (a, b) => a + b);
    final entries = totals.entries.toList();
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: entries.map((entry) {
        final pct = total > 0 ? (entry.value / total * 100) : 0.0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _categoryColor(entry.key),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '${entry.key} (${pct.toStringAsFixed(0)}%)',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedLight,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Bar Chart ─────────────────────────────────────────────────

  Widget _buildWeeklyBarChartSection() {
    final weeklyData = _weeklyExpenses;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxVal = weeklyData.reduce((a, b) => a > b ? a : b);
    final now = DateTime.now();
    final dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[d.weekday - 1];
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Weekly Breakdown', Icons.bar_chart_rounded),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal > 0 ? maxVal * 1.3 : 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: AppTheme.primary.withAlpha(230),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        SettingsService.instance.formatAmount(rod.toY, decimalDigits: 0),
                        GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dayLabels[idx],
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppTheme.mutedLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          SettingsService.instance.formatAmount(value, decimalDigits: 0),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: AppTheme.mutedLight,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? AppTheme.outlineDark
                        : AppTheme.outlineLight,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: weeklyData[i],
                        gradient: LinearGradient(
                          colors: [AppTheme.primary, AppTheme.secondary],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal > 0 ? maxVal * 1.3 : 100,
                          color: isDark
                              ? AppTheme.outlineDark.withAlpha(80)
                              : AppTheme.outlineLight,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Monthly Trend ─────────────────────────────────────────────

  Widget _buildMonthlyTrendSection() {
    final months = _monthlyTrend;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allValues = [
      ...months.map((m) => m.expense),
      ...months.map((m) => m.income),
    ];
    final maxVal = allValues.isEmpty
        ? 100.0
        : allValues.reduce((a, b) => a > b ? a : b);
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Monthly Trend', Icons.show_chart_rounded),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendDot(AppTheme.income, 'Income'),
              const SizedBox(width: 16),
              _buildLegendDot(AppTheme.expense, 'Expenses'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: maxVal > 0 ? maxVal * 1.2 : 100,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppTheme.primary.withAlpha(230),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final label = spot.barIndex == 0 ? 'Income' : 'Expense';
                        return LineTooltipItem(
                          '$label: ${SettingsService.instance.formatAmount(spot.y, decimalDigits: 0)}',
                          GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? AppTheme.outlineDark
                        : AppTheme.outlineLight,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            monthNames[months[idx].month.month - 1],
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppTheme.mutedLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          SettingsService.instance.formatAmount(value, decimalDigits: 0),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: AppTheme.mutedLight,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Income line
                  LineChartBarData(
                    spots: List.generate(
                      months.length,
                      (i) => FlSpot(i.toDouble(), months[i].income),
                    ),
                    isCurved: true,
                    color: AppTheme.income,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: AppTheme.income,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.income.withAlpha(26),
                    ),
                  ),
                  // Expense line
                  LineChartBarData(
                    spots: List.generate(
                      months.length,
                      (i) => FlSpot(i.toDouble(), months[i].expense),
                    ),
                    isCurved: true,
                    color: AppTheme.expense,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: AppTheme.expense,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.expense.withAlpha(26),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.primaryMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppTheme.mutedLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChart(String message) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.mutedLight),
        ),
      ),
    );
  }
}

class _MonthData {
  final DateTime month;
  final double expense;
  final double income;
  const _MonthData({
    required this.month,
    required this.expense,
    required this.income,
  });
}