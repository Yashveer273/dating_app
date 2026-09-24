import 'package:flutter/material.dart';
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/components/app_colors.dart';

class CallHistoryPage extends StatefulWidget {
  const CallHistoryPage({super.key});

  @override
  State createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends State {
  final UserApiService _apiService = UserApiService();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  List _historyList = [];
  Map? _userInfo;
  num _walletBalance = 0;

  // Pagination variables
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasNextPage = false;

  // Filter variables
  DateTime? _selectedDate;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _apiService.onInit();
    _fetchHistoryData(page: 1, reset: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (_hasNextPage && !_isLoadingMore) {
          _loadMoreData();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future _fetchHistoryData({required int page, bool reset = false}) async {
    if (reset) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingMore = true);
    }

    final response = await _apiService.fetchUserCallHistory(
      page: page,
      limit: 10,
      selectedDate: _selectedDate, // Pass DateTime directly
    );

    if (response != null && response['success'] == true) {
      setState(() {
        _walletBalance = response['currentWalletBalance'] ?? 0;
        _userInfo = response['userInfo'];

        final pagination = response['pagination'];
        if (pagination != null) {
          _currentPage = pagination['currentPage'] ?? page;
          _totalPages = pagination['totalPages'] ?? 1;
          _hasNextPage = pagination['hasNextPage'] ?? false;
        }

        if (reset) {
          _historyList = response['history'] ?? [];
        } else {
          _historyList.addAll(response['history'] ?? []);
        }
      });
    }

    setState(() {
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  Future _loadMoreData() async {
    if (_currentPage < _totalPages) {
      await _fetchHistoryData(page: _currentPage + 1, reset: false);
    }
  }

  Future _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryPink,
              onPrimary: Colors.white,
              surface: AppColors.darkCard,
              onSurface: AppColors.darkPrimaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchHistoryData(page: 1, reset: true);
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
    _fetchHistoryData(page: 1, reset: true);
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBgTop : AppColors.lightBgTop,
      appBar: AppBar(
        backgroundColor: isDarkMode
            ? AppColors.darkBgMid
            : AppColors.lightBgMid,
        elevation: 0,
        title: Text(
          "Call History & Ledger",
          style: TextStyle(
            color: isDarkMode
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month,
              color: _selectedDate != null
                  ? AppColors.primaryPink
                  : (isDarkMode ? Colors.white : Colors.black),
            ),
            onPressed: () => _selectDate(context),
            tooltip: "Filter by Date",
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.primaryPink),
              onPressed: _clearDateFilter,
              tooltip: "Clear Filter",
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            )
          : Column(
              children: [
                // Header Profile & Wallet Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.pinkGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPink.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(
                          _userInfo?['avatar'] ??
                              "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userInfo?['name'] ?? "Valued User",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedDate != null
                                  ? "Filtered: ${_selectedDate.toString().split('T')[0]}"
                                  : "Total Records: ${_historyList.length}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Wallet Balance",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "₹$_walletBalance",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // History List Ledger
                Expanded(
                  child: _historyList.isEmpty
                      ? Center(
                          child: Text(
                            "No call history found.",
                            style: TextStyle(
                              color: isDarkMode
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount:
                              _historyList.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _historyList.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryPink,
                                  ),
                                ),
                              );
                            }

                            final call = _historyList[index];
                            bool isVideo = call['callType'] == 'video';

                            String formattedTime = _selectedDate != null
                                ? "Filtered: ${_selectedDate.toString().split('T')[0]}"
                                : "Total Records: ${_historyList.length}";

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? AppColors.darkCard
                                    : AppColors.lightCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDarkMode
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isVideo
                                          ? AppColors.pinkLight.withOpacity(0.2)
                                          : AppColors.otpSuccessGreen
                                                .withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isVideo ? Icons.videocam : Icons.call,
                                      color: isVideo
                                          ? AppColors.primaryPink
                                          : AppColors.otpSuccessGreen,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "${call['callType'].toString().toUpperCase()} CALL",
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? AppColors.darkPrimaryText
                                                    : AppColors
                                                          .lightPrimaryText,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              "-₹${call['totalCostDeducted']}",
                                              style: const TextStyle(
                                                color: AppColors.primaryPink,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formattedTime,
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? AppColors.darkSecondaryText
                                                : AppColors.lightSecondaryText,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            _badge(
                                              label:
                                                  "${call['durationInSeconds']}s duration",
                                              color: Colors.blueAccent,
                                            ),
                                            const SizedBox(width: 6),
                                            _badge(
                                              label:
                                                  call['disconnectReason'] ??
                                                  'ended',
                                              color: Colors.orangeAccent,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _badge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
