import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phi_app/components/my_colors.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../services/analyticsDashboardService.dart';
import '../components/graphViewer.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({Key? key}) : super(key: key);

  @override
  _AnalyticsDashboardPage createState() => _AnalyticsDashboardPage();
}

class _AnalyticsDashboardPage extends State<AnalyticsDashboardPage> {
  final AnalyticsDashboardService _analyticsService = AnalyticsDashboardService();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int _denguePatientCount = 0;
  int _hospitalizedPatientCount = 0;
  int _completedFumigationsCount = 0;
  int _breedingSitesCount = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load all analytics data concurrently
      final denguePatientsFuture = _analyticsService.getDenguePatientCount(_startDate, _endDate);
      final hospitalizedFuture = _analyticsService.getHospitalizedDenguePatientCount(_startDate, _endDate);
      final fumigationsFuture = _analyticsService.getCompletedFumigationsCount(_startDate, _endDate);
      final breedingSitesFuture = _analyticsService.getBreedingSitesCount(_startDate, _endDate);

      // Wait for all futures to complete
      final results = await Future.wait([
        denguePatientsFuture,
        hospitalizedFuture,
        fumigationsFuture,
        breedingSitesFuture
      ]);

      setState(() {
        _denguePatientCount = results[0];
        _hospitalizedPatientCount = results[1];
        _completedFumigationsCount = results[2];
        _breedingSitesCount = results[3];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load analytics data: ${e.toString()}';
      });
    }
  }

  void _showDateRangePicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Date Range'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: SfDateRangePicker(
              view: DateRangePickerView.month,
              selectionMode: DateRangePickerSelectionMode.range,
              initialSelectedRange: PickerDateRange(_startDate, _endDate),
              maxDate: DateTime.now(),
              onSelectionChanged: (DateRangePickerSelectionChangedArgs args){
                if (args.value is PickerDateRange) {
                  final PickerDateRange range = args.value;
                  setState(() {
                    _startDate = range.startDate ?? _startDate;
                    _endDate = range.endDate ?? _startDate;
                  });
                }
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
                onPressed: (){
                  Navigator.of(context).pop();
                  _loadData();
                },
                child: const Text('Apply'),
            ),
          ],
        );
      }
    );
  }

  void _navigateToDenguePatientGraph() async {
    try {
      final data = await _analyticsService.getDenguePatientDataForGraph(_startDate, _endDate);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DenguePatientGraphViewer(data: data),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load graph data: ${e.toString()}')),
      );
    }
  }

  void _navigateToHospitalizedGraph() async {
    try {
      final data = await _analyticsService.getHospitalizedDataForGraph(_startDate, _endDate);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HospitalizedGraphViewer(data: data),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load graph data: ${e.toString()}')),
      );
    }
  }

  void _navigateToBreedingSitesGraph() async {
    try {
      final data = await _analyticsService.getBreedingSitesDataForGraph(_startDate, _endDate);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BreedingSitesGraphViewer(data: data),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load graph data: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
          : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeSelector(),
          const SizedBox(height: 24),
          _buildStatCards(),
          const SizedBox(height: 24),
          _buildSummarySection(),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: const Text('Change'),
                  onPressed: _showDateRangePicker,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: MyColors.mainColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Dengue Patients',
                _denguePatientCount.toString(),
                Colors.red,
                Icons.sick,
                onTap: _navigateToDenguePatientGraph,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Hospitalized',
                _hospitalizedPatientCount.toString(),
                Colors.orange,
                Icons.local_hospital,
                onTap: _navigateToHospitalizedGraph,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Completed Fumigations',
                _completedFumigationsCount.toString(),
                Colors.blue,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Breeding Sites',
                _breedingSitesCount.toString(),
                Colors.green,
                Icons.bug_report,
                onTap: _navigateToBreedingSitesGraph,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, {VoidCallback? onTap}) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    // Calculate hospitalization rate as a percentage
    double hospitalizationRate = _denguePatientCount > 0
        ? (_hospitalizedPatientCount / _denguePatientCount) * 100
        : 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryItem(
              'Hospitalization Rate',
              '${hospitalizationRate.toStringAsFixed(1)}%',
              hospitalizationRate > 30 ? Colors.red : Colors.green,
              'Percentage of dengue patients requiring hospitalization',
            ),
            const Divider(),
            _buildSummaryItem(
              'Date Range Duration',
              '${_endDate.difference(_startDate).inDays + 1} days',
              Colors.blue,
              'Total number of days in the selected period',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color valueColor, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

}
