import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wheeler/services/user_api.dart';
import 'package:wheeler/services/solana_service.dart';
import 'package:wheeler/widget/custom_drawer.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Cache for different periods
  final Map<String, List<dynamic>> _leaderboardCache = {};
  final Map<String, bool> _isLoadingMap = {};
  final Map<String, String> _errorMap = {};

  final List<String> _periods = ['daily', 'weekly', 'all-time'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Initial load
    _fetchLeaderboard('daily');
    _fetchLeaderboard('weekly');
    _fetchLeaderboard('all-time');
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      // Optional: Refresh on tab change if needed, but we cache for now
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaderboard(String period) async {
    if (_isLoadingMap[period] == true) return;

    setState(() {
      _isLoadingMap[period] = true;
      _errorMap[period] = '';
    });

    try {
      final data = await UserApi.getLeaderboard(period: period);

      if (mounted) {
        setState(() {
          _leaderboardCache[period] = data;
          _isLoadingMap[period] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMap[period] = 'Failed to load leaderboard';
          _isLoadingMap[period] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            const Text(
              'LEADERBOARD',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 6,
                shadows: [Shadow(color: Color(0xFFF48FB1), blurRadius: 15)],
              ),
            ),
            Container(
              height: 2,
              width: 40,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0xFFF48FB1),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                size: 32,
                color: Colors.white,
              ),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF48FB1),
          labelColor: const Color(0xFFF48FB1),
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'DAILY'),
            Tab(text: 'WEEKLY'),
            Tab(text: 'ALL TIME'),
          ],
        ),
      ),
      endDrawer: const CustomDrawer(currentRoute: '/leaderboard'),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _periods
                  .map((period) => _buildLeaderboardList(period))
                  .toList(),
            ),
          ),
          _buildMyRankBar(),
        ],
      ),
    );
  }

  Widget _buildMyRankBar() {
    return Consumer<SolanaService>(
      builder: (context, solanaService, _) {
        final currentAddress = solanaService.state.address;
        if (currentAddress == null) return const SizedBox.shrink();

        // Find my rank in current active list
        final currentIndex = _tabController.index;
        final currentPeriod = _periods[currentIndex];
        final list = _leaderboardCache[currentPeriod] ?? [];

        final myEntry = list.firstWhere(
          (entry) => entry['walletAddress'] == currentAddress,
          orElse: () => null,
        );

        if (myEntry == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            border: Border(
              top: BorderSide(
                color: const Color(0xFFF48FB1).withOpacity(0.3),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF48FB1).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF48FB1), width: 2),
                ),
                child: Text(
                  '#${myEntry['rank']}',
                  style: const TextStyle(
                    color: Color(0xFFF48FB1),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'You',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF48FB1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF48FB1).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF48FB1),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatPoints(myEntry['totalRewards']),
                      style: const TextStyle(
                        color: Color(0xFFF48FB1),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardList(String period) {
    return Consumer<SolanaService>(
      builder: (context, solanaService, _) {
        final currentAddress = solanaService.state.address;
        final isLoading = _isLoadingMap[period] ?? true;
        final errorMessage = _errorMap[period] ?? '';
        final leaderboard = _leaderboardCache[period] ?? [];

        if (isLoading && leaderboard.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF48FB1)),
          );
        }

        if (errorMessage.isNotEmpty && leaderboard.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _fetchLeaderboard(period),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF48FB1),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (leaderboard.isEmpty) {
          return Center(
            child: Text(
              'No records for this period',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFFF48FB1),
          backgroundColor: const Color(0xFF16213e),
          onRefresh: () => _fetchLeaderboard(period),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              final int rank = entry['rank'];
              final isTop3 = rank <= 3;
              final Color rankColor = _getRankColor(rank);
              final isMe = entry['walletAddress'] == currentAddress;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xFFF48FB1).withOpacity(0.15)
                      : _getRankBackgroundColor(rank),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isMe
                        ? const Color(0xFFF48FB1)
                        : rankColor.withOpacity(0.3),
                    width: isMe ? 1.5 : 1,
                  ),
                  boxShadow: isTop3
                      ? [
                          BoxShadow(
                            color: rankColor.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    // Rank
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rankColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: rankColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          color: rankColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isMe
                                ? 'You'
                                : _formatWalletAddress(
                                    entry['walletAddress'] ?? '',
                                  ),
                            style: TextStyle(
                              color: isMe
                                  ? const Color(0xFFF48FB1)
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: isMe ? null : 'monospace',
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF48FB1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFF48FB1).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF48FB1),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatPoints(entry['totalRewards']),
                            style: const TextStyle(
                              color: Color(0xFFF48FB1),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatPoints(dynamic points) {
    if (points == null) return '0';
    // Use RegExp to separate thousands
    try {
      final number = double.parse(points.toString());
      // If it's an integer like 100.0, show 100
      if (number == number.truncateToDouble()) {
        final intVal = number.truncate();
        return intVal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
      }
      // If decimal, keep 2 decimal places max
      return number.toStringAsFixed(
        number.truncateToDouble() == number ? 0 : 2,
      );
    } catch (e) {
      return points.toString();
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.white;
    }
  }

  Color _getRankBackgroundColor(int rank) {
    if (rank <= 3) {
      return const Color(0xFF16213e);
    }
    return Colors.white.withValues(alpha: 0.03);
  }

  String _formatWalletAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 4)}...${address.substring(address.length - 4)}';
  }
}
