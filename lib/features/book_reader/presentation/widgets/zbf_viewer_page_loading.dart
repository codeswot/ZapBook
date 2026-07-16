part of 'zbf_viewer_page.dart';

class _ViewerLoading extends StatelessWidget {
  const _ViewerLoading();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.paper,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AppBackButton(),
          ),
        ),

        const ReaderPageLoading(message: 'Opening…'),
      ],
    ),
  );
}
