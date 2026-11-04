import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'ads.dart';

/// Banner placed right after a page's content. Same size on every page:
/// a full-width adaptive banner for the screen width minus the 16 dp page
/// margins. Collapses to nothing if no ad could be loaded.
class BannerSlot extends StatefulWidget {
  const BannerSlot({super.key, this.padding = const EdgeInsets.only(top: 16)});
  final EdgeInsets padding;

  @override
  State<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<BannerSlot> {
  BannerAd? _ad;
  AdSize? _size;
  bool _loaded = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ad == null && !_failed && Ads.supported) _load();
  }

  Future<void> _load() async {
    final width = (MediaQuery.sizeOf(context).width - 32).truncate();
    // The standard adaptive banner (≈ 50–60 dp tall) keeps every page's
    // banner the same compact size. The newer "large" variant can grow to
    // 15% of the screen height, which is too big for an in-content slot.
    // ignore: deprecated_member_use
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width) ?? AdSize.banner;
    if (!mounted) return;
    setState(() => _size = size);
    _ad = BannerAd(
      adUnitId: AdIds.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _ad = null;
          if (mounted) setState(() => _failed = true);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;
    if (!Ads.supported || _failed || size == null) return const SizedBox.shrink();
    return Padding(
      padding: widget.padding,
      child: Center(
        child: SizedBox(
          width: size.width.toDouble(),
          height: size.height.toDouble(),
          // Space is kept while loading so the page doesn't jump.
          child: _loaded && _ad != null ? AdWidget(ad: _ad!) : null,
        ),
      ),
    );
  }
}
