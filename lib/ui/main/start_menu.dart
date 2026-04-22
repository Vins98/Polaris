import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polaris/services/theme_service.dart';

// ---------------------------------------------------------------------------
// Result returned by the dialog to the caller
// ---------------------------------------------------------------------------

enum StartMenuAction {
  generalSettings,
  sorting,
  scraping,
  exit,
  dismissed,
}

// ---------------------------------------------------------------------------
// StartMenuDialog
// ---------------------------------------------------------------------------

Future<StartMenuAction> showStartMenu(
  BuildContext context,
  PolarisTheme polarisTheme,
) async {
  final result = await showDialog<StartMenuAction>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) => _StartMenuDialog(polarisTheme: polarisTheme),
  );
  return result ?? StartMenuAction.dismissed;
}

class _StartMenuDialog extends StatefulWidget {
  final PolarisTheme polarisTheme;

  const _StartMenuDialog({required this.polarisTheme});

  @override
  State<_StartMenuDialog> createState() => _StartMenuDialogState();
}

class _StartMenuDialogState extends State<_StartMenuDialog> {
  int _selectedIndex = 0;
  late FocusNode _focusNode;

  static const _items = [
    _MenuItem(
      action: StartMenuAction.generalSettings,
      icon: Icons.settings_outlined,
      label: 'General Settings',
    ),
    _MenuItem(
      action: StartMenuAction.sorting,
      icon: Icons.sort_outlined,
      label: 'Sorting',
    ),
    _MenuItem(
      action: StartMenuAction.scraping,
      icon: Icons.image_search_outlined,
      label: 'Scraping',
    ),
    _MenuItem(
      action: StartMenuAction.exit,
      icon: Icons.power_settings_new_outlined,
      label: 'Exit',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.of(context).pop(_items[_selectedIndex].action);
  }

  void _dismiss() {
    Navigator.of(context).pop(StartMenuAction.dismissed);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        setState(() {
          _selectedIndex =
              (_selectedIndex - 1 + _items.length) % _items.length;
        });
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _items.length;
        });
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
      case LogicalKeyboardKey.gameButtonA:
        _confirm();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.gameButtonStart:
        _dismiss();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.polarisTheme;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: t.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: t.accentColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.menu, color: t.accentColor, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Menu',
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Items
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: List.generate(_items.length, (i) {
                        return _MenuItemRow(
                          item: _items[i],
                          isSelected: _selectedIndex == i,
                          theme: t,
                          onTap: () {
                            setState(() => _selectedIndex = i);
                            _confirm();
                          },
                          onHover: (hovering) {
                            if (hovering) {
                              setState(() => _selectedIndex = i);
                            }
                          },
                        );
                      }),
                    ),
                  ),
                  // Footer hint
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HintChip(label: '↑↓', theme: t),
                        const SizedBox(width: 6),
                        Text(
                          'Navigate',
                          style: TextStyle(
                            color: t.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _HintChip(label: '↵', theme: t),
                        const SizedBox(width: 6),
                        Text(
                          'Select',
                          style: TextStyle(
                            color: t.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _HintChip(label: 'Esc', theme: t),
                        const SizedBox(width: 6),
                        Text(
                          'Close',
                          style: TextStyle(
                            color: t.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MenuItemRow
// ---------------------------------------------------------------------------

class _MenuItemRow extends StatelessWidget {
  final _MenuItem item;
  final bool isSelected;
  final PolarisTheme theme;
  final VoidCallback onTap;
  final void Function(bool) onHover;

  const _MenuItemRow({
    required this.item,
    required this.isSelected,
    required this.theme,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final isExit = item.action == StartMenuAction.exit;
    final itemColor = isExit ? Colors.redAccent : t.textPrimary;

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: isSelected
                ? t.accentColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border(
                    left: BorderSide(color: t.accentColor, width: 3),
                  )
                : const Border(
                    left: BorderSide(color: Colors.transparent, width: 3),
                  ),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: isSelected ? t.accentColor : itemColor.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? t.textPrimary : itemColor.withValues(alpha: 0.85),
                  fontSize: 15,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isExit) ...[
                const Spacer(),
                Icon(Icons.logout, color: Colors.redAccent.withValues(alpha: 0.6), size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HintChip — keyboard hint pill
// ---------------------------------------------------------------------------

class _HintChip extends StatelessWidget {
  final String label;
  final PolarisTheme theme;

  const _HintChip({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textSecondary,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MenuItem descriptor
// ---------------------------------------------------------------------------

class _MenuItem {
  final StartMenuAction action;
  final IconData icon;
  final String label;

  const _MenuItem({
    required this.action,
    required this.icon,
    required this.label,
  });
}
