import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

class RvizView extends StatefulWidget {
  const RvizView({Key? key}) : super(key: key);

  @override
  State<RvizView> createState() => _RvizViewState();
}

class _RvizViewState extends State<RvizView> {
  @override
  Widget build(BuildContext context) {
    return Mjpeg(
      width: double.infinity,
      key: UniqueKey(),
      stream: 'http://192.168.0.104:8080/stream?topic=/stream1/image',
      fit: BoxFit.contain,
      loading: (ctx) => const Center(
        child: ProgressRing(),
      ),
      isLive: true,
      error: (ctx, e, v) {
        return TextButton(
          onPressed: () => setState(() {}),
          child: Container(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  FluentIcons.refresh,
                  size: 48,
                ),
                const SizedBox(height: 15),
                Center(
                  child: const Text("Actions.Buttons.retry").tr(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
