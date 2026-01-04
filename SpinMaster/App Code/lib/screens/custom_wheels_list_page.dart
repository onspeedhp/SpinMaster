import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wheeler/services/wheel_manage.dart';
import 'package:wheeler/widget/custom_drawer.dart';
import 'package:wheeler/screens/wheel_editor_page.dart';
import 'package:wheeler/screens/custom_wheel_play_page.dart';

class CustomWheelsListPage extends StatelessWidget {
  const CustomWheelsListPage({super.key});

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
              'MY WHEELS',
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
      ),
      endDrawer: const CustomDrawer(currentRoute: '/custom_wheels'),
      body: Consumer<WheelProvider>(
        builder: (context, wheelProvider, child) {
          final wheels = wheelProvider.wheels;

          if (wheels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_esports_outlined,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No custom wheels yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: wheels.length,
            itemBuilder: (context, index) {
              final wheel = wheels[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF48FB1).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pie_chart_rounded,
                        color: Color(0xFFF48FB1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wheel.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${wheel.segments.length} segments',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          context,
                          icon: Icons.play_arrow_rounded,
                          color: Colors.greenAccent,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CustomWheelPlayPage(wheel: wheel),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          context,
                          icon: Icons.edit_rounded,
                          color: const Color(0xFFF48FB1),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WheelEditorPage(wheelToEdit: wheel),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          context,
                          icon: Icons.delete_rounded,
                          color: Colors.redAccent,
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF1a1a2e),
                                title: const Text(
                                  'Delete Wheel?',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: Text(
                                  'Are you sure you want to delete "${wheel.name}"?',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.white60),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              // ignore: use_build_context_synchronously
                              Provider.of<WheelProvider>(
                                context,
                                listen: false,
                              ).deleteWheel(wheel.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WheelEditorPage()),
          );
        },
        backgroundColor: const Color(0xFFF48FB1),
        icon: const Icon(Icons.add_rounded, color: Colors.black),
        label: const Text(
          'CREATE WHEEL',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withValues(alpha: 0.2),
          highlightColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}
