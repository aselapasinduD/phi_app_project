import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/geographicInformationSystemService.dart';

class MapInfoCard extends StatelessWidget {
  final GISMapData data;
  final VoidCallback? onClose;

  const MapInfoCard({
    Key? key,
    required this.data,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Different card styling based on data type
    Color cardColor;
    IconData typeIcon;

    switch (data.type) {
      case 'patient':
        cardColor = Colors.red.shade50;
        typeIcon = Icons.medical_services;
        break;
      case 'fumigation':
        cardColor = Colors.blue.shade50;
        typeIcon = Icons.cleaning_services;
        break;
      case 'breeding':
        cardColor = Colors.green.shade50;
        typeIcon = Icons.bug_report;
        break;
      default:
        cardColor = Colors.grey.shade100;
        typeIcon = Icons.info;
    }

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(typeIcon),
                    const SizedBox(width: 8),
                    Text(
                      _getTypeTitle(data.type),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const Divider(),
            Text(
              data.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data.address,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(data.date),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTypeSpecificInfo(),
          ],
        ),
      ),
    );
  }

  String _getTypeTitle(String type) {
    switch (type) {
      case 'patient':
        return 'Dengue Patients';
      case 'fumigation':
        return 'Fumigation';
      case 'breeding':
        return 'Breeding Site';
      default:
        return 'Location Info';
    }
  }

  Widget _buildTypeSpecificInfo() {
    switch (data.type) {
      case 'patient':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Number of Patients: ${data.additionalData['numberOfPatients']}'),
            Text('Hospitalized: ${data.additionalData['hospitalized']}'),
            if (data.additionalData['notes'] != null && data.additionalData['notes'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(data.additionalData['notes']),
                ],
              ),
          ],
        );

      case 'fumigation':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Status: '),
                Chip(
                  label: Text(
                    data.additionalData['isCompleted'] ? 'Completed' : 'Pending',
                    style: TextStyle(
                      color: data.additionalData['isCompleted'] ? Colors.white : Colors.black,
                    ),
                  ),
                  backgroundColor: data.additionalData['isCompleted']
                      ? Colors.green
                      : Colors.yellow,
                ),
              ],
            ),
            if (data.additionalData['weatherForecast'] != null &&
                data.additionalData['weatherForecast'].isNotEmpty)
              Text('Weather: ${data.additionalData['weatherForecast']}'),
            if (data.additionalData['notes'] != null &&
                data.additionalData['notes'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(data.additionalData['notes']),
                ],
              ),
          ],
        );

      case 'breeding':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Site Head: ${data.additionalData['headName']}'),
            Row(
              children: [
                const Text('Legal Action: '),
                Chip(
                  label: Text(
                    data.additionalData['legalAction'] ? 'Yes' : 'No',
                    style: TextStyle(
                      color: data.additionalData['legalAction'] ? Colors.white : Colors.black,
                    ),
                  ),
                  backgroundColor: data.additionalData['legalAction']
                      ? Colors.red
                      : Colors.grey.shade300,
                ),
              ],
            ),
            if (data.additionalData['hasPhotos'])
              const Text('Evidence Photos: Available'),
            if (data.additionalData['notes'] != null &&
                data.additionalData['notes'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(data.additionalData['notes']),
                ],
              ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}