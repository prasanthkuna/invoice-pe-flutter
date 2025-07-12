import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/debug_service.dart';

/// Debug logs screen for viewing centralized logs
/// Only available in debug mode for developers
class DebugLogsScreen extends ConsumerStatefulWidget {
  const DebugLogsScreen({super.key});

  @override
  ConsumerState<DebugLogsScreen> createState() => _DebugLogsScreenState();
}

class _DebugLogsScreenState extends ConsumerState<DebugLogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String _selectedLevel = 'ALL';
  String _selectedCategory = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      setState(() => _isLoading = true);

      // Simple query without filters for now - we'll filter client-side
      final response = await Supabase.instance.client
          .from('logs')
          .select()
          .order('created_at', ascending: false)
          .limit(100);

      // Apply client-side filtering
      List<Map<String, dynamic>> filteredLogs = List<Map<String, dynamic>>.from(response);

      if (_selectedLevel != 'ALL') {
        filteredLogs = filteredLogs.where((log) => log['level'] == _selectedLevel).toList();
      }

      if (_selectedCategory != 'ALL') {
        filteredLogs = filteredLogs.where((log) => log['category'] == _selectedCategory).toList();
      }
      
      setState(() {
        _logs = filteredLogs;
        _isLoading = false;
      });
      
      DebugService.logInfo('Loaded ${_logs.length} debug logs');
    } catch (e) {
      DebugService.logError('Failed to load debug logs', error: e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        backgroundColor: AppTheme.primaryAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.cardBackground,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedLevel,
                    isExpanded: true,
                    items: ['ALL', 'ERROR', 'WARN', 'INFO', 'DEBUG']
                        .map((level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedLevel = value!);
                      _loadLogs();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: ['ALL', 'AUTH', 'DB', 'API', 'PAYMENT', 'NAVIGATION', 'USER_ACTION']
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value!);
                      _loadLogs();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Logs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'No logs found',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return _LogTile(log: log);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to clear all logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.from('logs').delete().neq('id', '');
        _loadLogs();
        DebugService.logInfo('Debug logs cleared');
      } catch (e) {
        DebugService.logError('Failed to clear logs', error: e);
      }
    }
  }
}

class _LogTile extends StatelessWidget {
  final Map<String, dynamic> log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final level = log['level'] as String;
    final category = log['category'] as String;
    final message = log['message'] as String;
    final createdAt = DateTime.parse(log['created_at'] as String);
    final contextData = log['context'] as Map<String, dynamic>?;
    final errorDetails = log['error_details'] as Map<String, dynamic>?;
    final performanceMs = log['performance_ms'] as int?;

    Color levelColor;
    IconData levelIcon;
    
    switch (level) {
      case 'ERROR':
        levelColor = Colors.red;
        levelIcon = Icons.error;
        break;
      case 'WARN':
        levelColor = Colors.orange;
        levelIcon = Icons.warning;
        break;
      case 'INFO':
        levelColor = Colors.blue;
        levelIcon = Icons.info;
        break;
      case 'DEBUG':
        levelColor = Colors.grey;
        levelIcon = Icons.bug_report;
        break;
      default:
        levelColor = Colors.grey;
        levelIcon = Icons.circle;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: Icon(levelIcon, color: levelColor),
        title: Text(
          message,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '$category • ${_formatTime(createdAt)}${performanceMs != null ? ' • ${performanceMs}ms' : ''}',
          style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
        ),
        children: [
          if (contextData != null && contextData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Context:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    contextData.toString(),
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          if (errorDetails != null && errorDetails.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Error Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 4),
                  Text(
                    errorDetails.toString(),
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.red),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
