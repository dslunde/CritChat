import 'package:flutter/material.dart';
import 'package:critchat/core/constants/app_colors.dart';

class NotificationIndicator extends StatelessWidget {
  final Widget child;
  final int count;
  final double size;
  final Color? color;
  final EdgeInsetsGeometry? offset;
  final bool showZero;

  const NotificationIndicator({
    super.key,
    required this.child,
    required this.count,
    this.size = 8.0,
    this.color,
    this.offset,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0 && !showZero) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: offset?.resolve(TextDirection.ltr).top ?? -2,
          right: offset?.resolve(TextDirection.ltr).right ?? -2,
          child: Container(
            constraints: BoxConstraints(minWidth: size, minHeight: size),
            padding: count > 9
                ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
                : null,
            decoration: BoxDecoration(
              color: color ?? AppColors.errorColor,
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: count > 9
                ? Text(
                    '9+',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.6,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  )
                : count > 0
                ? null
                : SizedBox(width: size, height: size),
          ),
        ),
      ],
    );
  }
}

class StreamNotificationIndicator extends StatelessWidget {
  final Widget child;
  final Stream<int> countStream;
  final double size;
  final Color? color;
  final EdgeInsetsGeometry? offset;
  final bool showZero;

  const StreamNotificationIndicator({
    super.key,
    required this.child,
    required this.countStream,
    this.size = 8.0,
    this.color,
    this.offset,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: countStream,
      initialData: 0,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return NotificationIndicator(
          count: count,
          size: size,
          color: color,
          offset: offset,
          showZero: showZero,
          child: child,
        );
      },
    );
  }
}
