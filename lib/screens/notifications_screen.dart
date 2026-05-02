import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'landlord/landlord_models.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATIONS SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onUpdate;
  const NotificationsScreen({super.key, this.onUpdate});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final notifications = LandlordStore.notifications;
    final unread = LandlordStore.unreadNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF006B4F),
            systemOverlayStyle: SystemUiOverlayStyle.light,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF006B4F), Color(0xFF00A876)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Notifications',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800)),
                            Text(
                              unread > 0
                                  ? '$unread unread notification${unread > 1 ? 's' : ''}'
                                  : 'All caught up!',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                        if (unread > 0)
                          GestureDetector(
                            onTap: () {
                              LandlordStore.markAllNotificationsRead();
                              setState(() {});
                              widget.onUpdate?.call();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('Mark all read',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              expandedTitleScale: 1,
            ),
            expandedHeight: 90,
          ),
        ],
        body: notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No notifications yet',
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final n = notifications[i];
                  return _NotificationCard(
                    notification: n,
                    onTap: () {
                      LandlordStore.markNotificationRead(n.id);
                      setState(() {});
                      widget.onUpdate?.call();
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final LandlordNotification notification;
  final VoidCallback onTap;

  const _NotificationCard(
      {required this.notification, required this.onTap});

  Color get _typeColor {
    switch (notification.type) {
      case 'booking':     return const Color(0xFF1A1F71);
      case 'payment':     return const Color(0xFF00C48C);
      case 'termination': return Colors.orange;
      default:            return Colors.grey;
    }
  }

  IconData get _typeIcon {
    switch (notification.type) {
      case 'booking':     return Icons.book_online_outlined;
      case 'payment':     return Icons.payments_outlined;
      case 'termination': return Icons.exit_to_app_outlined;
      default:            return Icons.notifications_outlined;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFE8F5EF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade100
                : const Color(0xFF006B4F).withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon, color: _typeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              fontSize: 14,
                              color: const Color(0xFF0D1147),
                            )),
                      ),
                      Text(_timeAgo(notification.createdAt),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.message,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      notification.type[0].toUpperCase() +
                          notification.type.substring(1),
                      style: TextStyle(
                          fontSize: 10,
                          color: _typeColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 4, top: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF006B4F),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}