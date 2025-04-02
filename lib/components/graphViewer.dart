import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class GraphViewer extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final List<Map<String, dynamic>>? secondList;
  final String title;
  final String yAxisLabel;
  final String? secondListLable;
  final Color lineColor;
  final bool showDots;

  const GraphViewer({
    Key? key,
    required this.data,
    this.secondList,
    required this.title,
    this.yAxisLabel = 'Count',
    this.secondListLable,
    this.lineColor = Colors.blue,
    this.showDots = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: data.isEmpty
          ? Center(child: Text('No data available for the selected period'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Total: ${_calculateTotal()} ${yAxisLabel.toLowerCase()}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _buildLineChart(),
            ),
            const SizedBox(height: 16),
            _buildDataTable(),
          ],
        ),
      ),
    );
  }

  int _calculateTotal() {
    int total = 0;
    for (var item in data) {
      total += item['count'] as int;
    }
    return total;
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length && value.toInt() % _getLabelInterval() == 0) {
                  String date = data[value.toInt()]['date'];
                  String displayDate = date.length > 7
                      ? DateFormat('dd/MM').format(DateTime.parse(date))
                      : DateFormat('MMM').format(DateTime.parse('$date-01'));

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      displayDate,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateYAxisInterval(),
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d)),
        ),
        minX: 0,
        maxX: data.length - 1.0,
        minY: 0,
        maxY: _calculateMaxY(),
        lineBarsData: [
          LineChartBarData(
            spots: _createSpots(),
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: showDots,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: lineColor,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final int index = spot.x.toInt();
                if (index >= 0 && index < data.length) {
                  String date = data[index]['date'];
                  int count = data[index]['count'];
                  int secondCount = secondList![index]['count'];

                  String formattedDate = date.length > 7
                      ? DateFormat('dd MMM yyyy').format(DateTime.parse(date))
                      : DateFormat('MMMM yyyy').format(DateTime.parse('$date-01'));

                  return LineTooltipItem(
                    '$formattedDate\n$count $yAxisLabel ${secondListLable != null ? '\n$secondCount $secondListLable' : ''}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<FlSpot> _createSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), (data[i]['count'] as int).toDouble()));
    }
    return spots;
  }

  double _calculateMaxY() {
    if (data.isEmpty) return 10;

    int maxCount = 0;
    for (var item in data) {
      final int count = item['count'] as int;
      if (count > maxCount) {
        maxCount = count;
      }
    }

    // Add 20% padding to the top
    return (maxCount * 1.2).ceilToDouble();
  }

  double _calculateYAxisInterval() {
    double maxY = _calculateMaxY();
    if (maxY <= 5) return 1;
    if (maxY <= 20) return 5;
    if (maxY <= 100) return 20;
    return (maxY / 5).ceilToDouble();
  }

  int _getLabelInterval() {
    // Calculate interval based on data length to avoid crowded labels
    if (data.length <= 10) return 1;
    if (data.length <= 20) return 2;
    if (data.length <= 60) return 5;
    return (data.length / 10).ceil();
  }

  Widget _buildDataTable() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Count'), numeric: true),
          ],
          rows: data.map((item) {
            String date = item['date'];

            // Format date based on whether it's daily or monthly
            String formattedDate = date.length > 7
                ? DateFormat('dd MMM yyyy').format(DateTime.parse(date))
                : DateFormat('MMMM yyyy').format(DateTime.parse('$date-01'));

            return DataRow(
              cells: [
                DataCell(Text(formattedDate)),
                DataCell(Text(item['count'].toString())),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// For specific type of graphs
class DenguePatientGraphViewer extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const DenguePatientGraphViewer({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GraphViewer(
      data: data,
      title: 'Dengue Patient Statistics',
      yAxisLabel: 'Patients',
      lineColor: Colors.red,
    );
  }
}

class HospitalizedGraphViewer extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const HospitalizedGraphViewer({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> graphData = data.map((entry) {
      return {
        'date': entry['date'],
        'count': entry['hospitalized'],
      };
    }).toList();
    final List<Map<String, dynamic>> secondData = data.map((entry) {
      return {
        'date': entry['date'],
        'count': entry['patients'],
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GraphViewer(
            data: graphData,
            secondList: secondData,
            title: 'Hospitalized Patient Statistics',
            yAxisLabel: 'Hospitalized',
            secondListLable: 'Patients',
            lineColor: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class BreedingSitesGraphViewer extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const BreedingSitesGraphViewer({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GraphViewer(
      data: data,
      title: 'Breeding Sites Statistics',
      yAxisLabel: 'Sites',
      lineColor: Colors.green,
    );
  }
}