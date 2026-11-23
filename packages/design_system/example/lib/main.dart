import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

void main() => runApp(const DesignSystemGalleryApp());

/// Gallery of every design system component in every state, with light/dark
/// and brand toggles.
class DesignSystemGalleryApp extends StatefulWidget {
  /// Creates the gallery app.
  const DesignSystemGalleryApp({super.key});

  @override
  State<DesignSystemGalleryApp> createState() => _DesignSystemGalleryAppState();
}

class _DesignSystemGalleryAppState extends State<DesignSystemGalleryApp> {
  static const _brands = {
    'Standard': DsBrand.standard,
    'Forest': DsBrand(primary: Color(0xFF0B6E4F)),
    'Sunrise': DsBrand(primary: Color(0xFFFFB300)),
  };

  var _mode = ThemeMode.light;
  var _brandName = 'Standard';

  @override
  Widget build(BuildContext context) {
    final brand = _brands[_brandName]!;
    return MaterialApp(
      title: 'Design system gallery',
      themeMode: _mode,
      theme: DsTheme.light(brand: brand),
      darkTheme: DsTheme.dark(brand: brand),
      home: GalleryPage(
        isDark: _mode == ThemeMode.dark,
        onDarkChanged: (dark) =>
            setState(() => _mode = dark ? ThemeMode.dark : ThemeMode.light),
        brandNames: _brands.keys.toList(),
        brandName: _brandName,
        onBrandChanged: (name) => setState(() => _brandName = name),
      ),
    );
  }
}

/// The gallery's single page: the toggles, then one section per component.
class GalleryPage extends StatelessWidget {
  /// Creates the page.
  const GalleryPage({
    super.key,
    required this.isDark,
    required this.onDarkChanged,
    required this.brandNames,
    required this.brandName,
    required this.onBrandChanged,
  });

  /// Whether the dark theme is shown.
  final bool isDark;

  /// Switches between the light and dark themes.
  final ValueChanged<bool> onDarkChanged;

  /// The brands to choose from.
  final List<String> brandNames;

  /// The selected brand.
  final String brandName;

  /// Selects a brand.
  final ValueChanged<String> onBrandChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    return DsPageScaffold(
      title: 'Design system gallery',
      primaryAction: DsButton(label: 'Pinned primary action', onPressed: () {}),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(
              'Dark theme',
              style: TextStyle(color: colors.textPrimary),
            ),
            value: isDark,
            onChanged: onDarkChanged,
          ),
          Wrap(
            spacing: DsSpacing.xs,
            children: [
              for (final name in brandNames)
                ChoiceChip(
                  label: Text(name),
                  selected: name == brandName,
                  onSelected: (_) => onBrandChanged(name),
                ),
            ],
          ),
          const _Section(title: 'Buttons', children: _buttons),
          const _Section(title: 'Text fields', children: _fields),
          const _Section(
            title: 'Loading indicator',
            children: [DsLoadingIndicator(semanticsLabel: 'Loading')],
          ),
          _Section(
            title: 'Cards',
            children: [
              const DsCard(child: Text('A static card')),
              DsCard(
                onTap: () {},
                semanticsLabel: 'Open the tappable card',
                child: const Text('A tappable card'),
              ),
            ],
          ),
          _Section(
            title: 'List tiles',
            children: [
              const DsListTile(title: 'Title only'),
              DsListTile(
                title: 'Checking',
                subtitle: '•••• 4821',
                leading: const Icon(Icons.account_balance),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
          _Section(
            title: 'Inline messages',
            children: [
              for (final tone in DsMessageTone.values)
                DsInlineMessage(
                  tone: tone,
                  title: 'A ${tone.name} message',
                  message: 'Supporting text for the ${tone.name} tone.',
                  actionLabel: 'Action',
                  onAction: () {},
                ),
            ],
          ),
          _Section(
            title: 'Empty states',
            children: [
              const DsEmptyState(
                icon: Icons.receipt_long,
                title: 'No transfers yet',
                message: 'Without an action.',
              ),
              DsEmptyState(
                icon: Icons.receipt_long,
                title: 'No transfers yet',
                message: 'With an action.',
                actionLabel: 'New transfer',
                onAction: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _noop() {}

const _buttons = [
  DsButton(label: 'Primary', onPressed: _noop),
  DsButton(
    label: 'Secondary',
    onPressed: _noop,
    variant: DsButtonVariant.secondary,
  ),
  DsButton(
    label: 'Tertiary',
    onPressed: _noop,
    variant: DsButtonVariant.tertiary,
  ),
  DsButton(label: 'With icon', icon: Icons.send, onPressed: _noop),
  DsButton(label: 'Loading', onPressed: _noop, isLoading: true),
  DsButton(label: 'Disabled', onPressed: null),
  DsButton(label: 'Expanded', onPressed: _noop, expand: true),
];

const _fields = [
  DsTextField(label: 'Label only'),
  DsTextField(
    label: 'With hint and helper',
    hint: 'name@example.com',
    helperText: 'Helper text below the field.',
  ),
  DsTextField(label: 'With error', errorText: 'This value is not valid.'),
  DsTextField(label: 'Password', obscureText: true),
  DsTextField(label: 'Disabled', enabled: false),
];

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.dsColors;
    return Padding(
      padding: const EdgeInsets.only(top: DsSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: context.dsTypography.headline.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          for (final child in children)
            Padding(
              padding: const EdgeInsets.only(top: DsSpacing.sm),
              child: Align(alignment: Alignment.centerLeft, child: child),
            ),
        ],
      ),
    );
  }
}
