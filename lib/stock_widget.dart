import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class CandleData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;

  CandleData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  bool get isGreen => close >= open;
}

class StockWidget extends StatefulWidget {
  final String defaultSymbol;
  const StockWidget({super.key, required this.defaultSymbol});

  @override
  State<StockWidget> createState() => _StockWidgetState();
}

class _StockWidgetState extends State<StockWidget> {
  late TextEditingController _symbolController;
  double? stockPrice;
  String? error;
  List<CandleData> candleData = [];
  double minY = 0;
  double maxY = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _symbolController = TextEditingController(text: widget.defaultSymbol);
    fetchStockData();
  }

  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    // Show month and year for better readability in yearly view
    return DateFormat('MMM yy').format(date);
  }

  Future<void> fetchStockData() async {
    if (_symbolController.text.isEmpty) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final now = DateTime.now();
      final period1 = now.subtract(const Duration(days: 365)).millisecondsSinceEpoch ~/ 1000;
      final period2 = now.millisecondsSinceEpoch ~/ 1000;
      
      final response = await http.get(
        Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/${_symbolController.text.toUpperCase()}?period1=$period1&period2=$period2&interval=1d'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final quote = data['chart']['result'][0]['indicators']['quote'][0];
        final timestamps = List<int>.from(data['chart']['result'][0]['timestamp']);
        
        final opens = quote['open'];
        final highs = quote['high'];
        final lows = quote['low'];
        final closes = quote['close'];
        
        // Get current price
        stockPrice = closes.last?.toDouble();
        
        // Create candle data
        candleData = [];
        List<double> allPrices = [];
        
        for (int i = 0; i < timestamps.length; i++) {
          if (opens[i] != null && highs[i] != null && lows[i] != null && closes[i] != null) {
            final open = opens[i].toDouble();
            final high = highs[i].toDouble();
            final low = lows[i].toDouble();
            final close = closes[i].toDouble();
            
            allPrices.addAll([open, high, low, close]);
            
            candleData.add(CandleData(
              date: DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
              open: open,
              high: high,
              low: low,
              close: close,
            ));
          }
        }
        
        if (allPrices.isNotEmpty) {
          minY = allPrices.reduce((a, b) => a < b ? a : b) * 0.95;
          maxY = allPrices.reduce((a, b) => a > b ? a : b) * 1.05;
        }

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to fetch stock data';
          candleData = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        candleData = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _symbolController,
                    decoration: InputDecoration(
                      labelText: 'Stock Symbol',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: fetchStockData,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => fetchStockData(),
                  ),
                ),
                if (stockPrice != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    '\$${stockPrice!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (error != null)
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
              )
            else if (isLoading || candleData.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            // Show date every ~30 days (monthly) for yearly view
                            if (index % 30 == 0 && index < candleData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _formatDate(candleData[index].date),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    barGroups: candleData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data.high,
                            fromY: data.low,
                            width: 1,
                            color: Colors.black,
                          ),
                          BarChartRodData(
                            toY: data.isGreen ? data.close : data.open,
                            fromY: data.isGreen ? data.open : data.close,
                            width: 8,
                            color: data.isGreen ? Colors.green : Colors.red,
                          ),
                        ],
                      );
                    }).toList(),
                    minY: minY,
                    maxY: maxY,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                onPressed: fetchStockData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
