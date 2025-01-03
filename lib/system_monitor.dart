import 'dart:async';
import 'package:flutter/material.dart';
import 'package:system_info2/system_info2.dart';
import 'package:fl_chart/fl_chart.dart';

class SystemMonitorWidget extends StatefulWidget {
  const SystemMonitorWidget({super.key});

  @override
  State<SystemMonitorWidget> createState() => _SystemMonitorWidgetState();
}

class _SystemMonitorWidgetState extends State<SystemMonitorWidget> {
  Timer? _timer;
  Map<String, dynamic> _systemInfo = {};
  double _totalMemory = 0;
  double _usedMemory = 0;
  double _totalSwap = 0;
  double _freeSwap = 0;

  @override
  void initState() {
    super.initState();
    _updateSystemInfo();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateSystemInfo();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateSystemInfo() {
    final totalMemory = SysInfo.getTotalPhysicalMemory() / (1024 * 1024 * 1024);
    final freeMemory = SysInfo.getFreePhysicalMemory() / (1024 * 1024 * 1024);
    final usedMemory = totalMemory - freeMemory;
    _totalSwap = SysInfo.getTotalVirtualMemory() / (1024 * 1024 * 1024);
    _freeSwap = SysInfo.getFreeVirtualMemory() / (1024 * 1024 * 1024);

    setState(() {
      _totalMemory = totalMemory;
      _usedMemory = usedMemory;
      _systemInfo = {
        'CPU Cores': SysInfo.cores.length,
        'CPU Architecture': SysInfo.kernelArchitecture,
        'Total Memory': '${totalMemory.toStringAsFixed(1)} GB',
        'Free Memory': '${freeMemory.toStringAsFixed(1)} GB',
        'Used Memory': '${usedMemory.toStringAsFixed(1)} GB',
        'Total Swap': '${_totalSwap.toStringAsFixed(1)} GB',
        'Free Swap': '${_freeSwap.toStringAsFixed(1)} GB',
        'Kernel Version': SysInfo.kernelVersion,
        'Operating System': SysInfo.operatingSystemName,
      };
    });
  }

  Widget _buildMemoryPieChart() {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: Colors.blue,
              value: _usedMemory,
              title: 'Used',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              color: Colors.green,
              value: _totalMemory - _usedMemory,
              title: 'Free',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwapPieChart() {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: Colors.orange,
              value: _totalSwap - _freeSwap,
              title: 'Used',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              color: Colors.lightGreen,
              value: _freeSwap,
              title: 'Free',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Memory Usage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildMemoryPieChart(),
            const SizedBox(height: 16),
            const Text(
              'Swap Memory Usage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildSwapPieChart(),
            const SizedBox(height: 16),
            const Text(
              'System Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._systemInfo.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(entry.value.toString()),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
