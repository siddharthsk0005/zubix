import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Shared top bar: ZUBIX title, location chip, and expanding search.
class ZubixSliverAppBar extends StatelessWidget {
  final AppState state;
  final bool searchOpen;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleSearch;

  const ZubixSliverAppBar({
    super.key,
    required this.state,
    required this.searchOpen,
    required this.searchController,
    required this.searchFocus,
    required this.searchHint,
    required this.onSearchChanged,
    required this.onToggleSearch,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: false,
      backgroundColor: AppTheme.pureWhite,
      surfaceTintColor: Colors.transparent,
      title: searchOpen
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: const ValueKey('search-field'),
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocus,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: searchHint,
                    hintStyle: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
            )
          : const Text(
              'ZUBIX',
              key: ValueKey('app-title'),
              style: TextStyle(
                fontFamily: 'Helvetica',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: AppTheme.pureBlack,
              ),
            ),
      actions: [
        if (!searchOpen) _LocationChip(state: state),
        IconButton(
          tooltip: searchOpen ? 'Close search' : 'Search',
          icon: Icon(
            searchOpen ? Icons.close : Icons.search,
            color: AppTheme.pureBlack,
          ),
          onPressed: onToggleSearch,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _LocationChip extends StatelessWidget {
  final AppState state;

  const _LocationChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasError = state.locationError != null;
    final label = state.isLocating
        ? 'Locating...'
        : (hasError ? 'Location off' : state.selectedCity);

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Tooltip(
          message: state.locationError ?? 'Tap to refresh your location',
          child: InkWell(
            onTap: state.isLocating ? null : state.detectCurrentLocation,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 170),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.near_me,
                    size: 13,
                    color: hasError ? Colors.redAccent : AppTheme.pureBlack,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: hasError ? Colors.redAccent : AppTheme.pureBlack,
                      ),
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
